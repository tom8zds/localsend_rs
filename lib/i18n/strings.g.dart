/// Generated file. Do not edit.
///
/// Original: assets/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 2
/// Strings: 60 (30 per locale)
///
/// Built on 2024-07-07 at 14:19 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.en;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.en) // set locale
/// - Locale locale = AppLocale.en.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.en) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	en(languageCode: 'en', build: Translations.build),
	zh(languageCode: 'zh', build: _StringsZh.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
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

	// Translations
	late final _StringsAppTitleEn appTitle = _StringsAppTitleEn._(_root);
	late final _StringsHomeEn home = _StringsHomeEn._(_root);
	late final _StringsMissionEn mission = _StringsMissionEn._(_root);
	late final _StringsCommonEn common = _StringsCommonEn._(_root);
	late final _StringsSettingEn setting = _StringsSettingEn._(_root);
}

// Path: appTitle
class _StringsAppTitleEn {
	_StringsAppTitleEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get parta => 'LocalSend';
	String get partb => '_RS';
}

// Path: home
class _StringsHomeEn {
	_StringsHomeEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Home Page';
}

// Path: mission
class _StringsMissionEn {
	_StringsMissionEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get accept => 'Accept';
	String get cancel => 'Cancel';
	String get complete => 'Complete';
	String get finished => 'Finished';
	String get tranfer => 'Transfering';
	String get pending => 'Pending';
	String get failed => 'Failed';
	String get skip => 'Skip';
	String get advance => 'Advance';
}

// Path: common
class _StringsCommonEn {
	_StringsCommonEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get file => 'File';
	String get size => 'Size';
}

// Path: setting
class _StringsSettingEn {
	_StringsSettingEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Settings';
	String get common => 'Common';
	late final _StringsSettingBrightnessEn brightness = _StringsSettingBrightnessEn._(_root);
	late final _StringsSettingLanguageEn language = _StringsSettingLanguageEn._(_root);
	late final _StringsSettingReceiveEn receive = _StringsSettingReceiveEn._(_root);
	late final _StringsSettingCoreEn core = _StringsSettingCoreEn._(_root);
}

// Path: setting.brightness
class _StringsSettingBrightnessEn {
	_StringsSettingBrightnessEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Brightness';
	String subTitle({required Object mode}) => 'Current mode: ${mode}';
	late final _StringsSettingBrightnessThemeModeEn themeMode = _StringsSettingBrightnessThemeModeEn._(_root);
}

// Path: setting.language
class _StringsSettingLanguageEn {
	_StringsSettingLanguageEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Language';
	String subTitle({required Object language}) => 'Current language: ${language}';
}

// Path: setting.receive
class _StringsSettingReceiveEn {
	_StringsSettingReceiveEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Receive';
	String get quickSave => 'Quick Save';
	String get quickSaveHint => 'Start tranfer without accept';
	String get saveFolder => 'Save Folder';
	String get selectSaveFolder => 'Select';
}

// Path: setting.core
class _StringsSettingCoreEn {
	_StringsSettingCoreEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'core setting';
	late final _StringsSettingCoreServerEn server = _StringsSettingCoreServerEn._(_root);
}

// Path: setting.brightness.themeMode
class _StringsSettingBrightnessThemeModeEn {
	_StringsSettingBrightnessThemeModeEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get system => 'Follow system';
	String get light => 'Light mode';
	String get dark => 'Dark mode';
}

// Path: setting.core.server
class _StringsSettingCoreServerEn {
	_StringsSettingCoreServerEn._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'server';
}

// Path: <root>
class _StringsZh implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_StringsZh.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.zh,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <zh>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	@override late final _StringsZh _root = this; // ignore: unused_field

	// Translations
	@override late final _StringsAppTitleZh appTitle = _StringsAppTitleZh._(_root);
	@override late final _StringsHomeZh home = _StringsHomeZh._(_root);
	@override late final _StringsMissionZh mission = _StringsMissionZh._(_root);
	@override late final _StringsCommonZh common = _StringsCommonZh._(_root);
	@override late final _StringsSettingZh setting = _StringsSettingZh._(_root);
}

// Path: appTitle
class _StringsAppTitleZh implements _StringsAppTitleEn {
	_StringsAppTitleZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get parta => '快传';
	@override String get partb => '锈';
}

// Path: home
class _StringsHomeZh implements _StringsHomeEn {
	_StringsHomeZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '主页';
}

// Path: mission
class _StringsMissionZh implements _StringsMissionEn {
	_StringsMissionZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get accept => '接收';
	@override String get cancel => '取消';
	@override String get complete => '完成';
	@override String get finished => '已完成';
	@override String get tranfer => '传输中';
	@override String get pending => '等待中';
	@override String get failed => '失败';
	@override String get skip => '跳过';
	@override String get advance => '高级';
}

// Path: common
class _StringsCommonZh implements _StringsCommonEn {
	_StringsCommonZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get file => '文件';
	@override String get size => '大小';
}

// Path: setting
class _StringsSettingZh implements _StringsSettingEn {
	_StringsSettingZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get common => '通用';
	@override late final _StringsSettingBrightnessZh brightness = _StringsSettingBrightnessZh._(_root);
	@override late final _StringsSettingLanguageZh language = _StringsSettingLanguageZh._(_root);
	@override late final _StringsSettingReceiveZh receive = _StringsSettingReceiveZh._(_root);
	@override late final _StringsSettingCoreZh core = _StringsSettingCoreZh._(_root);
}

// Path: setting.brightness
class _StringsSettingBrightnessZh implements _StringsSettingBrightnessEn {
	_StringsSettingBrightnessZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '明暗';
	@override String subTitle({required Object mode}) => '当前模式: ${mode}';
	@override late final _StringsSettingBrightnessThemeModeZh themeMode = _StringsSettingBrightnessThemeModeZh._(_root);
}

// Path: setting.language
class _StringsSettingLanguageZh implements _StringsSettingLanguageEn {
	_StringsSettingLanguageZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '语言';
	@override String subTitle({required Object language}) => '当前语言: ${language}';
}

// Path: setting.receive
class _StringsSettingReceiveZh implements _StringsSettingReceiveEn {
	_StringsSettingReceiveZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '接收设置';
	@override String get quickSave => '快速保存';
	@override String get quickSaveHint => '不需要等待确认直接接受';
	@override String get saveFolder => '保存目录';
	@override String get selectSaveFolder => '选择';
}

// Path: setting.core
class _StringsSettingCoreZh implements _StringsSettingCoreEn {
	_StringsSettingCoreZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '核心设置';
	@override late final _StringsSettingCoreServerZh server = _StringsSettingCoreServerZh._(_root);
}

// Path: setting.brightness.themeMode
class _StringsSettingBrightnessThemeModeZh implements _StringsSettingBrightnessThemeModeEn {
	_StringsSettingBrightnessThemeModeZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get system => '跟随系统';
	@override String get light => '浅色模式';
	@override String get dark => '深色模式';
}

// Path: setting.core.server
class _StringsSettingCoreServerZh implements _StringsSettingCoreServerEn {
	_StringsSettingCoreServerZh._(this._root);

	@override final _StringsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '服务器';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'appTitle.parta': return 'LocalSend';
			case 'appTitle.partb': return '_RS';
			case 'home.title': return 'Home Page';
			case 'mission.accept': return 'Accept';
			case 'mission.cancel': return 'Cancel';
			case 'mission.complete': return 'Complete';
			case 'mission.finished': return 'Finished';
			case 'mission.tranfer': return 'Transfering';
			case 'mission.pending': return 'Pending';
			case 'mission.failed': return 'Failed';
			case 'mission.skip': return 'Skip';
			case 'mission.advance': return 'Advance';
			case 'common.file': return 'File';
			case 'common.size': return 'Size';
			case 'setting.title': return 'Settings';
			case 'setting.common': return 'Common';
			case 'setting.brightness.title': return 'Brightness';
			case 'setting.brightness.subTitle': return ({required Object mode}) => 'Current mode: ${mode}';
			case 'setting.brightness.themeMode.system': return 'Follow system';
			case 'setting.brightness.themeMode.light': return 'Light mode';
			case 'setting.brightness.themeMode.dark': return 'Dark mode';
			case 'setting.language.title': return 'Language';
			case 'setting.language.subTitle': return ({required Object language}) => 'Current language: ${language}';
			case 'setting.receive.title': return 'Receive';
			case 'setting.receive.quickSave': return 'Quick Save';
			case 'setting.receive.quickSaveHint': return 'Start tranfer without accept';
			case 'setting.receive.saveFolder': return 'Save Folder';
			case 'setting.receive.selectSaveFolder': return 'Select';
			case 'setting.core.title': return 'core setting';
			case 'setting.core.server.title': return 'server';
			default: return null;
		}
	}
}

extension on _StringsZh {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'appTitle.parta': return '快传';
			case 'appTitle.partb': return '锈';
			case 'home.title': return '主页';
			case 'mission.accept': return '接收';
			case 'mission.cancel': return '取消';
			case 'mission.complete': return '完成';
			case 'mission.finished': return '已完成';
			case 'mission.tranfer': return '传输中';
			case 'mission.pending': return '等待中';
			case 'mission.failed': return '失败';
			case 'mission.skip': return '跳过';
			case 'mission.advance': return '高级';
			case 'common.file': return '文件';
			case 'common.size': return '大小';
			case 'setting.title': return '设置';
			case 'setting.common': return '通用';
			case 'setting.brightness.title': return '明暗';
			case 'setting.brightness.subTitle': return ({required Object mode}) => '当前模式: ${mode}';
			case 'setting.brightness.themeMode.system': return '跟随系统';
			case 'setting.brightness.themeMode.light': return '浅色模式';
			case 'setting.brightness.themeMode.dark': return '深色模式';
			case 'setting.language.title': return '语言';
			case 'setting.language.subTitle': return ({required Object language}) => '当前语言: ${language}';
			case 'setting.receive.title': return '接收设置';
			case 'setting.receive.quickSave': return '快速保存';
			case 'setting.receive.quickSaveHint': return '不需要等待确认直接接受';
			case 'setting.receive.saveFolder': return '保存目录';
			case 'setting.receive.selectSaveFolder': return '选择';
			case 'setting.core.title': return '核心设置';
			case 'setting.core.server.title': return '服务器';
			default: return null;
		}
	}
}
