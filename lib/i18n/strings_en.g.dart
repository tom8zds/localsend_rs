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
			'mission.accept' => 'Accept',
			'mission.cancel' => 'Cancel',
			'mission.complete' => 'Complete',
			'mission.finished' => 'Finished',
			'mission.tranfer' => 'Transfering',
			'mission.pending' => 'Pending',
			'mission.failed' => 'Failed',
			'mission.skip' => 'Skip',
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
			'setting.core.title' => 'core setting',
			'setting.core.server.title' => 'server',
			_ => null,
		};
	}
}
