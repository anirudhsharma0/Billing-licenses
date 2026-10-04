import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/license_provider.dart';
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
    // Curated high-end color palette inspired by Oripio Fintech & Glassmorphic Mobile
    const primaryEmerald = Color(0xFF00A86B);
    const darkEmerald = Color(0xFF047857);
    const deepCharcoal = Color(0xFF0F172A);
    const accentIndigo = Color(0xFF4F46E5);
    const softMintBg = Color(0xFFE8F5EE);
    const surfaceWhite = Colors.white;
    const scaffoldBg = Color(0xFFF4F6F8);

    final baseTextTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);
    final outfitHeading = GoogleFonts.outfitTextTheme(Theme.of(context).textTheme);

    final mergedTextTheme = baseTextTheme.copyWith(
      displayLarge: outfitHeading.displayLarge?.copyWith(fontWeight: FontWeight.w800, color: deepCharcoal),
      displayMedium: outfitHeading.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: deepCharcoal),
      headlineMedium: outfitHeading.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: deepCharcoal),
      headlineSmall: outfitHeading.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: deepCharcoal),
      titleLarge: outfitHeading.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: deepCharcoal),
      titleMedium: outfitHeading.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: deepCharcoal),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LicenseProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
      ],
      child: MaterialApp(
        title: 'The Kishan Bharti Coop. M.P. Society Ltd.',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: primaryEmerald,
            primary: primaryEmerald,
            secondary: accentIndigo,
            tertiary: darkEmerald,
            surface: surfaceWhite,
            brightness: Brightness.light,
          ),
          textTheme: mergedTextTheme,
          scaffoldBackgroundColor: scaffoldBg,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: deepCharcoal,
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
              side: const BorderSide(color: Color(0xFFE5EAE8), width: 1.0),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            labelStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            floatingLabelStyle: const TextStyle(color: primaryEmerald, fontWeight: FontWeight.w700, fontSize: 13),
            hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryEmerald, width: 1.8),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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
                  return softMintBg;
                }
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryEmerald;
                }
                return const Color(0xFF64748B);
              }),
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE5EAE8),
            thickness: 1,
            space: 1,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
