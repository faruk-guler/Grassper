import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants.dart';
import 'models/note_model.dart';
import 'providers/note_provider.dart';
import 'screens/home_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Date Formatting for Turkish
  await initializeDateFormatting('tr_TR', null);

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NoteAdapter());

  // Open Boxes
  await Hive.openBox<Note>('notesBox');
  await Hive.openBox<Note>('trashBox');
  await Hive.openBox('settingsBox');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: const GrassperApp(),
    ),
  );
}

class GrassperApp extends StatelessWidget {
  const GrassperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        // Show a minimal loading screen while provider initializes from Hive
        if (noteProvider.isLoading) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('tr', 'TR')],
            locale: const Locale('tr', 'TR'),
            home: Scaffold(
              backgroundColor: noteProvider.isDarkMode
                  ? AppColors.darkBg
                  : AppColors.lightBg,
              body: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Trigger auto-backup if needed
        WidgetsBinding.instance.addPostFrameCallback((_) {
          noteProvider.autoBackupIfNeeded();
        });

        return MaterialApp(
          title: 'Grassper',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('tr', 'TR')],
          locale: const Locale('tr', 'TR'),
          themeMode: noteProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.outfitTextTheme(
              ThemeData.light().textTheme,
            ),
            brightness: Brightness.light,
            scaffoldBackgroundColor: AppColors.lightBg,
            primaryColor: AppColors.lightAccent,
            cardColor: AppColors.lightCardBg,
            dividerColor: AppColors.lightBorder,
            iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            textTheme: GoogleFonts.outfitTextTheme(
              ThemeData.dark().textTheme,
            ),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.darkBg,
            primaryColor: AppColors.darkAccent,
            cardColor: AppColors.darkCardBg,
            dividerColor: AppColors.darkBorder,
            iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
