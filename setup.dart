import 'dart:io';

import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

/// [InnoSetup] variant whose generated script also registers the
/// `localsend-relay` URL protocol (relay invite deep links) under
/// HKCR. The stock package has no [Registry] support, so this
/// overrides `make` to re-emit its script with the section appended.
class DeepLinkInnoSetup extends InnoSetup {
  const DeepLinkInnoSetup({
    required super.app,
    required super.icon,
    super.compression,
    super.languages,
    required super.name,
    required super.location,
    super.license,
    required super.files,
    super.runAfterInstall,
  });

  @override
  Future<void> make() async {
    final executable = '${app.name}.exe';
    final iss = StringBuffer('''
[Setup]
$app
$compression
$icon
$name
$location
${license ?? ''}

${InnoSetupLanguagesBuilder(languages)}

$files

[Registry]
Root: HKCR; Subkey: "localsend-relay"; ValueType: string; ValueName: ""; ValueData: "URL:localsend-relay Protocol"; Flags: createvalueifdoesntexist uninsdeletekey
Root: HKCR; Subkey: "localsend-relay"; ValueType: string; ValueName: "URL Protocol"; ValueData: ""; Flags: createvalueifdoesntexist uninsdeletekey
Root: HKCR; Subkey: "localsend-relay\\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\\$executable"; Flags: createvalueifdoesntexist uninsdeletekey
Root: HKCR; Subkey: "localsend-relay\\shell\\open\\command"; ValueType: string; ValueName: ""; ValueData: """{app}\\$executable"" ""%1"""; Flags: createvalueifdoesntexist uninsdeletekey

${InnoSetupIconsBuilder(app)}

${runAfterInstall ? InnoSetupRunBuilder(app) : ''}
''');

    final buildDirectory = Directory('build');

    if (!await buildDirectory.exists()) {
      await buildDirectory.create();
    }

    File('build/innosetup.iss').writeAsStringSync('$iss');

    final result = await Process.run(
      'iscc',
      ['build/innosetup.iss'],
      runInShell: true,
    );
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      throw StateError('iscc failed with exit code \${result.exitCode}');
    }
  }
}

void main() {
  DeepLinkInnoSetup(
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
