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
	@override late final _Translations$send$zh send = _Translations$send$zh._(_root);
	@override late final _Translations$transfers$zh transfers = _Translations$transfers$zh._(_root);
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
	@override String get sendFile => '发送文件';
	@override String get sendFolder => '发送文件夹';
	@override String get next => '下一步';
	@override String get add => '添加';
	@override String get clear => '清空';
	@override String get nearbyDevices => '附近的设备';
	@override String get tapToSend => '点击设备直接发送所选文件';
	@override String filesSummary({required Object count, required Object size}) => '文件: ${count}  大小: ${size}';
}

// Path: send
class _Translations$send$zh implements Translations$send$en {
	_Translations$send$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '发送';
	@override String get noFiles => '未选择文件';
	@override String get selectTargets => '选择目标设备';
	@override String get manualTarget => '手动添加目标';
	@override String get manualTargetHint => 'IP 或 IP:端口';
	@override String get invalidAddress => '地址无效';
	@override String get addTarget => '添加';
	@override String confirm({required Object count}) => '发送到 ${count} 台设备';
	@override String sentTo({required Object alias, required Object count}) => '正在向 ${alias} 发送 ${count} 个文件';
	@override String sentToDevices({required Object devices, required Object count}) => '已开始向 ${devices} 台设备发送 ${count} 个文件';
	@override String sendFailed({required Object alias, required Object reason}) => '发送到 ${alias} 失败: ${reason}';
	@override String get removeFile => '移除';
}

// Path: transfers
class _Translations$transfers$zh implements Translations$transfers$en {
	_Translations$transfers$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '传输';
	@override String get empty => '暂无传输任务';
	@override String get incoming => '接收';
	@override String get outgoing => '发送';
	@override String get accept => '接收';
	@override String get decline => '拒绝';
	@override String get cancel => '取消';
	@override String peerWantsToSend({required Object alias, required Object count}) => '${alias} 想要发送给你 ${count} 个文件';
	@override String toPeer({required Object alias}) => '发送到 ${alias}';
	@override String failedReason({required Object reason}) => '失败: ${reason}';
	@override String get viaRelay => '经中继';
	@override String get selectAll => '全选';
	@override String get selectNone => '全不选';
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
	@override String get busy => '忙碌';
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
	@override late final _Translations$setting$relay$zh relay = _Translations$setting$relay$zh._(_root);
	@override late final _Translations$setting$security$zh security = _Translations$setting$security$zh._(_root);
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

// Path: setting.relay
class _Translations$setting$relay$zh implements Translations$setting$relay$en {
	_Translations$setting$relay$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '中继服务器';
	@override String get address => '服务器地址';
	@override String get addressHint => '主机:端口';
	@override String get secret => '共享密钥';
	@override String get notSet => '未设置';
	@override String get edit => '编辑';
	@override String get save => '保存';
	@override String get cancel => '取消';
	@override String get restartHint => '修改后重启应用生效';
	@override String get importTitle => '导入配置';
	@override String get importHint => '邀请链接或 主机:端口|密钥';
	@override String get import => '导入';
	@override String get importInvalid => '无法识别的中继配置';
	@override String get scanQr => '扫描二维码';
	@override String get scanTitle => '扫描二维码';
	@override String get scanError => '相机不可用';
	@override String get confirmTitle => '应用中继配置？';
	@override String get apply => '应用';
	@override String get savedRestart => '中继已保存，重启应用后生效';
	@override String get test => '连接测试';
	@override String get testHint => '向中继发送 STUN 探测';
	@override String get testAction => '测试';
	@override String testResult({required Object ms}) => '${ms} ms';
	@override String testFailed({required Object reason}) => '失败: ${reason}';
}

// Path: setting.security
class _Translations$setting$security$zh implements Translations$setting$security$en {
	_Translations$setting$security$zh._(this._root);

	final TranslationsZh _root; // ignore: unused_field

	// Translations
	@override String get title => '安全';
	@override String get tls => '端到端加密 (TLS)';
	@override String get plainWarning => '明文传输，仅建议调试使用';
	@override String get restartHint => '修改后重启应用生效';
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
			'home.sendFile' => '发送文件',
			'home.sendFolder' => '发送文件夹',
			'home.next' => '下一步',
			'home.add' => '添加',
			'home.clear' => '清空',
			'home.nearbyDevices' => '附近的设备',
			'home.tapToSend' => '点击设备直接发送所选文件',
			'home.filesSummary' => ({required Object count, required Object size}) => '文件: ${count}  大小: ${size}',
			'send.title' => '发送',
			'send.noFiles' => '未选择文件',
			'send.selectTargets' => '选择目标设备',
			'send.manualTarget' => '手动添加目标',
			'send.manualTargetHint' => 'IP 或 IP:端口',
			'send.invalidAddress' => '地址无效',
			'send.addTarget' => '添加',
			'send.confirm' => ({required Object count}) => '发送到 ${count} 台设备',
			'send.sentTo' => ({required Object alias, required Object count}) => '正在向 ${alias} 发送 ${count} 个文件',
			'send.sentToDevices' => ({required Object devices, required Object count}) => '已开始向 ${devices} 台设备发送 ${count} 个文件',
			'send.sendFailed' => ({required Object alias, required Object reason}) => '发送到 ${alias} 失败: ${reason}',
			'send.removeFile' => '移除',
			'transfers.title' => '传输',
			'transfers.empty' => '暂无传输任务',
			'transfers.incoming' => '接收',
			'transfers.outgoing' => '发送',
			'transfers.accept' => '接收',
			'transfers.decline' => '拒绝',
			'transfers.cancel' => '取消',
			'transfers.peerWantsToSend' => ({required Object alias, required Object count}) => '${alias} 想要发送给你 ${count} 个文件',
			'transfers.toPeer' => ({required Object alias}) => '发送到 ${alias}',
			'transfers.failedReason' => ({required Object reason}) => '失败: ${reason}',
			'transfers.viaRelay' => '经中继',
			'transfers.selectAll' => '全选',
			'transfers.selectNone' => '全不选',
			'mission.accept' => '接收',
			'mission.cancel' => '取消',
			'mission.complete' => '完成',
			'mission.finished' => '已完成',
			'mission.tranfer' => '传输中',
			'mission.pending' => '等待中',
			'mission.failed' => '失败',
			'mission.skip' => '跳过',
			'mission.busy' => '忙碌',
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
			'setting.relay.title' => '中继服务器',
			'setting.relay.address' => '服务器地址',
			'setting.relay.addressHint' => '主机:端口',
			'setting.relay.secret' => '共享密钥',
			'setting.relay.notSet' => '未设置',
			'setting.relay.edit' => '编辑',
			'setting.relay.save' => '保存',
			'setting.relay.cancel' => '取消',
			'setting.relay.restartHint' => '修改后重启应用生效',
			'setting.relay.importTitle' => '导入配置',
			'setting.relay.importHint' => '邀请链接或 主机:端口|密钥',
			'setting.relay.import' => '导入',
			'setting.relay.importInvalid' => '无法识别的中继配置',
			'setting.relay.scanQr' => '扫描二维码',
			'setting.relay.scanTitle' => '扫描二维码',
			'setting.relay.scanError' => '相机不可用',
			'setting.relay.confirmTitle' => '应用中继配置？',
			'setting.relay.apply' => '应用',
			'setting.relay.savedRestart' => '中继已保存，重启应用后生效',
			'setting.relay.test' => '连接测试',
			'setting.relay.testHint' => '向中继发送 STUN 探测',
			'setting.relay.testAction' => '测试',
			'setting.relay.testResult' => ({required Object ms}) => '${ms} ms',
			'setting.relay.testFailed' => ({required Object reason}) => '失败: ${reason}',
			'setting.security.title' => '安全',
			'setting.security.tls' => '端到端加密 (TLS)',
			'setting.security.plainWarning' => '明文传输，仅建议调试使用',
			'setting.security.restartHint' => '修改后重启应用生效',
			'setting.core.title' => '核心设置',
			'setting.core.server.title' => '服务器',
			_ => null,
		};
	}
}
