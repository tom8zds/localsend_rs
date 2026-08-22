///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$appTitle$en appTitle = Translations$appTitle$en._(_root);
	late final Translations$home$en home = Translations$home$en._(_root);
	late final Translations$send$en send = Translations$send$en._(_root);
	late final Translations$transfers$en transfers = Translations$transfers$en._(_root);
	late final Translations$mission$en mission = Translations$mission$en._(_root);
	late final Translations$common$en common = Translations$common$en._(_root);
	late final Translations$setting$en setting = Translations$setting$en._(_root);
}

// Path: appTitle
class Translations$appTitle$en {
	Translations$appTitle$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'LocalSend'
	String get parta => 'LocalSend';

	/// en: '_RS'
	String get partb => '_RS';
}

// Path: home
class Translations$home$en {
	Translations$home$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Home Page'
	String get title => 'Home Page';

	/// en: 'Send File'
	String get sendFile => 'Send File';

	/// en: 'Send Folder'
	String get sendFolder => 'Send Folder';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Add'
	String get add => 'Add';

	/// en: 'Clear'
	String get clear => 'Clear';

	/// en: 'Nearby Devices'
	String get nearbyDevices => 'Nearby Devices';

	/// en: 'Tap a device to send the selected files'
	String get tapToSend => 'Tap a device to send the selected files';

	/// en: 'Files: $count Size: $size'
	String filesSummary({required Object count, required Object size}) => 'Files: ${count}  Size: ${size}';
}

// Path: send
class Translations$send$en {
	Translations$send$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Send'
	String get title => 'Send';

	/// en: 'No files selected'
	String get noFiles => 'No files selected';

	/// en: 'Select targets'
	String get selectTargets => 'Select targets';

	/// en: 'Manual target'
	String get manualTarget => 'Manual target';

	/// en: 'IP or IP:port'
	String get manualTargetHint => 'IP or IP:port';

	/// en: 'Invalid address'
	String get invalidAddress => 'Invalid address';

	/// en: 'Add'
	String get addTarget => 'Add';

	/// en: 'Send to $count device(s)'
	String confirm({required Object count}) => 'Send to ${count} device(s)';

	/// en: 'Sending $count file(s) to $alias'
	String sentTo({required Object count, required Object alias}) => 'Sending ${count} file(s) to ${alias}';

	/// en: 'Started sending $count file(s) to $devices device(s)'
	String sentToDevices({required Object count, required Object devices}) => 'Started sending ${count} file(s) to ${devices} device(s)';

	/// en: 'Send to $alias failed: $reason'
	String sendFailed({required Object alias, required Object reason}) => 'Send to ${alias} failed: ${reason}';

	/// en: 'Remove'
	String get removeFile => 'Remove';
}

// Path: transfers
class Translations$transfers$en {
	Translations$transfers$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Transfers'
	String get title => 'Transfers';

	/// en: 'No transfers yet'
	String get empty => 'No transfers yet';

	/// en: 'Incoming'
	String get incoming => 'Incoming';

	/// en: 'Outgoing'
	String get outgoing => 'Outgoing';

	/// en: 'Accept'
	String get accept => 'Accept';

	/// en: 'Decline'
	String get decline => 'Decline';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: '$alias wants to send you $count file(s)'
	String peerWantsToSend({required Object alias, required Object count}) => '${alias} wants to send you ${count} file(s)';

	/// en: 'To $alias'
	String toPeer({required Object alias}) => 'To ${alias}';

	/// en: 'Failed: $reason'
	String failedReason({required Object reason}) => 'Failed: ${reason}';

	/// en: 'Via relay'
	String get viaRelay => 'Via relay';

	/// en: 'All'
	String get selectAll => 'All';

	/// en: 'None'
	String get selectNone => 'None';

	/// en: 'Local'
	String get routeLocal => 'Local';

	/// en: 'Relay'
	String get routeTurn => 'Relay';

	/// en: 'STUN'
	String get routeStun => 'STUN';
}

// Path: mission
class Translations$mission$en {
	Translations$mission$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Accept'
	String get accept => 'Accept';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Complete'
	String get complete => 'Complete';

	/// en: 'Finished'
	String get finished => 'Finished';

	/// en: 'Transfering'
	String get tranfer => 'Transfering';

	/// en: 'Pending'
	String get pending => 'Pending';

	/// en: 'Failed'
	String get failed => 'Failed';

	/// en: 'Skip'
	String get skip => 'Skip';

	/// en: 'Busy'
	String get busy => 'Busy';

	/// en: 'Advance'
	String get advance => 'Advance';
}

// Path: common
class Translations$common$en {
	Translations$common$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'File'
	String get file => 'File';

	/// en: 'Size'
	String get size => 'Size';
}

// Path: setting
class Translations$setting$en {
	Translations$setting$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Common'
	String get common => 'Common';

	late final Translations$setting$brightness$en brightness = Translations$setting$brightness$en._(_root);
	late final Translations$setting$language$en language = Translations$setting$language$en._(_root);
	late final Translations$setting$receive$en receive = Translations$setting$receive$en._(_root);
	late final Translations$setting$relay$en relay = Translations$setting$relay$en._(_root);
	late final Translations$setting$security$en security = Translations$setting$security$en._(_root);
	late final Translations$setting$core$en core = Translations$setting$core$en._(_root);
}

// Path: setting.brightness
class Translations$setting$brightness$en {
	Translations$setting$brightness$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Brightness'
	String get title => 'Brightness';

	/// en: 'Current mode: $mode'
	String subTitle({required Object mode}) => 'Current mode: ${mode}';

	late final Translations$setting$brightness$themeMode$en themeMode = Translations$setting$brightness$themeMode$en._(_root);
}

// Path: setting.language
class Translations$setting$language$en {
	Translations$setting$language$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Language'
	String get title => 'Language';

	/// en: 'Current language: $language'
	String subTitle({required Object language}) => 'Current language: ${language}';
}

// Path: setting.receive
class Translations$setting$receive$en {
	Translations$setting$receive$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Receive'
	String get title => 'Receive';

	/// en: 'Quick Save'
	String get quickSave => 'Quick Save';

	/// en: 'Start tranfer without accept'
	String get quickSaveHint => 'Start tranfer without accept';

	/// en: 'Save Folder'
	String get saveFolder => 'Save Folder';

	/// en: 'Select'
	String get selectSaveFolder => 'Select';
}

// Path: setting.relay
class Translations$setting$relay$en {
	Translations$setting$relay$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Relay Server'
	String get title => 'Relay Server';

	/// en: 'Server Address'
	String get address => 'Server Address';

	/// en: 'host:port'
	String get addressHint => 'host:port';

	/// en: 'Shared Secret'
	String get secret => 'Shared Secret';

	/// en: 'Not set'
	String get notSet => 'Not set';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Changes take effect after restarting the app'
	String get restartHint => 'Changes take effect after restarting the app';

	/// en: 'Import Configuration'
	String get importTitle => 'Import Configuration';

	/// en: 'Invite link or host:port|secret'
	String get importHint => 'Invite link or host:port|secret';

	/// en: 'Import'
	String get import => 'Import';

	/// en: 'Unrecognized relay configuration'
	String get importInvalid => 'Unrecognized relay configuration';

	/// en: 'Scan QR Code'
	String get scanQr => 'Scan QR Code';

	/// en: 'Scan QR Code'
	String get scanTitle => 'Scan QR Code';

	/// en: 'Camera unavailable'
	String get scanError => 'Camera unavailable';

	/// en: 'Apply Relay Configuration?'
	String get confirmTitle => 'Apply Relay Configuration?';

	/// en: 'Apply'
	String get apply => 'Apply';

	/// en: 'Relay saved; restart the app to apply'
	String get savedRestart => 'Relay saved; restart the app to apply';

	/// en: 'Connection Test'
	String get test => 'Connection Test';

	/// en: 'Probe the relay with a STUN request'
	String get testHint => 'Probe the relay with a STUN request';

	/// en: 'Test'
	String get testAction => 'Test';

	/// en: '$ms ms'
	String testResult({required Object ms}) => '${ms} ms';

	/// en: 'Failed: $reason'
	String testFailed({required Object reason}) => 'Failed: ${reason}';
}

// Path: setting.security
class Translations$setting$security$en {
	Translations$setting$security$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Security'
	String get title => 'Security';

	/// en: 'End-to-end Encryption (TLS)'
	String get tls => 'End-to-end Encryption (TLS)';

	/// en: 'Unencrypted transfer; recommended for debugging only'
	String get plainWarning => 'Unencrypted transfer; recommended for debugging only';

	/// en: 'Changes take effect after restarting the app'
	String get restartHint => 'Changes take effect after restarting the app';
}

// Path: setting.core
class Translations$setting$core$en {
	Translations$setting$core$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'core setting'
	String get title => 'core setting';

	late final Translations$setting$core$server$en server = Translations$setting$core$server$en._(_root);
}

// Path: setting.brightness.themeMode
class Translations$setting$brightness$themeMode$en {
	Translations$setting$brightness$themeMode$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Follow system'
	String get system => 'Follow system';

	/// en: 'Light mode'
	String get light => 'Light mode';

	/// en: 'Dark mode'
	String get dark => 'Dark mode';
}

// Path: setting.core.server
class Translations$setting$core$server$en {
	Translations$setting$core$server$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'server'
	String get title => 'server';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle.parta' => 'LocalSend',
			'appTitle.partb' => '_RS',
			'home.title' => 'Home Page',
			'home.sendFile' => 'Send File',
			'home.sendFolder' => 'Send Folder',
			'home.next' => 'Next',
			'home.add' => 'Add',
			'home.clear' => 'Clear',
			'home.nearbyDevices' => 'Nearby Devices',
			'home.tapToSend' => 'Tap a device to send the selected files',
			'home.filesSummary' => ({required Object count, required Object size}) => 'Files: ${count}  Size: ${size}',
			'send.title' => 'Send',
			'send.noFiles' => 'No files selected',
			'send.selectTargets' => 'Select targets',
			'send.manualTarget' => 'Manual target',
			'send.manualTargetHint' => 'IP or IP:port',
			'send.invalidAddress' => 'Invalid address',
			'send.addTarget' => 'Add',
			'send.confirm' => ({required Object count}) => 'Send to ${count} device(s)',
			'send.sentTo' => ({required Object count, required Object alias}) => 'Sending ${count} file(s) to ${alias}',
			'send.sentToDevices' => ({required Object count, required Object devices}) => 'Started sending ${count} file(s) to ${devices} device(s)',
			'send.sendFailed' => ({required Object alias, required Object reason}) => 'Send to ${alias} failed: ${reason}',
			'send.removeFile' => 'Remove',
			'transfers.title' => 'Transfers',
			'transfers.empty' => 'No transfers yet',
			'transfers.incoming' => 'Incoming',
			'transfers.outgoing' => 'Outgoing',
			'transfers.accept' => 'Accept',
			'transfers.decline' => 'Decline',
			'transfers.cancel' => 'Cancel',
			'transfers.peerWantsToSend' => ({required Object alias, required Object count}) => '${alias} wants to send you ${count} file(s)',
			'transfers.toPeer' => ({required Object alias}) => 'To ${alias}',
			'transfers.failedReason' => ({required Object reason}) => 'Failed: ${reason}',
			'transfers.viaRelay' => 'Via relay',
			'transfers.selectAll' => 'All',
			'transfers.selectNone' => 'None',
			'transfers.routeLocal' => 'Local',
			'transfers.routeTurn' => 'Relay',
			'transfers.routeStun' => 'STUN',
			'mission.accept' => 'Accept',
			'mission.cancel' => 'Cancel',
			'mission.complete' => 'Complete',
			'mission.finished' => 'Finished',
			'mission.tranfer' => 'Transfering',
			'mission.pending' => 'Pending',
			'mission.failed' => 'Failed',
			'mission.skip' => 'Skip',
			'mission.busy' => 'Busy',
			'mission.advance' => 'Advance',
			'common.file' => 'File',
			'common.size' => 'Size',
			'setting.title' => 'Settings',
			'setting.common' => 'Common',
			'setting.brightness.title' => 'Brightness',
			'setting.brightness.subTitle' => ({required Object mode}) => 'Current mode: ${mode}',
			'setting.brightness.themeMode.system' => 'Follow system',
			'setting.brightness.themeMode.light' => 'Light mode',
			'setting.brightness.themeMode.dark' => 'Dark mode',
			'setting.language.title' => 'Language',
			'setting.language.subTitle' => ({required Object language}) => 'Current language: ${language}',
			'setting.receive.title' => 'Receive',
			'setting.receive.quickSave' => 'Quick Save',
			'setting.receive.quickSaveHint' => 'Start tranfer without accept',
			'setting.receive.saveFolder' => 'Save Folder',
			'setting.receive.selectSaveFolder' => 'Select',
			'setting.relay.title' => 'Relay Server',
			'setting.relay.address' => 'Server Address',
			'setting.relay.addressHint' => 'host:port',
			'setting.relay.secret' => 'Shared Secret',
			'setting.relay.notSet' => 'Not set',
			'setting.relay.edit' => 'Edit',
			'setting.relay.save' => 'Save',
			'setting.relay.cancel' => 'Cancel',
			'setting.relay.restartHint' => 'Changes take effect after restarting the app',
			'setting.relay.importTitle' => 'Import Configuration',
			'setting.relay.importHint' => 'Invite link or host:port|secret',
			'setting.relay.import' => 'Import',
			'setting.relay.importInvalid' => 'Unrecognized relay configuration',
			'setting.relay.scanQr' => 'Scan QR Code',
			'setting.relay.scanTitle' => 'Scan QR Code',
			'setting.relay.scanError' => 'Camera unavailable',
			'setting.relay.confirmTitle' => 'Apply Relay Configuration?',
			'setting.relay.apply' => 'Apply',
			'setting.relay.savedRestart' => 'Relay saved; restart the app to apply',
			'setting.relay.test' => 'Connection Test',
			'setting.relay.testHint' => 'Probe the relay with a STUN request',
			'setting.relay.testAction' => 'Test',
			'setting.relay.testResult' => ({required Object ms}) => '${ms} ms',
			'setting.relay.testFailed' => ({required Object reason}) => 'Failed: ${reason}',
			'setting.security.title' => 'Security',
			'setting.security.tls' => 'End-to-end Encryption (TLS)',
			'setting.security.plainWarning' => 'Unencrypted transfer; recommended for debugging only',
			'setting.security.restartHint' => 'Changes take effect after restarting the app',
			'setting.core.title' => 'core setting',
			'setting.core.server.title' => 'server',
			_ => null,
		};
	}
}
