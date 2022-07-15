import 'dart:io';

import 'package:googleapis/gmail/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:receipt_gmail/client_config.dart';
import 'package:receipt_gmail/platform_utils.dart';

final _clientId = clientId;
final _scopes = [GmailApi.gmailReadonlyScope];
final _userId = 'me';

late GmailApi _gmailApi;
Future<http.Client> obtainClient() async {
  return await clientViaUserConsent(_clientId, _scopes, openBrowser);
}

Future<List<Message>> getAllSBBMessages() async {
  final lightMessages = (await _gmailApi.users.messages
              .list(_userId, q: "from:sbb.feedback@fairtiq.com"))
          .messages ??
      [];

  final messageRequests = <Future<Message>>[];
  for (var message in lightMessages) {
    if (message.id == null) continue;
    final messageId = message.id!;
    messageRequests.add(_gmailApi.users.messages.get(_userId, messageId));
  }
  return Future.wait(messageRequests);
}

AttachmentInfo? _extractAttachmentInfos(Message message) {
  final parts = message.payload?.parts;
  if (parts == null || parts.length <= 1) return null;
  final partOne = message.payload?.parts?[1];
  if (partOne == null) return null;
  final attachmentId = partOne.body?.attachmentId;
  final fileName = partOne.filename;
  final messageId = message.id;
  if (messageId == null || attachmentId == null || fileName == null) {
    return null;
  }
  return AttachmentInfo(
    attachmentId: attachmentId,
    fileName: fileName,
    messageId: messageId,
  );
}

Future<File> saveToFile(List<int> bytes, String filePath) async {
  final newFile = File(filePath);
  if (!newFile.existsSync()) {
    newFile.createSync(recursive: true);
  }
  return newFile.writeAsBytes(bytes);
}

Future<void> downloadAllAttachments(
  GmailApi gmailApi,
  List<Message> messages,
) async {
  for (final message in messages) {
    final attachmentInfo = _extractAttachmentInfos(message);
    if (attachmentInfo == null) continue;
    final bytes = (await gmailApi.users.messages.attachments.get(
            _userId, attachmentInfo.messageId, attachmentInfo.attachmentId))
        .dataAsBytes;
    final file = await saveToFile(bytes,
        '${SpecialDirectory.desktopWithPathSeparator}SBBInvoices${Platform.pathSeparator}${attachmentInfo.fileName}');
    print('Saved ${file.absolute.path}');
  }
  return Future.value();
}

Future<void> run() async {
  final httpClient = await obtainClient();
  _gmailApi = GmailApi(httpClient);
  final messages = await getAllSBBMessages();
  await downloadAllAttachments(_gmailApi, messages);
  print('DONE');
  return Future.value();
}

class AttachmentInfo {
  final String attachmentId;
  final String fileName;
  final String messageId;

  AttachmentInfo({
    required this.attachmentId,
    required this.fileName,
    required this.messageId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentInfo &&
          runtimeType == other.runtimeType &&
          attachmentId == other.attachmentId &&
          fileName == other.fileName &&
          messageId == other.messageId;

  @override
  int get hashCode =>
      attachmentId.hashCode ^ fileName.hashCode ^ messageId.hashCode;
}
