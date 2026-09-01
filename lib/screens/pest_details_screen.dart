import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../l10n/app_localizations.dart';

class PestDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pest;

  const PestDetailScreen({super.key, required this.pest});

  @override
  Widget build(BuildContext context) {
    final Color severityColor = _getSeverityColor(pest['severity']);
    final Color primaryColor = pest['color'] ?? AppTheme.primaryColor;

    final ImageProvider? heroImage = pest['imageAsset'] != null
        ? AssetImage(pest['imageAsset']) as ImageProvider
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Shrinking sticky image header ──────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _PestImageDelegate(
              expandedHeight: 300,
              collapsedHeight: 180,
              heroImage: heroImage,
              fallbackIcon: pest['icon'],
              fallbackColor: primaryColor,
              onBack: () => Navigator.pop(context),
            ),
          ),

          // ── Content Body ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pest['name'],
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSeverityBadge(
                      context,
                      pest['severity'],
                      severityColor,
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle(
                      AppLocalizations.of(context)!.overview,
                      Icons.description_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildRichText(
                      pest['description'] ??
                          AppLocalizations.of(context)!.noDescription,
                      Colors.grey[800]!,
                    ),
                    const SizedBox(height: 32),

                    if (pest['symptoms'] != null) ...[
                      _buildSectionTitle(
                        AppLocalizations.of(context)!.identificationAndSymptoms,
                        Icons.search,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        content: pest['symptoms'],
                        icon: Icons.info_outline,
                        color: Colors.blue.shade50,
                        textColor: Colors.blue.shade900,
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (pest['treatment'] != null) ...[
                      _buildSectionTitle(
                        AppLocalizations.of(context)!.treatmentAndControl,
                        Icons.medical_services_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        content: pest['treatment'],
                        icon: Icons.healing,
                        color: Colors.green.shade50,
                        textColor: Colors.green.shade900,
                      ),
                      const SizedBox(height: 32),
                    ],

                    if (pest['prevention'] != null) ...[
                      _buildSectionTitle(
                        AppLocalizations.of(context)!.prevention,
                        Icons.shield_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        content: pest['prevention'],
                        icon: Icons.security,
                        color: Colors.orange.shade50,
                        textColor: Colors.orange.shade900,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(
      BuildContext context,
      String severity,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            "${AppLocalizations.of(context)!.severity}: ${_getLocalizedSeverity(context, severity)}",
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedSeverity(BuildContext context, String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppLocalizations.of(context)!.high;
      case 'medium':
        return AppLocalizations.of(context)!.medium;
      case 'low':
        return AppLocalizations.of(context)!.low;
      default:
        return severity;
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String content,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColor.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(child: _buildRichText(content, textColor)),
        ],
      ),
    );
  }

  Widget _buildRichText(String text, Color baseColor) {
    List<TextSpan> spans = [];
    final RegExp exp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (Match match in exp.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, match.start),
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: baseColor,
              height: 1.6,
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: baseColor,
            fontWeight: FontWeight.w800,
            height: 1.6,
          ),
        ),
      );
      start = match.end;
    }

    if (start < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(start),
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: baseColor,
            height: 1.6,
          ),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  Color _getSeverityColor(String? severity) {
    switch (severity) {
      case 'High':
        return AppTheme.highSeverity;
      case 'Medium':
        return AppTheme.mediumSeverity;
      default:
        return AppTheme.primaryColor;
    }
  }
}

// ─── Custom shrinking image header delegate ───────────────────────────────────
class _PestImageDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final ImageProvider? heroImage;
  final IconData? fallbackIcon;
  final Color fallbackColor;
  final VoidCallback onBack;

  const _PestImageDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.heroImage,
    required this.fallbackColor,
    required this.onBack,
    this.fallbackIcon,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant _PestImageDelegate old) =>
      old.heroImage != heroImage ||
          old.expandedHeight != expandedHeight ||
          old.collapsedHeight != collapsedHeight;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    final progress = (shrinkOffset / (expandedHeight - collapsedHeight)).clamp(
      0.0,
      1.0,
    );
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image / Fallback ──────────────────────────────
          if (heroImage != null)
            Image(
              image: heroImage!,
              fit: BoxFit.cover,
              alignment: Alignment(0, -progress * 0.3),
              errorBuilder: (_, __, ___) => Container(
                color: fallbackColor.withOpacity(0.4),
                child: Icon(fallbackIcon, size: 80, color: Colors.white38),
              ),
            )
          else
            Container(
              color: fallbackColor.withOpacity(0.4),
              child: Center(
                child: Icon(fallbackIcon, size: 80, color: Colors.white38),
              ),
            ),

          // ── Gradient overlay ──────────────────────────────
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35 + progress * 0.25),
                  Colors.transparent,
                  Colors.black.withOpacity(0.15 + progress * 0.25),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── Back button ───────────────────────────────────
          Positioned(
            top: topPadding + 8,
            left: 12,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
