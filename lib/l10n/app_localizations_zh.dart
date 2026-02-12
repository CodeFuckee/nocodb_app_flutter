// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'NocoDB 应用';

  @override
  String get settings => '设置';

  @override
  String get mistakeBook => '错题本';

  @override
  String get nocodbUrl => 'NocoDB 网址';

  @override
  String get apiToken => 'API 令牌';

  @override
  String get mistakeBookTableId => '错题本表 ID';

  @override
  String get mistakeBookViewId => '错题本视图 ID';

  @override
  String get save => '保存';

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get previous => '上一题';

  @override
  String get next => '下一题';

  @override
  String get offset => '偏移量';

  @override
  String get retry => '重试';

  @override
  String get noMoreRecords => '没有更多记录或表为空。';

  @override
  String get errorPrefix => '错误: ';

  @override
  String get nocodbUrlHint => 'https://app.nocodb.com';

  @override
  String get ignoreSsl => '忽略 SSL 证书验证';

  @override
  String get language => '语言';

  @override
  String get systemDefault => '系统默认';

  @override
  String get english => '英语';

  @override
  String get chinese => '中文';
}
