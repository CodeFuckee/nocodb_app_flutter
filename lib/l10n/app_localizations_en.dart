// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NocoDB App';

  @override
  String get settings => 'Settings';

  @override
  String get mistakeBook => 'Mistake Book';

  @override
  String get nocodbUrl => 'NocoDB URL';

  @override
  String get apiToken => 'API Token';

  @override
  String get mistakeBookTableId => 'Mistake Book Table ID';

  @override
  String get mistakeBookViewId => 'Mistake Book View ID';

  @override
  String get save => 'Save';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get offset => 'Offset';

  @override
  String get retry => 'Retry';

  @override
  String get noMoreRecords => 'No more records or empty table.';

  @override
  String get errorPrefix => 'Error: ';

  @override
  String get nocodbUrlHint => 'https://app.nocodb.com';

  @override
  String get ignoreSsl => 'Ignore SSL Verification';

  @override
  String get language => 'Language';

  @override
  String get systemDefault => 'System Default';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';
}
