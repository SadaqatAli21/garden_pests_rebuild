import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_pests_rebuild/providers/in_app_purchase_provider.dart';
import 'package:garden_pests_rebuild/providers/locale_provider.dart' hide MaterialApp;
import 'package:garden_pests_rebuild/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'core/app_theme.dart';
import 'core/services/analytics_services.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint("Firebase initialization success");

  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }



  runApp(
    ProviderScope(
      child: legacy_provider.MultiProvider(
        providers: [
          legacy_provider.ChangeNotifierProvider(
            create: (_) => InAppPurchaseProvider(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'Garden Pests',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('de'), // German
        Locale('hi'), // Hindi
        Locale('ar'), // Arabic
        Locale('tr'), // Turkish
        Locale('pt'), // Portuguese
        Locale('id'), // Indonesian
      ],

      home: const SplashScreen(),
    );
  }
}
