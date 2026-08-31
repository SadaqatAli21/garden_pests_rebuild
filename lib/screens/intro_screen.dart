import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../core/notification_service.dart';
import 'language_screen.dart';
import '../providers/locale_provider.dart';
import '../../core/services/permission_service.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache images to prevent slow loading
    precacheImage(
      const AssetImage('assets/images/pests/into_img1.jpg'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/pests/intro_img2.jpg'),
      context,
    );
    precacheImage(
      const AssetImage('assets/images/pests/intro_img3.jpg'),
      context,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context);

    final List<Map<String, dynamic>> slides = [
      {'image': 'assets/images/pests/into_img1.jpg'},
      {'image': 'assets/images/pests/intro_img2.jpg'},
      {'image': 'assets/images/pests/intro_img3.jpg'},
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          // 1. Top Image Section (50% of screen)
          Expanded(
            flex: 5,
            child: Container(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    child: Image.asset(
                      slides[index]['image'],
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. Bottom Content Section (50% of screen) - White "Card"
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Text Content
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              Text(
                                _getLocalizedTitle(l10n, _currentPage),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _getLocalizedDescription(l10n, _currentPage),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Controls
                      Column(
                        children: [
                          // Indicators
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              slides.length,
                                  (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 8,
                                width: _currentPage == index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? AppTheme.primaryColor
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {


                                if (_currentPage < slides.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _completeIntro();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: AppTheme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _currentPage == slides.length - 1
                                    ? (l10n?.getStarted ?? "Get Started")
                                    : (l10n?.next ?? "Next"),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedTitle(AppLocalizations? l10n, int index) {
    if (l10n == null) {
      if (index == 0) return "Identify Pests Instantly";
      if (index == 1) return "Get Expert Solutions";
      return "Track Your Garden";
    }
    if (index == 0) return l10n.introTitle1;
    if (index == 1) return l10n.introTitle2;
    return l10n.introTitle3;
  }

  String _getLocalizedDescription(AppLocalizations? l10n, int index) {
    if (l10n == null) {
      if (index == 0)
        return "Take a photo to instantly identify pests and diseases affecting your plants.";
      if (index == 1)
        return "Receive detailed treatment plans and expert advice to save your garden.";
      return "Keep a history of your scans and monitor the health of your plants over time.";
    }
    if (index == 0) return l10n.introDesc1;
    if (index == 1) return l10n.introDesc2;
    return l10n.introDesc3;
  }

  Future<void> _completeIntro() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LanguageScreen()),
    );
  }
}
