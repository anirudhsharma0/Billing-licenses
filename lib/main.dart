import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/license_provider.dart';
import 'providers/purchase_provider.dart';
import 'providers/receipt_provider.dart';
import 'providers/stock_provider.dart';
import 'screens/home_screen.dart';
import 'services/safe_http_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    HttpOverrides.global = SafeHttpOverrides();
  }
  runApp(const BillingApp());
}

class BillingApp extends StatelessWidget {
  const BillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Minimal High-Contrast (Print / Sunlight Friendly) color palette
    const primaryContrast = Color(0xFF111827);
    const secondaryContrast = Color(0xFF1F2937);
    const accentSlate = Color(0xFF334155);
    const deepInk = Color(0xFF030712);
    const softHighlightBg = Color(0xFFE2E8F0);
    const surfaceWhite = Colors.white;
    const scaffoldBg = Color(0xFFF8FAFC);
    const crispBorder = Color(0xFFCBD5E1);

    final baseTextTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);
    final outfitHeading = GoogleFonts.outfitTextTheme(Theme.of(context).textTheme);

    final mergedTextTheme = baseTextTheme.copyWith(
      displayLarge: outfitHeading.displayLarge?.copyWith(fontWeight: FontWeight.w800, color: deepInk),
      displayMedium: outfitHeading.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: deepInk),
      headlineMedium: outfitHeading.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: deepInk),
      headlineSmall: outfitHeading.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: deepInk),
      titleLarge: outfitHeading.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: deepInk),
      titleMedium: outfitHeading.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: deepInk),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: deepInk),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: primaryContrast),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LicenseProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => ReceiptProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
      ],
      child: MaterialApp(
        title: 'The Kishan Bharti Coop. M.P. Society Ltd.',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryContrast,
            primary: primaryContrast,
            onPrimary: Colors.white,
            secondary: accentSlate,
            onSecondary: Colors.white,
            tertiary: secondaryContrast,
            surface: surfaceWhite,
            onSurface: deepInk,
            outline: crispBorder,
            brightness: Brightness.light,
          ),
          textTheme: mergedTextTheme,
          scaffoldBackgroundColor: scaffoldBg,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: deepInk,
            elevation: 0,
            centerTitle: false,
            surfaceTintColor: Colors.transparent,
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: crispBorder, width: 1.2),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            labelStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w600),
            floatingLabelStyle: const TextStyle(color: primaryContrast, fontWeight: FontWeight.w700, fontSize: 13),
            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: crispBorder, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: crispBorder, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryContrast, width: 2.0),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryContrast,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryContrast,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              side: const BorderSide(color: Color(0xFF475569), width: 1.2),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: primaryContrast,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return softHighlightBg;
                }
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryContrast;
                }
                return const Color(0xFF334155);
              }),
              side: WidgetStateProperty.all(
                const BorderSide(color: crispBorder, width: 1.0),
              ),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: crispBorder,
            thickness: 1,
            space: 1,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
