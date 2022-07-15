import 'dart:io';

void openBrowser(String url) {
  _assertPlatformIsSupported();
  final arguments = [url];
  late String executable;

  if (Platform.isMacOS) {
    executable = 'open';
  } else if (Platform.isLinux) {
    executable = 'xdg-open';
  } else if (Platform.isWindows) {
    executable = 'start';
  }
  Process.runSync(executable, arguments);
}

void _assertPlatformIsSupported() {
  switch (Platform.operatingSystem) {
    case 'linux':
    case 'macos':
    case 'windows':
      return;
    default:
      throw UnsupportedError('${Platform.operatingSystem} is unsupported');
  }
}

class SpecialDirectory {
  static String _home() {
    _assertPlatformIsSupported();
    String? home;
    Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS || Platform.isLinux) {
      home = envVars['HOME'];
    } else if (Platform.isWindows) {
      home = envVars['UserProfile'];
    }
    return home!;
  }

  static final String homeWithPathSeparator =
      ('$home${Platform.pathSeparator}');
  static String home = _home();
  static String desktop = ('${homeWithPathSeparator}Desktop');
  static String desktopWithPathSeparator =
      ('$desktop${Platform.pathSeparator}');
  static String downloads = ('${homeWithPathSeparator}Downloads');
  static String downloadsWithPathSeparator =
      ('$downloads${Platform.pathSeparator}');
}
