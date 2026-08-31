import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';
import '../core/services/analytics_services.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'home_screen.dart';

class LanguageScreen extends ConsumerStatefulWidget {
  final bool isFromSettings;
  const LanguageScreen({super.key, this.isFromSettings = false});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnim;
  late Animation<double> _fadeAnim;
  String? _tempSelectedCode;

  final List<_LangData> _languages = const [
    _LangData(
      code: 'en',
      native: 'English',
      english: 'English',
      flag: 'assets/images/flag_uk.svg',
    ),
    _LangData(
      code: 'es',
      native: 'Español',
      english: 'Spanish',
      flag: 'assets/images/flag_es.svg',
    ),
    _LangData(
      code: 'fr',
      native: 'Français',
      english: 'French',
      flag: 'assets/images/flag_fr.svg',
    ),
    _LangData(
      code: 'de',
      native: 'Deutsch',
      english: 'German',
      flag: 'assets/images/flag_de.svg',
    ),
    _LangData(
      code: 'hi',
      native: 'हिन्दी',
      english: 'Hindi',
      flag: 'assets/images/flag_hi.svg',
    ),
    _LangData(
      code: 'ar',
      native: 'العربية',
      english: 'Arabic',
      flag: 'assets/images/flag_ar.svg',
    ),
    _LangData(
      code: 'tr',
      native: 'Türkçe',
      english: 'Turkish',
      flag: 'assets/images/flag_tr.svg',
    ),
    _LangData(
      code: 'pt',
      native: 'Português',
      english: 'Portuguese',
      flag: 'assets/images/flag_pr.svg',
    ),
    _LangData(
      code: 'id',
      native: 'Bahasa Indonesia',
      english: 'Indonesian',
      flag: 'assets/images/flag_in.svg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = ref.watch(localeProvider).languageCode;
    _tempSelectedCode ??= currentCode;

    final l10n = AppLocalizations.of(context);
    final selectedIdx = _languages
        .indexWhere((l) => l.code == _tempSelectedCode)
        .clamp(0, _languages.length - 1);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1A0C),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F2210), // top: deep forest
              Color(0xFF091520), // mid: dark blue-green
              Color(0xFF0B1A0C), // bottom: dark
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative glows
            Positioned(
              top: -80,
              left: -60,
              child: _Glow(
                color: AppTheme.primaryColor,
                opacity: 0.18,
                size: 280,
              ),
            ),
            Positioned(
              top: 60,
              right: -70,
              child: _Glow(color: Colors.teal, opacity: 0.12, size: 220),
            ),
            Positioned(
              bottom: 100,
              left: -40,
              child: _Glow(
                color: AppTheme.primaryColor,
                opacity: 0.08,
                size: 180,
              ),
            ),

            // Main layout
            SafeArea(
              child: Column(
                children: [
                  // ── Header ───────────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: _Header(
                      isFromSettings: widget.isFromSettings,
                      title: l10n?.selectLanguage ?? 'Select Language',
                      onBack: () => Navigator.pop(context),
                    ),
                  ),

                  // ── Language list ─────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      itemCount: _languages.length,
                      itemBuilder: (_, i) {
                        final lang = _languages[i];
                        final isSelected = selectedIdx == i;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LangTile(
                            data: lang,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _tempSelectedCode = lang.code;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Bottom bar ───────────────────────────────
                  _BottomBar(
                    selectedLang: _languages[selectedIdx],
                    l10n: l10n,
                    isFromSettings: widget.isFromSettings,
                    onContinue: () {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(Locale(_tempSelectedCode!));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Decorative glow helper ───────────────────────────────────────────────────
class _Glow extends StatelessWidget {
  final Color color;
  final double opacity;
  final double size;
  const _Glow({required this.color, required this.opacity, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isFromSettings;
  final String title;
  final VoidCallback onBack;

  const _Header({
    required this.isFromSettings,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, isFromSettings ? 4 : 20, 20, 16),
      child: Row(
        children: [
          if (isFromSettings)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ───────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final _LangData selectedLang;
  final AppLocalizations? l10n;
  final bool isFromSettings;
  final VoidCallback onContinue;

  const _BottomBar({
    required this.selectedLang,
    required this.l10n,
    required this.isFromSettings,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1A0C).withOpacity(0.97),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected language chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.28),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.primaryColor,
                    size: 15,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    selectedLang.native,
                    style: GoogleFonts.outfit(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '· ${selectedLang.english}',
                    style: GoogleFonts.outfit(
                      color: AppTheme.primaryColor.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {



                  onContinue();

                  if (isFromSettings) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n?.continueText ?? 'Continue',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ─── Language tile widget ──────────────────────────────────────────────────────
class _LangTile extends StatelessWidget {
  final _LangData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangTile({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.13)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.8)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            // Flag
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: SvgPicture.asset(
                  data.flag,
                  width: 42,
                  height: 42,
                  fit: BoxFit.cover,
                  placeholderBuilder: (_) => Container(
                    width: 42,
                    height: 42,
                    color: Colors.white12,
                    child: const Icon(
                      Icons.flag_rounded,
                      size: 20,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Names
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.native,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    data.english,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.75)
                          : Colors.white38,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Check indicator
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Container(
                key: const ValueKey('check'),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              )
                  : Container(
                key: const ValueKey('empty'),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────
class _LangData {
  final String code;
  final String native;
  final String english;
  final String flag;
  const _LangData({
    required this.code,
    required this.native,
    required this.english,
    required this.flag,
  });
}
