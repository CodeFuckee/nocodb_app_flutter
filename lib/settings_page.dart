import 'package:flutter/material.dart';
import 'package:nocodb_app_flutter/utils/notify_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nocodb_app_flutter/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _tableIdController = TextEditingController();
  final _viewIdController = TextEditingController();
  final _familyExpenseTableIdController = TextEditingController();
  final _familyExpenseMonthlyTableIdController = TextEditingController();
  final _familyExpenseDailyTableIdController = TextEditingController();
  final _familyExpenseTypeTableIdController = TextEditingController();
  bool _isLoading = true;
  bool _ignoreSsl = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _urlController.text = prefs.getString('nocodb_url') ?? '';
      _tokenController.text = prefs.getString('nocodb_token') ?? '';
      _tableIdController.text = prefs.getString('nocodb_table_id') ?? '';
      _viewIdController.text = prefs.getString('nocodb_view_id') ?? '';
      _familyExpenseTableIdController.text =
          prefs.getString('family_expense_table_id') ?? '';
      _familyExpenseMonthlyTableIdController.text =
          prefs.getString('family_expense_monthly_table_id') ?? '';
      _familyExpenseDailyTableIdController.text =
          prefs.getString('family_expense_daily_table_id') ?? '';
      _familyExpenseTypeTableIdController.text =
          prefs.getString('family_expense_type_table_id') ?? '';
      _ignoreSsl = prefs.getBool('nocodb_ignore_ssl') ?? false;
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nocodb_url', _urlController.text);
    await prefs.setString('nocodb_token', _tokenController.text);
    await prefs.setString('nocodb_table_id', _tableIdController.text);
    await prefs.setString('nocodb_view_id', _viewIdController.text);
    await prefs.setString(
      'family_expense_table_id',
      _familyExpenseTableIdController.text,
    );
    await prefs.setString(
      'family_expense_monthly_table_id',
      _familyExpenseMonthlyTableIdController.text,
    );
    await prefs.setString(
      'family_expense_daily_table_id',
      _familyExpenseDailyTableIdController.text,
    );
    await prefs.setString(
      'family_expense_type_table_id',
      _familyExpenseTypeTableIdController.text,
    );
    await prefs.setBool('nocodb_ignore_ssl', _ignoreSsl);
    if (mounted) {
      NotifyUtils.showNotify(context, AppLocalizations.of(context)!.settingsSaved);
    }
  }

  Future<void> _openRepo() async {
    final uri = Uri.parse('https://github.com/CodeFuckee/nocodb_app_flutter');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      NotifyUtils.showNotify(context, '无法打开链接');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _tableIdController.dispose();
    _viewIdController.dispose();
    _familyExpenseTableIdController.dispose();
    _familyExpenseMonthlyTableIdController.dispose();
    _familyExpenseDailyTableIdController.dispose();
    _familyExpenseTypeTableIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              AppLocalizations.of(context)!.save,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'NocoDB URL',
                      hintText: 'https://app.nocodb.com',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'API Token',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _tableIdController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.mistakeBookTableId,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _viewIdController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.mistakeBookViewId,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _familyExpenseTableIdController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.familyExpenseTableId,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _familyExpenseMonthlyTableIdController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.familyExpenseMonthlyTableId,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _familyExpenseDailyTableIdController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.familyExpenseDailyTableId,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _familyExpenseTypeTableIdController,
                    decoration: InputDecoration(
                      labelText:
                          AppLocalizations.of(context)!.familyExpenseTypeTableId,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(AppLocalizations.of(context)!.ignoreSsl),
                    value: _ignoreSsl,
                    onChanged: (bool value) {
                      setState(() {
                        _ignoreSsl = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.language,
                      border: const OutlineInputBorder(),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Locale?>(
                        value: context.watch<LocaleProvider>().locale,
                        isExpanded: true,
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(AppLocalizations.of(context)!.systemDefault),
                          ),
                          DropdownMenuItem(
                            value: const Locale('en'),
                            child: Text(AppLocalizations.of(context)!.english),
                          ),
                          DropdownMenuItem(
                            value: const Locale('zh'),
                            child: Text(AppLocalizations.of(context)!.chinese),
                          ),
                        ],
                        onChanged: (Locale? newLocale) {
                          context.read<LocaleProvider>().setLocale(newLocale);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('GitHub'),
                    subtitle: const Text(
                      'https://github.com/CodeFuckee/nocodb_app_flutter',
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: _openRepo,
                  ),
                  if (_appVersion != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '版本: $_appVersion',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
}
