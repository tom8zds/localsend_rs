import 'dart:io';

import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

void main() {
  InnoSetup(
    app: InnoSetupApp(
      name: 'localsend_rs',
      version: Version.parse('0.1.0'),
      publisher: 'tomzds9@gihub',
      urls: InnoSetupAppUrls(
        homeUrl: Uri.parse('https://github.com/tom8zds/localsend_rs'),
      ),
    ),
    files: InnoSetupFiles(
      executable: File('build/windows/x64/runner/Release/localsend_rs.exe'),
      location: Directory('build/windows/x64/runner/Release/'),
    ),
    name: const InnoSetupName('localsend_rs-setup'),
    location: InnoSetupInstallerDirectory(
      Directory('build/windows'),
    ),
    icon: InnoSetupIcon(
      File('assets/icon/logo.ico'),
    ),
  ).make();
}
