import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nocodb_app_flutter/l10n/app_localizations.dart';
import 'package:nocodb_app_flutter/settings_page.dart';
import 'package:nocodb_app_flutter/mistake_book_page.dart';
import 'package:provider/provider.dart';
import 'locale_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'NocoDB App',
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('zh'), // Chinese
      ],
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF1F1F1F),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFE0E0E0),
          onPrimaryContainer: Color(0xFF1F1F1F),
          secondary: Color(0xFF5C5C5C),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFEEEEEE),
          onSecondaryContainer: Color(0xFF2B2B2B),
          tertiary: Color(0xFF7A7A7A),
          onTertiary: Color(0xFFFFFFFF),
          tertiaryContainer: Color(0xFFF2F2F2),
          onTertiaryContainer: Color(0xFF2B2B2B),
          error: Color(0xFFB00020),
          onError: Color(0xFFFFFFFF),
          errorContainer: Color(0xFFF2D7D7),
          onErrorContainer: Color(0xFF3B0000),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF1F1F1F),
          surfaceContainerHighest: Color(0xFFF3F3F3),
          onSurfaceVariant: Color(0xFF4A4A4A),
          outline: Color(0xFFBDBDBD),
          outlineVariant: Color(0xFFE0E0E0),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
          inverseSurface: Color(0xFF2B2B2B),
          onInverseSurface: Color(0xFFF5F5F5),
          inversePrimary: Color(0xFFD6D6D6),
          surfaceTint: Color(0xFF1F1F1F),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1F1F1F),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F1F1F),
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1F1F1F),
            side: const BorderSide(color: Color(0xFFBDBDBD)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF1F1F1F),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1F1F1F),
          unselectedItemColor: Color(0xFF7A7A7A),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    MistakeBookPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: AppLocalizations.of(context)!.mistakeBook,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
