import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../core/services/analytics_services.dart';
import '../providers/scan_provider.dart';
import 'result_screen.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  final File imageFile; // Original full image for background
  final File? croppedFile; // Cropped image for the analysis centerpiece
  final Future<void> Function() onAnalyze;

  const LoadingScreen({
    super.key,
    required this.imageFile,
    this.croppedFile,
    required this.onAnalyze,
  });

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _messageTimer;
  int _messageIndex = 0;
  List<String> _getLoadingMessages(AppLocalizations l10n) => [
    l10n.analyzingLeafStructure,
    l10n.scanningForPests,
    l10n.identifyingInsects,
    l10n.checkingPlantHealth,
    l10n.comparingWithDatabase,
    l10n.finalizingAnalysis,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messageTimer == null) {
      final l10n = AppLocalizations.of(context)!;
      _startMessageCycle(l10n);
    }
  }

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _startAnalysis();
  }

  void _startMessageCycle(AppLocalizations l10n) {
    final messagesLength = _getLoadingMessages(l10n).length;
    _messageTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % messagesLength;
        });
      }
    });
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  void _startAnalysis() async {
    // Artificial delay to show off the cool animation (optional, but feels better)
    // Only delay on the first attempt (when there's no error yet)
    if (ref.read(scanProvider).error == null) {
      await Future.delayed(const Duration(seconds: 2));
    }

    await widget.onAnalyze();

    if (!mounted) return;

    // Check state after analysis
    final state = ref.read(scanProvider);

    if (state.result != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            result: state.result!,
            imageFile:
            widget.croppedFile ??
                widget.imageFile, // Use cropped for result if available
          ),
        ),
      );
    }
    // Note: We no longer pop on error here,
    // the build method will show the error UI instead.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scanProvider);
    final hasError = state.error != null;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Blurred Background Image
          Image.file(widget.imageFile, fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),

          // 2. Center Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Scanning Card or Error Icon
                if (hasError) _buildErrorIcon() else _buildScanningCard(),

                const SizedBox(height: 40),

                // Status/Error Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    hasError ? l10n.analysisFailed : l10n.analyzingPlant,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    hasError ? state.error! : _getLoadingMessages(l10n)[_messageIndex],
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: hasError ? Colors.redAccent[100] : Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                if (hasError)
                  _buildErrorActions(context)
                else
                  _buildProgressIndicator(),

                const Spacer(),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningCard() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              widget.croppedFile ?? widget.imageFile,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(top: 0, left: 0, child: _buildCorner(0)),
        Positioned(top: 0, right: 0, child: _buildCorner(1)),
        Positioned(bottom: 0, right: 0, child: _buildCorner(2)),
        Positioned(bottom: 0, left: 0, child: _buildCorner(3)),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              top: _animation.value * 280,
              left: 10,
              right: 10,
              child: Column(
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.8),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: CustomPaint(painter: GridPainter()),
        ),
      ],
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.redAccent, width: 3),
      ),
      child: const Icon(
        Icons.error_outline_rounded,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 200,
      child: LinearProgressIndicator(
        backgroundColor: Colors.white10,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        borderRadius: BorderRadius.circular(10),
        minHeight: 6,
      ),
    );
  }

  Widget _buildErrorActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        SizedBox(
          width: 220,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.replay_rounded),
            label: Text(l10n.retryAnalysis),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            onPressed: () {
              AnalyticsService.instance.logEvent(
                'loading_screen_onPressed_tapped',
              );
              return _startAnalysis();
            },
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            AnalyticsService.instance.logEvent(
              'loading_screen_onPressed_tapped',
            );
            return Navigator.pop(context);
          },
          child: Text(
            l10n.cancelAndGoBack,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner(int quarter) {
    return Transform.rotate(
      angle: quarter * 1.5708, // 90 degrees in radians
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
          border: Border(
            top: BorderSide(color: Colors.white, width: 4),
            left: BorderSide(color: Colors.white, width: 4),
          ),
        ),
      ),
    );
  }
}

// Simple Grid Painter for the tech look
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += size.width / 4) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += size.height / 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
