///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsZh with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsZh({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
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

	late final TranslationsZh _root = this; // ignore: unused_field

	@override 
	TranslationsZh $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsZh(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$appTitle$zh appTitle = _Translations$appTitle$zh._(_root);
	@override late final _Translations$home$zh home = _Translations$home$zh._(_root);
	@override late final _Translations$mission$zh mission = _Translations$mission$zh._(_root);
	@override late final _Translations$common$zh common = _Translations$common$zh._(_root);
	@override late final _Translations$setting$zh setting = _Translations$setting$zh._(_root);
}

// Path: appTitle
class _Translations$appTitle$zh implements Translations$appTitle$en {
	_Translations$appTitle$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get parta => '快传';
	@override String get partb => '锈';
}

// Path: home
class _Translations$home$zh implements Translations$home$en {
	_Translations$home$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '主页';
}

// Path: mission
class _Translations$mission$zh implements Translations$mission$en {
	_Translations$mission$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

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
class _Translations$common$zh implements Translations$common$en {
	_Translations$common$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get file => '文件';
	@override String get size => '大小';
}

// Path: setting
class _Translations$setting$zh implements Translations$setting$en {
	_Translations$setting$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '设置';
	@override String get common => '通用';
	@override late final _Translations$setting$brightness$zh brightness = _Translations$setting$brightness$zh._(_root);
	@override late final _Translations$setting$language$zh language = _Translations$setting$language$zh._(_root);
	@override late final _Translations$setting$receive$zh receive = _Translations$setting$receive$zh._(_root);
	@override late final _Translations$setting$core$zh core = _Translations$setting$core$zh._(_root);
}

// Path: setting.brightness
class _Translations$setting$brightness$zh implements Translations$setting$brightness$en {
	_Translations$setting$brightness$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '明暗';
	@override String subTitle({required Object mode}) => '当前模式: ${mode}';
	@override late final _Translations$setting$brightness$themeMode$zh themeMode = _Translations$setting$brightness$themeMode$zh._(_root);
}

// Path: setting.language
class _Translations$setting$language$zh implements Translations$setting$language$en {
	_Translations$setting$language$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '语言';
	@override String subTitle({required Object language}) => '当前语言: ${language}';
}

// Path: setting.receive
class _Translations$setting$receive$zh implements Translations$setting$receive$en {
	_Translations$setting$receive$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '接收设置';
	@override String get quickSave => '快速保存';
	@override String get quickSaveHint => '不需要等待确认直接接受';
	@override String get saveFolder => '保存目录';
	@override String get selectSaveFolder => '选择';
}

// Path: setting.core
class _Translations$setting$core$zh implements Translations$setting$core$en {
	_Translations$setting$core$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '核心设置';
	@override late final _Translations$setting$core$server$zh server = _Translations$setting$core$server$zh._(_root);
}

// Path: setting.brightness.themeMode
class _Translations$setting$brightness$themeMode$zh implements Translations$setting$brightness$themeMode$en {
	_Translations$setting$brightness$themeMode$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get system => '跟随系统';
	@override String get light => '浅色模式';
	@override String get dark => '深色模式';
}

// Path: setting.core.server
class _Translations$setting$core$server$zh implements Translations$setting$core$server$en {
	_Translations$setting$core$server$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '服务器';
}

/// The flat map containing all translations for locale <zh>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsZh {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appTitle.parta' => '快传',
			'appTitle.partb' => '锈',
			'home.title' => '主页',
			'mission.accept' => '接收',
			'mission.cancel' => '取消',
			'mission.complete' => '完成',
			'mission.finished' => '已完成',
			'mission.tranfer' => '传输中',
			'mission.pending' => '等待中',
			'mission.failed' => '失败',
			'mission.skip' => '跳过',
			'mission.advance' => '高级',
			'common.file' => '文件',
			'common.size' => '大小',
			'setting.title' => '设置',
			'setting.common' => '通用',
			'setting.brightness.title' => '明暗',
			'setting.brightness.subTitle' => ({required Object mode}) => '当前模式: ${mode}',
			'setting.brightness.themeMode.system' => '跟随系统',
			'setting.brightness.themeMode.light' => '浅色模式',
			'setting.brightness.themeMode.dark' => '深色模式',
			'setting.language.title' => '语言',
			'setting.language.subTitle' => ({required Object language}) => '当前语言: ${language}',
			'setting.receive.title' => '接收设置',
			'setting.receive.quickSave' => '快速保存',
			'setting.receive.quickSaveHint' => '不需要等待确认直接接受',
			'setting.receive.saveFolder' => '保存目录',
			'setting.receive.selectSaveFolder' => '选择',
			'setting.core.title' => '核心设置',
			'setting.core.server.title' => '服务器',
			_ => null,
		};
	}
}
