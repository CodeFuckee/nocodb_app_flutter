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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
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
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save'),
                  ),
                  const SizedBox(height: 12),
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
