import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garden_pests_rebuild/screens/saved_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_theme.dart';
import '../core/services/analytics_services.dart';
import '../data/models/pest_results.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../../core/app_logger.dart';
import '../../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final PestResult result;
  final File? imageFile;

  const ResultScreen({super.key, required this.result, this.imageFile});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;
  int? _savedId;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _savedId = widget.result.id;
    _isFavorite = widget.result.isFavorite;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // Handle Auto-save if enabled and not already saved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAutoSave();
    });
  }

  Future<void> _checkAndAutoSave() async {
    final autoSaveEnabled = ref.read(settingsProvider).historyAutoSave;
    if (autoSaveEnabled && _savedId == null) {
      try {
        setState(() => _isSaving = true);
        final finalResult = widget.result.copyWith(
          isHistory: true,
          dateScanned: DateTime.now(),
          imagePath: widget.imageFile?.path ?? widget.result.imagePath,
        );
        final id = await ref
            .read(historyProvider.notifier)
            .saveScan(finalResult);
        if (mounted) {
          setState(() {
            _savedId = id;
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.scanAutoSaved),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        AppLogger.error("Auto-save failed", e, null, "ResultScreen");
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  PestResult get result => widget.result;
  File? get imageFile => widget.imageFile;

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    // Watch history to trigger rebuilds when items are added/removed
    ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return _buildDesktopLayout(context, ref);
          } else {
            return _buildMobileLayout(context, ref);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    ImageProvider? heroImage;
    if (imageFile != null) {
      heroImage = FileImage(imageFile!);
    } else if (result.imagePath != null) {
      heroImage = result.imagePath!.startsWith('assets/')
          ? AssetImage(result.imagePath!) as ImageProvider
          : FileImage(File(result.imagePath!));
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      // ── Fixed save button at bottom ──────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.background,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.15))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: _buildSaveButton(context, ref),
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Shrinking sticky image header ──────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _ResultImageDelegate(
              expandedHeight: 300,
              collapsedHeight: 180,
              heroImage: heroImage,
              onBack: () => Navigator.pop(context),
              onReport: () => _showReportDialog(context),
            ),
          ),

          // ── All body content ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewSection(context),

                  Builder(builder: (context) {
                    final isUnidentified = (result.plantName.toLowerCase().contains('unknown') || result.plantName.toLowerCase() == 'n/a');

                    if (isUnidentified) {
                      return Column(
                        children: [
                          const SizedBox(height: 40),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.plantNotIdentified,
                                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade300),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          const SizedBox(height: 24),

                          // Conditional Sections based on scanType
                          if (result.scanType == 'pest' || result.scanType == 'identify' || result.scanType == 'diagnose')
                            _buildPlantInfoSection(),

                          if (result.scanType == 'diagnose' || result.scanType == 'pest') ...[
                            const SizedBox(height: 24),
                            _buildHealthCareSection(),
                          ],

                          if (result.scanType == 'identify' || result.scanType == 'pest') ...[
                            const SizedBox(height: 24),
                            _buildCareGuideSection(),
                          ],

                          if (result.scanType == 'pest') ...[
                            const SizedBox(height: 24),
                            _buildInDepthSection(),
                            const SizedBox(height: 24),
                            _buildStatsSection(),
                            const SizedBox(height: 24),
                            _buildTreatmentTabs(context),
                          ],

                          // Render ALL other rich data from the new JSON schemas
                          ..._buildRichDataSections(),
                        ],
                      );
                    }
                  }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Panel: Image & Stats
        Expanded(
          flex: 4,
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      AnalyticsService.instance.logEvent(
                        'result_screen_onPressed_tapped',
                      );
                      return Navigator.pop(context);
                    },
                  ),
                  title: Text(
                    AppLocalizations.of(context)!.analysisResult,
                    style: GoogleFonts.outfit(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 300,
                            width: double.infinity,
                            child: _buildHeaderImage(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildOverviewSection(context, isDesktop: true),
                        const SizedBox(height: 24),

                        if (result.scanType == 'pest' || result.scanType == 'identify' || result.scanType == 'diagnose')
                          _buildPlantInfoSection(),

                        if (result.scanType == 'diagnose' || result.scanType == 'pest') ...[
                          const SizedBox(height: 24),
                          _buildHealthCareSection(),
                        ],

                        if (result.scanType == 'identify' || result.scanType == 'pest') ...[
                          const SizedBox(height: 24),
                          _buildCareGuideSection(),
                        ],

                        if (result.scanType == 'pest') ...[
                          const SizedBox(height: 24),
                          _buildInDepthSection(),
                          const SizedBox(height: 24),
                          _buildStatsSection(),
                        ],

                        // Render ALL other rich data
                        ..._buildRichDataSections(),

                        const SizedBox(height: 32),
                        _buildSaveButton(context, ref),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Panel: Details
        Expanded(
          flex: 6,
          child: Container(
            color: AppTheme.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: result.scanType == 'pest'
                  ? _buildTreatmentTabs(context)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRichDataSections() {
    final List<Widget> sections = [];
    final data = result.completeData;

    // Define sections we want to show and their icons/colors
    final sectionConfig = {
      'basic_info': {'icon': Icons.info_outline, 'color': Colors.blue},
      'history': {'icon': Icons.history_edu, 'color': Colors.brown},
      'growth': {'icon': Icons.trending_up, 'color': Colors.green},
      'care': {'icon': Icons.wb_sunny_outlined, 'color': Colors.orange},
      'safety': {'icon': Icons.security, 'color': Colors.red},
      'usage': {'icon': Icons.medical_services_outlined, 'color': Colors.purple},
      'benefits': {'icon': Icons.favorite_border, 'color': Colors.pink},
      'cost': {'icon': Icons.attach_money, 'color': Colors.teal},
      'inspiration': {'icon': Icons.lightbulb_outline, 'color': Colors.amber},
      'gardening': {'icon': Icons.grass, 'color': Colors.lightGreen},
      'business': {'icon': Icons.business_center_outlined, 'color': Colors.indigo},
      'finance': {'icon': Icons.pix_outlined, 'color': Colors.deepPurple},
      'disease': {'icon': Icons.bug_report_outlined, 'color': Colors.redAccent},
      'symptoms': {'icon': Icons.warning_amber_rounded, 'color': Colors.orangeAccent},
      'causes': {'icon': Icons.search_outlined, 'color': Colors.deepOrange},
      'treatment': {'icon': Icons.healing_outlined, 'color': Colors.teal},
      'prevention': {'icon': Icons.shield_outlined, 'color': Colors.blueAccent},
      'protection': {'icon': Icons.verified_user_outlined, 'color': Colors.greenAccent},
      'impact': {'icon': Icons.trending_down, 'color': Colors.red},
      'harvest': {'icon': Icons.agriculture, 'color': Colors.amber},
      'management': {'icon': Icons.admin_panel_settings_outlined, 'color': Colors.indigoAccent},
      'pest_details': {'icon': Icons.bug_report, 'color': Colors.red},
      'identification_guide': {'icon': Icons.search, 'color': Colors.amber},
      'damage_analysis': {'icon': Icons.report_problem_outlined, 'color': Colors.deepOrange},
      'lifecycle_and_environment': {'icon': Icons.loop, 'color': Colors.teal},
      'natural_predators': {'icon': Icons.pets, 'color': Colors.green},
      'prevention_and_control': {'icon': Icons.security, 'color': Colors.blue},
      'early_warning_signs': {'icon': Icons.warning_amber_rounded, 'color': Colors.orange},
      'risk_assessment': {'icon': Icons.assessment_outlined, 'color': Colors.purple},
      'action_plan': {'icon': Icons.playlist_add_check, 'color': Colors.indigo},
      'ai_advice': {'icon': Icons.auto_awesome, 'color': Colors.blueAccent},
    };

    for (var entry in sectionConfig.entries) {
      final key = entry.key;
      final config = entry.value;

      if (data.containsKey(key)) {
        final sectionData = data[key];
        if (sectionData != null) {
          sections.add(const SizedBox(height: 24));
          sections.add(_buildCardSection(
            title: _getLocalizedSectionTitle(context, key),
            icon: config['icon'] as IconData,
            color: config['color'] as Color,
            content: sectionData,
          ));
        }
      }
    }

    return sections;
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Color color,
    required dynamic content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _renderDynamicContent(content, color),
        ],
      ),
    );
  }

  Widget _renderDynamicContent(dynamic content, Color color) {
    if (content is Map) {
      final entries = content.entries.where((e) {
        final val = e.value;
        if (val == null) return false;
        final sVal = val.toString().toLowerCase();
        return sVal != 'n/a' && sVal.isNotEmpty && sVal != 'null' && sVal != '0' && sVal != '0.0';
      }).toList();

      if (entries.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map((e) {
          final key = _getLocalizedFieldKey(context, e.key.toString());
          final val = e.value;

          if (val is List) {
            return _buildBulletList(key, val.map((item) => _getLocalizedValue(context, item.toString())).toList(), color);
          } else if (val is Map) {
            final childContent = _renderDynamicContent(val, color);
            if (childContent is SizedBox) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(key, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  childContent,
                ],
              ),
            );
          } else {
            return _buildInfoRow(key, _getLocalizedValue(context, val.toString()), color);
          }
        }).toList(),
      );
    } else if (content is List) {
      final filteredList = content.where((item) {
        final sVal = item.toString().toLowerCase();
        return sVal != 'n/a' && sVal.isNotEmpty && sVal != 'null';
      }).toList();

      if (filteredList.isEmpty) return const SizedBox.shrink();

      return Column(
        children: filteredList.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline, color: color, size: 16),
              const SizedBox(width: 10),
              Expanded(child: Text(_getLocalizedValue(context, item.toString()), style: GoogleFonts.outfit(color: Colors.grey[800], height: 1.5))),
            ],
          ),
        )).toList(),
      );
    }
    return Text(_getLocalizedValue(context, content.toString()), style: GoogleFonts.outfit(color: Colors.grey[700]));
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    if (value.toLowerCase() == 'n/a' || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletList(String label, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.blueGrey[800], height: 1.5),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    ImageProvider imageProvider;

    if (imageFile != null) {
      imageProvider = FileImage(imageFile!);
    } else if (result.imagePath != null) {
      if (result.imagePath!.startsWith('assets/')) {
        imageProvider = AssetImage(result.imagePath!);
      } else {
        imageProvider = FileImage(File(result.imagePath!));
      }
    } else {
      return Container(
        color: Colors.grey[200],
        child: const Icon(
          Icons.image_not_supported,
          size: 50,
          color: Colors.grey,
        ),
      );
    }

    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      errorBuilder: (c, o, s) => Container(
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, {bool isDesktop = false}) {
    final l10n = AppLocalizations.of(context)!;
    final isPest = result.isPestDetected.toLowerCase() == 'yes';

    // Special behavior for Identify and Diagnose
    if (result.scanType == 'identify' || result.scanType == 'diagnose') {
      final isIdentify = result.scanType == 'identify';
      final title = result.getLocalizedDisplayName(context);
      final subtitle = result.getLocalizedSubtitle(context);
      final scientific = result.scientificName;
      final conf = result.completeData['confidence_score'] ?? result.completeData['health_confidence'] ?? result.confidence;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCard(
            title: title,
            subtitle: subtitle,
            icon: isIdentify ? Icons.search_rounded : Icons.health_and_safety_outlined,
            color: isIdentify ? Colors.green : _getSeverityColor(result.healthStatus),
          ),
          if (scientific.isNotEmpty && scientific != 'N/A') ...[
            const SizedBox(height: 8),
            Text(
              scientific,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
          ],
          const SizedBox(height: 12),
          _buildBadge(
            "${(num.parse(conf.toString())).toStringAsFixed(0)}% ${l10n.confidence}",
            Colors.blue,
            Icons.analytics_outlined,
          ),
        ],
      );
    }

    // Default 'pest' logic
    if (!isPest) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noPestDetected,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  Text(
                    l10n.keepHealthy, // Using "Keep your garden healthy" or similar
                    style: GoogleFonts.outfit(color: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (isDesktop) ...[
          Text(
            result.getLocalizedDisplayName(context),
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
        ],
        Text(
          result.scientificName,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Colors.grey[600],
          ),
          textAlign: isDesktop ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: isDesktop ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildBadge(
              result.severityLevel,
              _getSeverityColor(result.severityLevel),
              Icons.warning_amber_rounded,
            ),
            _buildBadge(
              "${result.confidence.toStringAsFixed(0)}% ${AppLocalizations.of(context)!.confidence}",
              Colors.blue,
              Icons.analytics_outlined,
            ),
            // ── Report AI chip ──────────────────────────────
            GestureDetector(
              onTap: () {
                AnalyticsService.instance.logEvent(
                  'result_screen_onTap_tapped',
                );
                return _showReportDialog(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      color: Colors.red.shade400,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)!.reportAI,
                      style: GoogleFonts.outfit(
                        color: Colors.red.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.aboutPest,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.getLocalizedDescription(context),
                style: GoogleFonts.outfit(color: Colors.grey[700], height: 1.5),
              ),
              if (result.identificationTips.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.identificationCues,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.identificationTips.map(
                      (tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.symptoms,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.getLocalizedSymptoms(context),
                style: GoogleFonts.outfit(color: Colors.grey[700], height: 1.5),
              ),
              if (result.damageDetails.isNotEmpty) ...[
                const SizedBox(height: 16),
                Divider(color: Colors.grey.withOpacity(0.1)),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.biologicalDamage,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.damageDetails,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInDepthSection() {
    final l10n = AppLocalizations.of(context)!;
    if (result.isPestDetected.toLowerCase() != 'yes') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.hostPlants.isNotEmpty) ...[
          Text(
            l10n.commonHostPlants,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.hostPlants
                .map(
                  (plant) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  plant,
                  style: GoogleFonts.outfit(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            )
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
        if (result.lifeCycle.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100.withOpacity(0.3),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.loop, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      l10n.pestLifeCycle,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  result.getLocalizedLifeCycle(context),
                  style: GoogleFonts.outfit(
                    color: Colors.blue.shade800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (result.favorableConditions.isNotEmpty) ...[
          _buildDetailCard(
            l10n.environmentalTriggers,
            result.getLocalizedFavorableConditions(context),
            Icons.wb_sunny_outlined,
            Colors.orange,
          ),
          const SizedBox(height: 24),
        ],
        if (result.economicImpact.isNotEmpty) ...[
          _buildDetailCard(
            l10n.economicImpact,
            result.getLocalizedEconomicImpact(context),
            Icons.trending_down,
            Colors.redAccent,
          ),
          const SizedBox(height: 24),
        ],
        if (result.longTermPrevention.isNotEmpty) ...[
          _buildDetailCard(
            l10n.multiSeasonStrategy,
            result.getLocalizedLongTermPrevention(context),
            Icons.calendar_month_outlined,
            Colors.green,
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildPlantInfoSection() {
    final l10n = AppLocalizations.of(context)!;
    if (result.plantName.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_florist, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Text(
                l10n.plantInfoTitle,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPlantDetailRow(l10n.plantName, result.getLocalizedDisplayName(context), Icons.label_important_outline),
          _buildPlantDetailRow(l10n.origin, result.getLocalizedOrigin(context), Icons.public),
          _buildPlantDetailRow(l10n.useCase, result.getLocalizedUseCase(context), Icons.work_outline),
          _buildPlantDetailRow(l10n.expectedPrice, result.getLocalizedExpectedPrice(context), Icons.currency_exchange),
          _buildPlantDetailRow(l10n.benefits, result.getLocalizedBenefits(context), Icons.stars_outlined, isLast: true),
        ],
      ),
    );
  }

  Widget _buildPlantDetailRow(String label, String value, IconData icon, {bool isLast = false}) {
    if (value.isEmpty || value == 'N/A') return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                if (value.contains(',') || value.contains('['))
                  ...value.replaceAll('[', '').replaceAll(']', '').split(',').where((s) => s.trim().isNotEmpty).map((item) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.circle, size: 6, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.trim(),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              color: Colors.grey[800],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
                else
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildHealthCareSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.health_and_safety, color: Colors.blue, size: 24),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.healthCareDiagnosis,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.overallStatus, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(result.healthStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result.getLocalizedHealthStatus(context),
                  style: GoogleFonts.outfit(color: _getSeverityColor(result.healthStatus), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.healthScore, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: result.healthScore / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(_getSeverityColor(result.healthStatus)),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.careRecommendations, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          ...result.getLocalizedCareRecommendations(context).map((rec) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.blue, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(rec, style: GoogleFonts.outfit(color: Colors.grey.shade800, height: 1.4))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildCareGuideSection() {
    final l10n = AppLocalizations.of(context)!;
    final careGuideText = result.getLocalizedCareGuide(context);
    if (careGuideText.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.green.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny_outlined, color: Colors.green, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                l10n.careGuideTitle,
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            careGuideText,
            style: GoogleFonts.outfit(
              fontSize: 15,
              height: 1.6,
              color: Colors.black87.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tips_and_updates_outlined, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  _getGardenerProTipLabel(context),
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
      String title,
      String content,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.outfit(color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            l10n.affectedArea,
            result.affectedAreaEstimate,
            Icons.grid_on,
          ),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildInfoItem(
            AppLocalizations.of(context)!.date,
            DateTime.now().toString().substring(0, 10),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }


  Widget _buildTreatmentTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (result.isPestDetected.toLowerCase() != 'yes') {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.treatmentPlan,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 60, // Increased height
          padding: const EdgeInsets.all(6), // Increased padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35), // More rounded
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: AppTheme.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            indicatorSize:
            TabBarIndicatorSize.tab, // Ensure indicator fills the tab
            labelPadding: const EdgeInsets.symmetric(
              horizontal: 4,
            ), // Reduced label padding to allow indicator to stretch more efficiently in space? No, actually we want the indicator to be bigger.
            // If we want the indicator to be bigger than text, we actually want sizable padding around the text inside the indicator.
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ), // Slightly larger text
            unselectedLabelStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
            tabs: [
              Tab(
                child: Text(
                  l10n.organic,
                  style: GoogleFonts.outfit(
                    color: result.organicTreatments.isEmpty ? Colors.grey.shade400 : null,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  l10n.chemical,
                  style: GoogleFonts.outfit(
                    color: result.chemicalTreatments.isEmpty ? Colors.grey.shade400 : null,
                  ),
                ),
              ),
              Tab(
                child: Text(
                  l10n.prevention,
                  style: GoogleFonts.outfit(
                    color: result.preventionTips.isEmpty ? Colors.grey.shade400 : null,
                  ),
                ),
              ),
            ],
            onTap: (index) {
              setState(() {});
            },
            dividerColor: Colors.transparent, // Remove default divider
          ),
        ),
        const SizedBox(height: 24),
        // Dynamic height content based on selection
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey<int>(_tabController.index),
            child: [
              _buildTreatmentList(result.organicTreatments),
              _buildChemicalList(result.chemicalTreatments),
              _buildPreventionList(result.getLocalizedPrevention(context)),
            ][_tabController.index],
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentList(List<Treatment> treatments) {
    if (treatments.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noOrganicTreatments,
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: treatments.length,
      itemBuilder: (context, index) {
        final t = treatments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16), // Increased margin
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Softer corners
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20), // Increased padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      // Added icon background
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18, // Increased font size
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  AppLocalizations.of(context)!.instructions,
                  t.instructions,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  AppLocalizations.of(context)!.frequency,
                  t.frequency,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChemicalList(List<ChemicalTreatment> treatments) {
    if (treatments.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noChemicalTreatments,
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: treatments.length,
      itemBuilder: (context, index) {
        final t = treatments[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.red.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.science,
                        color: Colors.orange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.name,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(AppLocalizations.of(context)!.dosage, t.dosage),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.safety,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.red[700],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        t.safetyPrecautions,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: Colors.red[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreventionList(List<String> tips) {
    if (tips.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noPreventionTips,
          style: GoogleFonts.outfit(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          color: Colors.blue.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.blue, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    tips[index],
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, WidgetRef ref) {
    // We consider it "Favorited" for the purpose of this button
    bool isFavorited = _isFavorite;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: _isSaving
            ? SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        )
            : Icon(
          isFavorited
              ? Icons.bookmark_added_rounded
              : Icons.bookmark_add_rounded,
          color: Colors.white,
        ),
        label: Text(
          _isSaving
              ? AppLocalizations.of(context)!.saving
              : (isFavorited
              ? AppLocalizations.of(context)!.savedToScans
              : AppLocalizations.of(context)!.saveScan),
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFavorited
              ? Colors.grey[400]
              : AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isFavorited ? 0 : 4,
          shadowColor: isFavorited
              ? Colors.transparent
              : AppTheme.primaryColor.withOpacity(0.4),
        ),
        onPressed: _isSaving
            ? null
            : () async {
          if (_isSaving) return;

          if (isFavorited) {
            // If already favorited, just show the snackbar again to allow "VIEW" action
            _showSuccessSnackBar(context);
            return;
          }

          setState(() => _isSaving = true);

          try {
            // We must respect the History toggle even when manually bookmarking
            final historyEnabled = ref
                .read(settingsProvider)
                .historyAutoSave;
            bool wasInHistory = _savedId != null;

            final finalResult = result.copyWith(
              id: _savedId,
              imagePath: imageFile?.path ?? result.imagePath,
              dateScanned: DateTime.now(),
              isFavorite: true,
              isHistory:
              historyEnabled && (wasInHistory || result.isHistory),
            );

            int newId;
            if (_savedId != null) {
              await ref
                  .read(historyProvider.notifier)
                  .updateScan(finalResult);
              newId = _savedId!;
            } else {
              newId = await ref
                  .read(historyProvider.notifier)
                  .saveScan(finalResult);
            }

            debugPrint(
              "DEBUG: Saved/Updated scan with ID: $newId to Favorites",
            );

            if (mounted) {
              setState(() {
                _savedId = newId;
                _isFavorite = true;
                _isSaving = false;
              });

              _showSuccessSnackBar(context);
            }
          } catch (e) {
            debugPrint("Error saving scan: $e");
            if (mounted) {
              setState(() => _isSaving = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!.failedToSave,
                    style: GoogleFonts.outfit(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context) {
    // Capture the navigator early before the current widget could be disposed
    final navigator = Navigator.of(context);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.scanSavedSuccess,
          style: GoogleFonts.outfit(),
        ),
        action: SnackBarAction(
          label: AppLocalizations.of(context)!.view,
          textColor: Colors.white,
          onPressed: () {
            AnalyticsService.instance.logEvent(
              'result_screen_onPressed_tapped',
            );

            navigator.push(
              MaterialPageRoute(
                builder: (context) => const SavedScansScreen(showAppBar: true),
              ),
            );
          },
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // â”€â”€â”€ Report AI dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withOpacity(0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.12),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.flag_rounded,
                        color: Colors.red.shade300,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.reportAIResult,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            result.pestName,
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        AnalyticsService.instance.logEvent(
                          'result_screen_onTap_tapped',
                        );
                        return Navigator.pop(ctx);
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white38,
                        size: 22,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  AppLocalizations.of(context)!.whatsWrong,
                  style: GoogleFonts.outfit(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 16),

                // â”€â”€ Selectable reason cards â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _ReportReasonPicker(
                  onSubmit: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        duration: const Duration(seconds: 3),
                        content: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade700,
                                Colors.green.shade900,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.reportSubmitted,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!.thanksImprove,
                                      style: GoogleFonts.outfit(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.highSeverity;
      case 'medium':
        return AppTheme.mediumSeverity;
      case 'low':
        return AppTheme.lowSeverity;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getLocalizedSectionTitle(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (key) {
      case 'basic_info':
        switch (lang) {
          case 'hi': return 'मूल जानकारी';
          case 'es': return 'Información Básica';
          case 'fr': return 'Informations de Base';
          case 'de': return 'Basisinformationen';
          case 'ar': return 'المعلومات الأساسية';
          case 'id': return 'Informasi Dasar';
          case 'pt': return 'Informações Básicas';
          case 'tr': return 'Temel Bilgiler';
          default: return 'Basic Info';
        }
      case 'history':
        switch (lang) {
          case 'hi': return 'इतिहास और उत्पत्ति';
          case 'es': return 'Historia y Origen';
          case 'fr': return 'Histoire et Origine';
          case 'de': return 'Geschichte & Herkunft';
          case 'ar': return 'التاريخ والأصل';
          case 'id': return 'Sejarah & Asal Usul';
          case 'pt': return 'História e Origem';
          case 'tr': return 'Tarihçe ve Köken';
          default: return 'History';
        }
      case 'growth':
        switch (lang) {
          case 'hi': return 'विकास और चरण';
          case 'es': return 'Crecimiento y Etapas';
          case 'fr': return 'Croissance et Étapes';
          case 'de': return 'Wachstum & Stufen';
          case 'ar': return 'النمو والمراحل';
          case 'id': return 'Pertumbuhan & Tahapan';
          case 'pt': return 'Crescimento e Estágios';
          case 'tr': return 'Büyüme ve Evreler';
          default: return 'Growth & Stages';
        }
      case 'care':
        switch (lang) {
          case 'hi': return 'देखभाल की आवश्यकताएं';
          case 'es': return 'Requisitos de Cuidado';
          case 'fr': return 'Exigences d\'Entretien';
          case 'de': return 'Pflegeanforderungen';
          case 'ar': return 'متطلبات العناية';
          case 'id': return 'Kebutuhan Perawatan';
          case 'pt': return 'Requisitos de Cuidados';
          case 'tr': return 'Bakım Gereksinimleri';
          default: return 'Care Requirements';
        }
      case 'safety':
        switch (lang) {
          case 'hi': return 'सुरक्षा और चेतावनी';
          case 'es': return 'Seguridad y Advertencias';
          case 'fr': return 'Sécurité et Avertissements';
          case 'de': return 'Sicherheit & Warnungen';
          case 'ar': return 'السلامة والتحذيرات';
          case 'id': return 'Keamanan & Peringatan';
          case 'pt': return 'Segurança e Avisos';
          case 'tr': return 'Güvenlik ve Uyarılar';
          default: return 'Safety & Warnings';
        }
      case 'usage':
        switch (lang) {
          case 'hi': return 'उपयोग और भाग';
          case 'es': return 'Usos y Partes';
          case 'fr': return 'Utilisations et Parties';
          case 'de': return 'Nutzung & Teile';
          case 'ar': return 'الاستخدامات والأجزاء';
          case 'id': return 'Penggunaan & Bagian';
          case 'pt': return 'Usos e Partes';
          case 'tr': return 'Kullanım ve Parçaları';
          default: return 'Uses & Parts';
        }
      case 'benefits':
        switch (lang) {
          case 'hi': return 'लाभ';
          case 'es': return 'Beneficios';
          case 'fr': return 'Avantages';
          case 'de': return 'Vorteile';
          case 'ar': return 'الفوائد';
          case 'id': return 'Manfaat';
          case 'pt': return 'Benefícios';
          case 'tr': return 'Faydaları';
          default: return 'Benefits';
        }
      case 'cost':
        switch (lang) {
          case 'hi': return 'बाजार और मूल्य';
          case 'es': return 'Mercado y Precio';
          case 'fr': return 'Marché et Prix';
          case 'de': return 'Markt & Preis';
          case 'ar': return 'السوق والسعر';
          case 'id': return 'Pasar & Harga';
          case 'pt': return 'Mercado e Preço';
          case 'tr': return 'Piyasa ve Fiyat';
          default: return 'Market & Price';
        }
      case 'inspiration':
        switch (lang) {
          case 'hi': return 'बागवानी प्रेरणा';
          case 'es': return 'Inspiración de Jardinería';
          case 'fr': return 'Inspiration de Jardinage';
          case 'de': return 'Garten-Inspiration';
          case 'ar': return 'إلهام البستنة';
          case 'id': return 'Inspirasi Berkebun';
          case 'pt': return 'Inspiração de Jardinagem';
          case 'tr': return 'Bahçecilik İlhamı';
          default: return 'Gardening Inspiration';
        }
      case 'gardening':
        switch (lang) {
          case 'hi': return 'उगाने के चरण';
          case 'es': return 'Pasos de Cultivo';
          case 'fr': return 'Étapes de Culture';
          case 'de': return 'Anbauschritte';
          case 'ar': return 'خطوات الزراعة';
          case 'id': return 'Langkah Penanaman';
          case 'pt': return 'Passos de Cultivo';
          case 'tr': return 'Yetiştirme Adımları';
          default: return 'Growing Steps';
        }
      case 'business':
        switch (lang) {
          case 'hi': return 'व्यवसाय और लाभ';
          case 'es': return 'Negocios y Retorno';
          case 'fr': return 'Affaires et Rentabilité';
          case 'de': return 'Geschäft & Rendite';
          case 'ar': return 'الأعمال والعائد';
          case 'id': return 'Bisnis & Hasil';
          case 'pt': return 'Negócios e Retorno';
          case 'tr': return 'İş ve Getiri';
          default: return 'Business & ROI';
        }
      case 'finance':
        switch (lang) {
          case 'hi': return 'वित्तीय अनुमान';
          case 'es': return 'Estimación Financiera';
          case 'fr': return 'Estimation Financière';
          case 'de': return 'Finanzschätzung';
          case 'ar': return 'التقدير المالي';
          case 'id': return 'Estimasi Keuangan';
          case 'pt': return 'Estimativa Financeira';
          case 'tr': return 'Finansal Tahmin';
          default: return 'Financial Estimation';
        }
      case 'disease':
        switch (lang) {
          case 'hi': return 'रोग विवरण';
          case 'es': return 'Detalles de la Enfermedad';
          case 'fr': return 'Détails de la Maladie';
          case 'de': return 'Krankheitsdetails';
          case 'ar': return 'تفاصيل المرض';
          case 'id': return 'Detail Penyakit';
          case 'pt': return 'Detalhes da Doença';
          case 'tr': return 'Hastalık Detayları';
          default: return 'Disease Details';
        }
      case 'symptoms':
        switch (lang) {
          case 'hi': return 'रोग के लक्षण';
          case 'es': return 'Síntomas de la Enfermedad';
          case 'fr': return 'Symptômes de la Maladie';
          case 'de': return 'Krankheitssymptome';
          case 'ar': return 'أعراض المرض';
          case 'id': return 'Gejala Penyakit';
          case 'pt': return 'Sintomas da Doença';
          case 'tr': return 'Hastalık Belirtileri';
          default: return 'Symptoms';
        }
      case 'causes':
        switch (lang) {
          case 'hi': return 'कारण और कारक';
          case 'es': return 'Causas y Factores';
          case 'fr': return 'Causes et Facteurs';
          case 'de': return 'Ursachen & Faktoren';
          case 'ar': return 'الأسباب والعوامل';
          case 'id': return 'Penyebab & Faktor';
          case 'pt': return 'Causas e Fatores';
          case 'tr': return 'Nedenler ve Faktörler';
          default: return 'Causes & Triggers';
        }
      case 'treatment':
        switch (lang) {
          case 'hi': return 'उपचार विधियां';
          case 'es': return 'Métodos de Tratamiento';
          case 'fr': return 'Méthodes de Traitement';
          case 'de': return 'Behandlungsmethoden';
          case 'ar': return 'طرق العلاج';
          case 'id': return 'Metode Pengobatan';
          case 'pt': return 'Métodos de Tratamento';
          case 'tr': return 'Tedavi Yöntemleri';
          default: return 'Treatment Methods';
        }
      case 'prevention':
        switch (lang) {
          case 'hi': return 'रोकथाम की रणनीतियाँ';
          case 'es': return 'Estrategias de Prevención';
          case 'fr': return 'Stratégies de Prévention';
          case 'de': return 'Präventionsstrategien';
          case 'ar': return 'استراتيجيات الوقاية';
          case 'id': return 'Strategi Pencegahan';
          case 'pt': return 'Estratégias de Prevenção';
          case 'tr': return 'Önleme Stratejileri';
          default: return 'Prevention Strategies';
        }
      case 'protection':
        switch (lang) {
          case 'hi': return 'पौधों की सुरक्षा';
          case 'es': return 'Protección de la Planta';
          case 'fr': return 'Protection de la Plante';
          case 'de': return 'Pflanzenschutz';
          case 'ar': return 'حماية النباتات';
          case 'id': return 'Perlindungan Tanaman';
          case 'pt': return 'Proteção da Planta';
          case 'tr': return 'Bitki Koruma';
          default: return 'Plant Protection';
        }
      case 'impact':
        switch (lang) {
          case 'hi': return 'फसल पर प्रभाव';
          case 'es': return 'Impacto en el Cultivo';
          case 'fr': return 'Impact sur les Cultures';
          case 'de': return 'Ernteauswirkungen';
          case 'ar': return 'التأثير على المحصول';
          case 'id': return 'Dampak pada Tanaman';
          case 'pt': return 'Impacto no Cultivo';
          case 'tr': return 'Ürün Etkisi';
          default: return 'Crop Impact';
        }
      case 'harvest':
        switch (lang) {
          case 'hi': return 'कटाई दिशानिर्देश';
          case 'es': return 'Guía de Cosecha';
          case 'fr': return 'Directives de Récolte';
          case 'de': return 'Ernte-Richtlinien';
          case 'ar': return 'إرشادات الحصاد';
          case 'id': return 'Panduan Panen';
          case 'pt': return 'Guia de Colheita';
          case 'tr': return 'Hasat Rehberi';
          default: return 'Harvest Guidelines';
        }
      case 'management':
        switch (lang) {
          case 'hi': return 'रोग प्रबंधन';
          case 'es': return 'Gestión de Enfermedades';
          case 'fr': return 'Gestion de la Maladie';
          case 'de': return 'Krankheitsmanagement';
          case 'ar': return 'إدارة الأمراض';
          case 'id': return 'Manajemen Penyakit';
          case 'pt': return 'Gestão de Doenças';
          case 'tr': return 'Hastalık Yönetimi';
          default: return 'Disease Management';
        }
      case 'pest_details':
        switch (lang) {
          case 'hi': return 'कीट विवरण';
          case 'es': return 'Detalles de la Plaga';
          case 'fr': return 'Détails du Nuisible';
          case 'de': return 'Schädlingsdetails';
          case 'ar': return 'تفاصيل الآفة';
          case 'id': return 'Detail Hama';
          case 'pt': return 'Detalhes da Praga';
          case 'tr': return 'Zararlı Detayları';
          default: return 'Pest Details';
        }
      case 'identification_guide':
        switch (lang) {
          case 'hi': return 'पहचान मार्गदर्शिका';
          case 'es': return 'Guía de Identificación';
          case 'fr': return 'Guide d\'Identification';
          case 'de': return 'Identifikationsleitfaden';
          case 'ar': return 'دليل التعرف';
          case 'id': return 'Panduan Identifikasi';
          case 'pt': return 'Guia de Identificação';
          case 'tr': return 'Tanımlama Rehberi';
          default: return 'Identification Guide';
        }
      case 'damage_analysis':
        switch (lang) {
          case 'hi': return 'क्षति विश्लेषण';
          case 'es': return 'Análisis de Daños';
          case 'fr': return 'Analyse des Dégâts';
          case 'de': return 'Schadensanalyse';
          case 'ar': return 'تحليل الأضرار';
          case 'id': return 'Analisis Kerusakan';
          case 'pt': return 'Análise de Danos';
          case 'tr': return 'Hasar Analizi';
          default: return 'Damage Analysis';
        }
      case 'lifecycle_and_environment':
        switch (lang) {
          case 'hi': return 'जीवन चक्र और आवास';
          case 'es': return 'Ciclo de Vida y Hábitat';
          case 'fr': return 'Cycle de Vie et Habitat';
          case 'de': return 'Lebenszyklus & Lebensraum';
          case 'ar': return 'دورة الحياة والموئل';
          case 'id': return 'Siklus Hidup & Habitat';
          case 'pt': return 'Ciclo de Vida e Hábitat';
          case 'tr': return 'Yaşam Döngüsü ve Yaşam Alanı';
          default: return 'Lifecycle & Habitat';
        }
      case 'natural_predators':
        switch (lang) {
          case 'hi': return 'प्राकृतिक शिकारी';
          case 'es': return 'Depredadores Naturales';
          case 'fr': return 'Prédateurs Naturels';
          case 'de': return 'Natürliche Feinde';
          case 'ar': return 'المفترسات الطبيعية';
          case 'id': return 'Predator Alami';
          case 'pt': return 'Predadores Naturais';
          case 'tr': return 'Doğal Avcılar';
          default: return 'Natural Predators';
        }
      case 'prevention_and_control':
        switch (lang) {
          case 'hi': return 'रोकथाम और नियंत्रण';
          case 'es': return 'Prevención y Control';
          case 'fr': return 'Prévention et Contrôle';
          case 'de': return 'Prävention & Kontrolle';
          case 'ar': return 'الوقاية والمكافحة';
          case 'id': return 'Pencegahan & Pengendalian';
          case 'pt': return 'Prevenção e Controle';
          case 'tr': return 'Önleme ve Kontrol';
          default: return 'Prevention & Control';
        }
      case 'early_warning_signs':
        switch (lang) {
          case 'hi': return 'शुरुआती चेतावनी के संकेत';
          case 'es': return 'Señales de Advertencia Temprana';
          case 'fr': return 'Signes d\'Avertissement Précoce';
          case 'de': return 'Frühwarnzeichen';
          case 'ar': return 'علامات التحذير المبكر';
          case 'id': return 'Tanda Peringatan Dini';
          case 'pt': return 'Sinais de Alerta Precoce';
          case 'tr': return 'Erken Uyarı İşaretleri';
          default: return 'Early Warning Signs';
        }
      case 'risk_assessment':
        switch (lang) {
          case 'hi': return 'जोखिम मूल्यांकन';
          case 'es': return 'Evaluación de Riesgos';
          case 'fr': return 'Évaluation des Risques';
          case 'de': return 'Risikobewertung';
          case 'ar': return 'تقيم المخاطر';
          case 'id': return 'Penilaian Risiko';
          case 'pt': return 'Avaliação de Risco';
          case 'tr': return 'Risk Değerlendirmesi';
          default: return 'Risk Assessment';
        }
      case 'action_plan':
        switch (lang) {
          case 'hi': return 'कार्य योजना';
          case 'es': return 'Plan de Acción';
          case 'fr': return 'Plan d\'Action';
          case 'de': return 'Aktionsplan';
          case 'ar': return 'خطة العمل';
          case 'id': return 'Rencana Tindakan';
          case 'pt': return 'Plano de Ação';
          case 'tr': return 'Eylem Planı';
          default: return 'Action Plan';
        }
      case 'ai_advice':
        switch (lang) {
          case 'hi': return 'एआई विशेषज्ञ सलाह';
          case 'es': return 'Consejo de Experto IA';
          case 'fr': return 'Conseils d\'Expert IA';
          case 'de': return 'KI-Expertenrat';
          case 'ar': return 'نصيحة خبير الذكاء الاصطناعي';
          case 'id': return 'Saran Pakar AI';
          case 'pt': return 'Conselho de Especialista IA';
          case 'tr': return 'Yapay Zeka Uzman Tavsiyesi';
          default: return 'AI Expert Advice';
        }
      default:
        return key.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _getLocalizedFieldKey(BuildContext context, String rawKey) {
    final lang = Localizations.localeOf(context).languageCode;
    final cleanKey = rawKey.trim().toLowerCase().replaceAll(' ', '_');

    switch (cleanKey) {
      case 'health_benefits':
        switch (lang) {
          case 'hi': return 'स्वास्थ्य लाभ';
          case 'es': return 'Beneficios para la Salud';
          case 'fr': return 'Bienfaits pour la Santé';
          case 'de': return 'Gesundheitliche Vorteile';
          case 'ar': return 'الفوائد الصحية';
          case 'id': return 'Manfaat Kesehatan';
          case 'pt': return 'Benefícios para a Saúde';
          case 'tr': return 'Sağlık Faydaları';
          default: return 'Health Benefits';
        }
      case 'currency':
      case 'currency_used':
        switch (lang) {
          case 'hi': return 'मुद्रा';
          case 'es': return 'Moneda';
          case 'fr': return 'Devise';
          case 'de': return 'Währung';
          case 'ar': return 'العملة';
          case 'id': return 'Mata Uang';
          case 'pt': return 'Moeda';
          case 'tr': return 'Para Birimi';
          default: return 'Currency';
        }
      case 'nursery_availability':
      case 'availability':
        switch (lang) {
          case 'hi': return 'नर्सरी उपलब्धता';
          case 'es': return 'Disponibilidad en Vivero';
          case 'fr': return 'Disponibilité en Pépinière';
          case 'de': return 'Verfügbarkeit in Gärtnereien';
          case 'ar': return 'توفره في المشتل';
          case 'id': return 'Ketersediaan Pembibitan';
          case 'pt': return 'Disponibilidade no Viveiro';
          case 'tr': return 'Fidanlık Bulunabilirliği';
          default: return 'Nursery Availability';
        }
      case 'gardning_difficulty_level':
      case 'gardening_difficulty_level':
      case 'difficulty_level':
      case 'gardening_difficulty':
        switch (lang) {
          case 'hi': return 'बागवानी कठिनाई स्तर';
          case 'es': return 'Nivel de Dificultad de Jardinería';
          case 'fr': return 'Niveau de Difficulté de Jardinage';
          case 'de': return 'Schwierigkeitsgrad beim Gärtnern';
          case 'ar': return 'مستوى صعوبة البستنة';
          case 'id': return 'Tingkat Kesulitan Berkebun';
          case 'pt': return 'Nível de Dificuldade de Jardinagem';
          case 'tr': return 'Bahçecilik Zorluk Seviyesi';
          default: return 'Gardening Difficulty Level';
        }
      case 'why_grow_this_plant':
      case 'why_grow':
        switch (lang) {
          case 'hi': return 'यह पौधा क्यों उगाएं';
          case 'es': return '¿Por qué cultivar esta planta?';
          case 'fr': return 'Pourquoi cultiver cette plante ?';
          case 'de': return 'Warum diese Pflanze anbauen?';
          case 'ar': return 'لماذا تزرع هذه النبتة؟';
          case 'id': return 'Mengapa Menanam Tanaman Ini';
          case 'pt': return 'Por que cultivar esta planta';
          case 'tr': return 'Neden Bu Bitkiyi Yetiştirmelisiniz';
          default: return 'Why Grow This Plant';
        }
      case 'success_stories':
      case 'stories':
        switch (lang) {
          case 'hi': return 'सफलता की कहानियां';
          case 'es': return 'Historias de Éxito';
          case 'fr': return 'Histoires de Succès';
          case 'de': return 'Erfolgsgeschichten';
          case 'ar': return 'قصص النجاح';
          case 'id': return 'Kisah Sukses';
          case 'pt': return 'Histórias de Sucesso';
          case 'tr': return 'Başarı Hikayeleri';
          default: return 'Success Stories';
        }
      case 'nutritional_value':
      case 'nutrition':
        switch (lang) {
          case 'hi': return 'पोषण मूल्य';
          case 'es': return 'Valor Nutricional';
          case 'fr': return 'Valeur Nutritive';
          case 'de': return 'Nährwert';
          case 'ar': return 'القيمة الغذائية';
          case 'id': return 'Nilai Gizi';
          case 'pt': return 'Valor Nutricional';
          case 'tr': return 'Besin Değeri';
          default: return 'Nutritional Value';
        }
      case 'medicinal_uses':
      case 'medicinal':
        switch (lang) {
          case 'hi': return 'औषधीय उपयोग';
          case 'es': return 'Usos Medicinales';
          case 'fr': return 'Utilisations Médicinales';
          case 'de': return 'Medizinische Nutzung';
          case 'ar': return 'الاستخدامات الطبية';
          case 'id': return 'Penggunaan Obat';
          case 'pt': return 'Usos Medicinais';
          case 'tr': return 'Tıbbi Kullanımlar';
          default: return 'Medicinal Uses';
        }
      case 'culinary_uses':
      case 'culinary':
        switch (lang) {
          case 'hi': return 'खाद्य व रसोई उपयोग';
          case 'es': return 'Usos Culinarios';
          case 'fr': return 'Utilisations Culinaires';
          case 'de': return 'Kulinarische Nutzung';
          case 'ar': return 'الاستخدامات الطهوية';
          case 'id': return 'Penggunaan Kuliner';
          case 'pt': return 'Usos Culinários';
          case 'tr': return 'Mutfak Kullanımları';
          default: return 'Culinary Uses';
        }
      case 'family':
        switch (lang) {
          case 'hi': return 'कुल (Family)';
          case 'es': return 'Familia';
          case 'fr': return 'Famille';
          case 'de': return 'Familie';
          case 'ar': return 'العائلة';
          case 'id': return 'Suku / Familia';
          case 'pt': return 'Família';
          case 'tr': return 'Familya';
          default: return 'Family';
        }
      case 'genus':
        switch (lang) {
          case 'hi': return 'वंश (Genus)';
          case 'es': return 'Género';
          case 'fr': return 'Genre';
          case 'de': return 'Gattung';
          case 'ar': return 'الجنس';
          case 'id': return 'Genus';
          case 'pt': return 'Gênero';
          case 'tr': return 'Cins';
          default: return 'Genus';
        }
      case 'species':
        switch (lang) {
          case 'hi': return 'प्रजाति (Species)';
          case 'es': return 'Especie';
          case 'fr': return 'Espèce';
          case 'de': return 'Art';
          case 'ar': return 'النوع';
          case 'id': return 'Spesies';
          case 'pt': return 'Espécie';
          case 'tr': return 'Tür';
          default: return 'Species';
        }
      case 'common_names':
        switch (lang) {
          case 'hi': return 'सामान्य नाम';
          case 'es': return 'Nombres Comunes';
          case 'fr': return 'Noms Communs';
          case 'de': return 'Gebräuchliche Namen';
          case 'ar': return 'الأسماء الشائعة';
          case 'id': return 'Nama Umum';
          case 'pt': return 'Nomes Comuns';
          case 'tr': return 'Yaygın İsimler';
          default: return 'Common Names';
        }
      case 'origin_history':
        switch (lang) {
          case 'hi': return 'उत्पत्ति और इतिहास';
          case 'es': return 'Historia y Origen';
          case 'fr': return 'Histoire d\'Origine';
          case 'de': return 'Herkunftsgeschichte';
          case 'ar': return 'تاريخ الأصل';
          case 'id': return 'Sejarah Asal';
          case 'pt': return 'História de Origem';
          case 'tr': return 'Köken Tarihçesi';
          default: return 'Origin History';
        }
      case 'historical_uses':
        switch (lang) {
          case 'hi': return 'ऐतिहासिक उपयोग';
          case 'es': return 'Usos Históricos';
          case 'fr': return 'Utilisations Historiques';
          case 'de': return 'Historische Nutzung';
          case 'ar': return 'الاستخدامات التاريخية';
          case 'id': return 'Penggunaan Sejarah';
          case 'pt': return 'Usos Históricos';
          case 'tr': return 'Tarihi Kullanımları';
          default: return 'Historical Uses';
        }
      case 'cultural_significance':
        switch (lang) {
          case 'hi': return 'सांस्कृतिक महत्व';
          case 'es': return 'Importancia Cultural';
          case 'fr': return 'Signification Culturelle';
          case 'de': return 'Kulturelle Bedeutung';
          case 'ar': return 'الأهمية الثقافية';
          case 'id': return 'Signifikansi Budaya';
          case 'pt': return 'Significado Cultural';
          case 'tr': return 'Kültürel Önemi';
          default: return 'Cultural Significance';
        }
      case 'growth_stages':
        switch (lang) {
          case 'hi': return 'विकास के चरण';
          case 'es': return 'Etapas de Crecimiento';
          case 'fr': return 'Étapes de Croissance';
          case 'de': return 'Wachstumsphasen';
          case 'ar': return 'مراحل النمو';
          case 'id': return 'Tahap Pertumbuhan';
          case 'pt': return 'Estágios de Crescimento';
          case 'tr': return 'Büyüme Evreleri';
          default: return 'Growth Stages';
        }
      case 'growth_duration_days':
        switch (lang) {
          case 'hi': return 'अवधि (दिन)';
          case 'es': return 'Duración (Días)';
          case 'fr': return 'Durée (Jours)';
          case 'de': return 'Dauer (Tage)';
          case 'ar': return 'المدة (بالأيام)';
          case 'id': return 'Durasi (Hari)';
          case 'pt': return 'Duração (Dias)';
          case 'tr': return 'Süre (Gün)';
          default: return 'Growth Duration (Days)';
        }
      case 'max_height':
        switch (lang) {
          case 'hi': return 'अधिकतम ऊंचाई';
          case 'es': return 'Altura Máxima';
          case 'fr': return 'Hauteur Maximale';
          case 'de': return 'Maximale Höhe';
          case 'ar': return 'الارتفاع الأقصى';
          case 'id': return 'Tinggi Maksimal';
          case 'pt': return 'Altura Máxima';
          case 'tr': return 'Maksimum Yükseklik';
          default: return 'Max Height';
        }
      case 'spread_width':
        switch (lang) {
          case 'hi': return 'चौड़ाई';
          case 'es': return 'Ancho de Propagación';
          case 'fr': return 'Largeur';
          case 'de': return 'Breite';
          case 'ar': return 'العرض الأقصى';
          case 'id': return 'Lebar Sebaran';
          case 'pt': return 'Largura';
          case 'tr': return 'Yayılma Genişliği';
          default: return 'Spread Width';
        }
      case 'water_requirement':
        switch (lang) {
          case 'hi': return 'पानी की आवश्यकता';
          case 'es': return 'Requisito de Agua';
          case 'fr': return 'Besoins en Eau';
          case 'de': return 'Wasserbedarf';
          case 'ar': return 'احتياجات المياه';
          case 'id': return 'Kebutuhan Air';
          case 'pt': return 'Requisito de Água';
          case 'tr': return 'Su Gereksinimi';
          default: return 'Water Requirement';
        }
      case 'sunlight':
        switch (lang) {
          case 'hi': return 'सूर्य का प्रकाश';
          case 'es': return 'Luz Solar';
          case 'fr': return 'Ensoleillement';
          case 'de': return 'Sonnenlicht';
          case 'ar': return 'ضوء الشمس';
          case 'id': return 'Sinar Matahari';
          case 'pt': return 'Luz Solar';
          case 'tr': return 'Güneş Işığı';
          default: return 'Sunlight';
        }
      case 'soil_type':
        switch (lang) {
          case 'hi': return 'मिट्टी का प्रकार';
          case 'es': return 'Tipo de Suelo';
          case 'fr': return 'Type de Sol';
          case 'de': return 'Bodentyp';
          case 'ar': return 'نوع التربة';
          case 'id': return 'Jenis Tanah';
          case 'pt': return 'Tipo de Solo';
          case 'tr': return 'Toprak Tipi';
          default: return 'Soil Type';
        }
      case 'growth_rate':
        switch (lang) {
          case 'hi': return 'विकास की दर';
          case 'es': return 'Tasa de Crecimiento';
          case 'fr': return 'Taux de Croissance';
          case 'de': return 'Wachstumsrate';
          case 'ar': return 'معدل النمو';
          case 'id': return 'Tingkat Pertumbuhan';
          case 'pt': return 'Taxa de Crescimento';
          case 'tr': return 'Büyüme Hızı';
          default: return 'Growth Rate';
        }
      case 'fertilizers':
        switch (lang) {
          case 'hi': return 'उर्वरक';
          case 'es': return 'Fertilizantes';
          case 'fr': return 'Engrais';
          case 'de': return 'Dünger';
          case 'ar': return 'الأسمدة';
          case 'id': return 'Pupuk';
          case 'pt': return 'Fertilizantes';
          case 'tr': return 'Gübreler';
          default: return 'Fertilizers';
        }
      case 'is_edible':
        switch (lang) {
          case 'hi': return 'खाने योग्य';
          case 'es': return 'Comestible';
          case 'fr': return 'Comestible';
          case 'de': return 'Essbar';
          case 'ar': return 'صالح للأكل';
          case 'id': return 'Dapat Dimakan';
          case 'pt': return 'Comestível';
          case 'tr': return 'Yenilebilir';
          default: return 'Edible';
        }
      case 'is_toxic':
        switch (lang) {
          case 'hi': return 'विषैला';
          case 'es': return 'Tóxico';
          case 'fr': return 'Toxique';
          case 'de': return 'Giftig';
          case 'ar': return 'سام';
          case 'id': return 'Beracun';
          case 'pt': return 'Tóxico';
          case 'tr': return 'Toksik / Zehirli';
          default: return 'Toxic';
        }
      case 'warnings':
        switch (lang) {
          case 'hi': return 'चेतावनी';
          case 'es': return 'Advertencias';
          case 'fr': return 'Avertissements';
          case 'de': return 'Warnungen';
          case 'ar': return 'تحذيرات';
          case 'id': return 'Peringatan';
          case 'pt': return 'Avisos';
          case 'tr': return 'Uyarılar';
          default: return 'Warnings';
        }
      case 'usage_types':
        switch (lang) {
          case 'hi': return 'उपयोग के प्रकार';
          case 'es': return 'Tipos de Uso';
          case 'fr': return 'Types d\'Utilisation';
          case 'de': return 'Nutzungsarten';
          case 'ar': return 'أنواع الاستخدام';
          case 'id': return 'Jenis Penggunaan';
          case 'pt': return 'Tipos de Uso';
          case 'tr': return 'Kullanım Türleri';
          default: return 'Usage Types';
        }
      case 'parts_used':
        switch (lang) {
          case 'hi': return 'उपयोग किए जाने वाले भाग';
          case 'es': return 'Partes Utilizadas';
          case 'fr': return 'Parties Utilisées';
          case 'de': return 'Verwendete Teile';
          case 'ar': return 'الأجزاء المستخدمة';
          case 'id': return 'Bagian yang Digunakan';
          case 'pt': return 'Partes Utilizadas';
          case 'tr': return 'Kullanılan Parçalar';
          default: return 'Parts Used';
        }
      case 'how_to_use':
        switch (lang) {
          case 'hi': return 'उपयोग कैसे करें';
          case 'es': return 'Cómo Usar';
          case 'fr': return 'Comment Utiliser';
          case 'de': return 'Anwendung';
          case 'ar': return 'كيفية الاستخدام';
          case 'id': return 'Cara Penggunaan';
          case 'pt': return 'Como Usar';
          case 'tr': return 'Nasıl Kullanılır';
          default: return 'How To Use';
        }
      case 'step_by_step_growing':
      case 'step_by_step':
        switch (lang) {
          case 'hi': return 'चरण-दर-चरण उगाने की प्रक्रिया';
          case 'es': return 'Cultivo Paso a Paso';
          case 'fr': return 'Culture Étape par Étape';
          case 'de': return 'Schritt-für-Schritt-Anbau';
          case 'ar': return 'خطوات الزراعة';
          case 'id': return 'Langkah Penanaman';
          case 'pt': return 'Passos de Cultivo';
          case 'tr': return 'Adım Adım Yetiştirme';
          default: return 'Step-by-Step Growing';
        }
      case 'tools_required':
      case 'tools':
        switch (lang) {
          case 'hi': return 'आवश्यक उपकरण';
          case 'es': return 'Herramientas Requeridas';
          case 'fr': return 'Outils Requis';
          case 'de': return 'Erforderliche Werkzeuge';
          case 'ar': return 'الأدوات المطلوبة';
          case 'id': return 'Alat yang Dibutuhkan';
          case 'pt': return 'Ferramentas Necessárias';
          case 'tr': return 'Gerekli Aletler';
          default: return 'Tools Required';
        }
      case 'common_mistakes':
        switch (lang) {
          case 'hi': return 'सामान्य गलतियां';
          case 'es': return 'Errores Comunes';
          case 'fr': return 'Erreurs Courantes';
          case 'de': return 'Häufige Fehler';
          case 'ar': return 'الأخطاء الشائعة';
          case 'id': return 'Kesalahan Umum';
          case 'pt': return 'Erros Comuns';
          case 'tr': return 'Yaygın Hatalar';
          default: return 'Common Mistakes';
        }
      case 'market_demand':
        switch (lang) {
          case 'hi': return 'बाजार की मांग';
          case 'es': return 'Demanda del Mercado';
          case 'fr': return 'Demande du Marché';
          case 'de': return 'Marktnachfrage';
          case 'ar': return 'الطلب في السوق';
          case 'id': return 'Permintaan Pasar';
          case 'pt': return 'Demanda do Mercado';
          case 'tr': return 'Piyasa Talebi';
          default: return 'Market Demand';
        }
      case 'selling_price_range':
      case 'price_range':
        switch (lang) {
          case 'hi': return 'बिक्री मूल्य सीमा';
          case 'es': return 'Rango de Precio de Venta';
          case 'fr': return 'Gamme de Prix de Vente';
          case 'de': return 'Verkaufspreisspanne';
          case 'ar': return 'نطاق سعر البيع';
          case 'id': return 'Kisaran Harga Jual';
          case 'pt': return 'Faixa de Preço de Venda';
          case 'tr': return 'Satış Fiyat Aralığı';
          default: return 'Selling Price Range';
        }
      case 'profit_margin_estimate':
      case 'profit_margin':
        switch (lang) {
          case 'hi': return 'अनुमानित लाभ मार्जिन';
          case 'es': return 'Margen de Ganancia Estimado';
          case 'fr': return 'Marge Bénéficiaire Estimée';
          case 'de': return 'Geschätzte Gewinnspanne';
          case 'ar': return 'هامش الربح التقديري';
          case 'id': return 'Estimasi Margin Keuntungan';
          case 'pt': return 'Margem de Lucro Estimada';
          case 'tr': return 'Tahmini Kar Marjı';
          default: return 'Estimated Profit Margin';
        }
      case 'target_customers':
        switch (lang) {
          case 'hi': return 'लक्षित ग्राहक';
          case 'es': return 'Clientes Objetivo';
          case 'fr': return 'Clients Cibles';
          case 'de': return 'Zielkunden';
          case 'ar': return 'العملاء المستهدفون';
          case 'id': return 'Target Pelanggan';
          case 'pt': return 'Clientes Alvo';
          case 'tr': return 'Hedef Müşteriler';
          default: return 'Target Customers';
        }
      case 'business_models':
        switch (lang) {
          case 'hi': return 'व्यापार मॉडल';
          case 'es': return 'Modelos de Negocio';
          case 'fr': return 'Modèles d\'Affaires';
          case 'de': return 'Geschäftsmodelle';
          case 'ar': return 'نماذج الأعمال';
          case 'id': return 'Model Bisnis';
          case 'pt': return 'Modelos de Negócio';
          case 'tr': return 'İş Modelleri';
          default: return 'Business Models';
        }
      case 'roi_estimation':
      case 'roi':
        switch (lang) {
          case 'hi': return 'निवेश पर रिटर्न (ROI)';
          case 'es': return 'Estimación de ROI';
          case 'fr': return 'Estimation du ROI';
          case 'de': return 'ROI-Schätzung';
          case 'ar': return 'تقدير العائد على الاستثمار';
          case 'id': return 'Estimasi ROI';
          case 'pt': return 'Estimativa de ROI';
          case 'tr': return 'ROI Tahmini';
          default: return 'ROI Estimation';
        }
      case 'scaling_potential':
        switch (lang) {
          case 'hi': return 'विस्तार की संभावना';
          case 'es': return 'Potencial de Escalabilidad';
          case 'fr': return 'Potentiel d\'Échelle';
          case 'de': return 'Skalierungspotenzial';
          case 'ar': return 'إمكانية التوسع';
          case 'id': return 'Potensi Skala Bisnis';
          case 'pt': return 'Potencial de Escala';
          case 'tr': return 'Büyüme Potansiyeli';
          default: return 'Scaling Potential';
        }
      case 'cost_per_plant':
        switch (lang) {
          case 'hi': return 'प्रति पौधा लागत';
          case 'es': return 'Costo por Planta';
          case 'fr': return 'Coût par Plante';
          case 'de': return 'Kosten pro Pflanze';
          case 'ar': return 'التكلفة لكل نبتة';
          case 'id': return 'Biaya per Tanaman';
          case 'pt': return 'Custo por Planta';
          case 'tr': return 'Bitki Başına Maliyet';
          default: return 'Cost Per Plant';
        }
      case 'total_investment':
        switch (lang) {
          case 'hi': return 'कुल निवेश';
          case 'es': return 'Inversión Total';
          case 'fr': return 'Investissement Total';
          case 'de': return 'Gesamtinvestition';
          case 'ar': return 'إجمالي الاستثمار';
          case 'id': return 'Total Investasi';
          case 'pt': return 'Investimento Total';
          case 'tr': return 'Toplam Yatırım';
          default: return 'Total Investment';
        }
      case 'expected_revenue':
        switch (lang) {
          case 'hi': return 'अपेक्षित राजस्व';
          case 'es': return 'Ingresos Esperados';
          case 'fr': return 'Revenus Attendus';
          case 'de': return 'Erwartete Einnahmen';
          case 'ar': return 'الإيرادات المتوقعة';
          case 'id': return 'Estimasi Pendapatan';
          case 'pt': return 'Receita Esperada';
          case 'tr': return 'Beklenen Gelir';
          default: return 'Expected Revenue';
        }
      case 'net_profit':
        switch (lang) {
          case 'hi': return 'शुद्ध लाभ';
          case 'es': return 'Ganancia Neta';
          case 'fr': return 'Bénéfice Net';
          case 'de': return 'Nettogewinn';
          case 'ar': return 'صافي الربح';
          case 'id': return 'Laba Bersih';
          case 'pt': return 'Lucro Líquido';
          case 'tr': return 'Net Kar';
          default: return 'Net Profit';
        }
      case 'break_even_time':
        switch (lang) {
          case 'hi': return 'लागत निकलने का समय';
          case 'es': return 'Tiempo de Equilibrio';
          case 'fr': return 'Temps de Rentabilité';
          case 'de': return 'Break-Even-Zeit';
          case 'ar': return 'فترة استرداد التكاليف';
          case 'id': return 'Waktu Impas';
          case 'pt': return 'Tempo de Retorno';
          case 'tr': return 'Başa Baş Noktası Süresi';
          default: return 'Break-Even Time';
        }
      case 'ai_description':
        switch (lang) {
          case 'hi': return 'एआई विवरण';
          case 'es': return 'Descripción IA';
          case 'fr': return 'Description IA';
          case 'de': return 'KI-Beschreibung';
          case 'ar': return 'وصف الذكاء الاصطناعي';
          case 'id': return 'Deskripsi AI';
          case 'pt': return 'Descrição IA';
          case 'tr': return 'Yapay Zeka Açıklaması';
          default: return 'AI Description';
        }
      case 'ai_gardening_advice':
        switch (lang) {
          case 'hi': return 'एआई बागवानी सलाह';
          case 'es': return 'Consejo de Jardinería IA';
          case 'fr': return 'Conseil Jardinage IA';
          case 'de': return 'KI-Gartenratschlag';
          case 'ar': return 'نصيحة البستنة من الذكاء الاصطناعي';
          case 'id': return 'Saran Berkebun AI';
          case 'pt': return 'Conselho de Jardinagem IA';
          case 'tr': return 'Yapay Zeka Bahçecilik Tavsiyesi';
          default: return 'AI Gardening Advice';
        }
      case 'ai_business_advice':
        switch (lang) {
          case 'hi': return 'एआई व्यापार सलाह';
          case 'es': return 'Consejo Comercial IA';
          case 'fr': return 'Conseil Commercial IA';
          case 'de': return 'KI-Geschäftsrat';
          case 'ar': return 'نصيحة الأعمال من الذكاء الاصطناعي';
          case 'id': return 'Saran Bisnis AI';
          case 'pt': return 'Conselho Comercial IA';
          case 'tr': return 'Yapay Zeka İş Tavsiyesi';
          default: return 'AI Business Advice';
        }
      case 'environmental_benefits':
        switch (lang) {
          case 'hi': return 'पर्यावरणीय लाभ';
          case 'es': return 'Beneficios Ambientales';
          case 'fr': return 'Avantages Environnementaux';
          case 'de': return 'Umweltvorteile';
          case 'ar': return 'الفوائد البيئية';
          case 'id': return 'Manfaat Lingkungan';
          case 'pt': return 'Benefícios Ambientais';
          case 'tr': return 'Çevresel Faydaları';
          default: return 'Environmental Benefits';
        }
      case 'economic_value':
        switch (lang) {
          case 'hi': return 'आर्थिक मूल्य';
          case 'es': return 'Valor Económico';
          case 'fr': return 'Valeur Économique';
          case 'de': return 'Wirtschaftlicher Wert';
          case 'ar': return 'القيمة الاقتصادية';
          case 'id': return 'Nilai Ekonomi';
          case 'pt': return 'Valor Econômico';
          case 'tr': return 'Ekonomik Değer';
          default: return 'Economic Value';
        }
      case 'air_purification_score':
        switch (lang) {
          case 'hi': return 'वायु शुद्धिकरण स्कोर';
          case 'es': return 'Puntuación de Purificación de Aire';
          case 'fr': return 'Score de Purification d\'Air';
          case 'de': return 'Luftreinigungswert';
          case 'ar': return 'درجة تنقية الهواء';
          case 'id': return 'Skor Pemurni Udara';
          case 'pt': return 'Pontuação de Purificação do Ar';
          case 'tr': return 'Hava Temizleme Puanı';
          default: return 'Air Purification Score';
        }
      case 'daily_tips':
        switch (lang) {
          case 'hi': return 'दैनिक टिप्स';
          case 'es': return 'Consejos Diarios';
          case 'fr': return 'Conseils Quotidiens';
          case 'de': return 'Tägliche Tipps';
          case 'ar': return 'نصائح يومية';
          case 'id': return 'Tips Harian';
          case 'pt': return 'Dicas Diárias';
          case 'tr': return 'Günlük İpuçları';
          default: return 'Daily Tips';
        }
      case 'harvest_method':
        switch (lang) {
          case 'hi': return 'कटाई का तरीका';
          case 'es': return 'Método de Cosecha';
          case 'fr': return 'Méthode de Récolte';
          case 'de': return 'Erntemethode';
          case 'ar': return 'طريقة الحصاد';
          case 'id': return 'Metode Panen';
          case 'pt': return 'Método de Colheita';
          case 'tr': return 'Hasat Yöntemi';
          default: return 'Harvest Method';
        }
      case 'harvest_frequency':
        switch (lang) {
          case 'hi': return 'कटाई की आवृत्ति';
          case 'es': return 'Frecuencia de Cosecha';
          case 'fr': return 'Fréquence de Récolte';
          case 'de': return 'Erntefrequenz';
          case 'ar': return 'تكرار الحصاد';
          case 'id': return 'Frekuensi Panen';
          case 'pt': return 'Frequência de Colheita';
          case 'tr': return 'Hasat Sıklığı';
          default: return 'Harvest Frequency';
        }
      case 'storage_methods':
        switch (lang) {
          case 'hi': return 'भंडारण के तरीके';
          case 'es': return 'Métodos de Almacenamiento';
          case 'fr': return 'Méthodes de Stockage';
          case 'de': return 'Lagerungsmethoden';
          case 'ar': return 'طرق التخزين';
          case 'id': return 'Metode Penyimpanan';
          case 'pt': return 'Métodos de Armazenamento';
          case 'tr': return 'Depolama Yöntemleri';
          default: return 'Storage Methods';
        }
      case 'post_harvest_processing':
        switch (lang) {
          case 'hi': return 'कटाई के बाद की प्रक्रिया';
          case 'es': return 'Procesamiento Postcosecha';
          case 'fr': return 'Traitement Post-Récolte';
          case 'de': return 'Nachernteverarbeitung';
          case 'ar': return 'معالجة ما بعد الحصاد';
          case 'id': return 'Pengolahan Pasca Panen';
          case 'pt': return 'Processamento Pós-Colheita';
          case 'tr': return 'Hasat Sonrası İşleme';
          default: return 'Post-Harvest Processing';
        }
      case 'spread_risk':
        switch (lang) {
          case 'hi': return 'फैलने का जोखिम';
          case 'es': return 'Riesgo de Propagación';
          case 'fr': return 'Risque de Propagation';
          case 'de': return 'Ausbreitungsrisiko';
          case 'ar': return 'خطر الانتشار';
          case 'id': return 'Risiko Penyebaran';
          case 'pt': return 'Risco de Propagação';
          case 'tr': return 'Yayılma Riski';
          default: return 'Spread Risk';
        }
      case 'affected_area_percentage':
        switch (lang) {
          case 'hi': return 'प्रभावित क्षेत्र (%)';
          case 'es': return 'Área Afectada (%)';
          case 'fr': return 'Zone Affectée (%)';
          case 'de': return 'Betroffener Bereich (%)';
          case 'ar': return 'المنطقة المصابة (%)';
          case 'id': return 'Area Terdampak (%)';
          case 'pt': return 'Área Afetada (%)';
          case 'tr': return 'Etkilenen Alan (%)';
          default: return 'Affected Area (%)';
        }
      case 'recovery_chance':
        switch (lang) {
          case 'hi': return 'रिकवरी की संभावना';
          case 'es': return 'Probabilidad de Recuperación';
          case 'fr': return 'Chances de Rétablissement';
          case 'de': return 'Erholungschance';
          case 'ar': return 'فرصة التعافي';
          case 'id': return 'Peluang Pemulihan';
          case 'pt': return 'Chance de Recuperação';
          case 'tr': return 'Iyileşme Şansı';
          default: return 'Recovery Chance';
        }
      case 'advanced_methods':
        switch (lang) {
          case 'hi': return 'उन्नत उपचार विधियां';
          case 'es': return 'Métodos Avanzados';
          case 'fr': return 'Méthodes Avancées';
          case 'de': return 'Fortgeschrittene Methoden';
          case 'ar': return 'طرق متقدمة';
          case 'id': return 'Metode Lanjutan';
          case 'pt': return 'Métodos Avançados';
          case 'tr': return 'Gelişmiş Yöntemler';
          default: return 'Advanced Methods';
        }
      case 'daily_care':
        switch (lang) {
          case 'hi': return 'दैनिक देखभाल';
          case 'es': return 'Cuidado Diario';
          case 'fr': return 'Soins Quotidiens';
          case 'de': return 'Tägliche Pflege';
          case 'ar': return 'العناية اليومية';
          case 'id': return 'Perawatan Harian';
          case 'pt': return 'Cuidados Diários';
          case 'tr': return 'Günlük Bakım';
          default: return 'Daily Care';
        }
      case 'seasonal_prevention':
        switch (lang) {
          case 'hi': return 'मौसमी रोकथाम';
          case 'es': return 'Prevención Estacional';
          case 'fr': return 'Prévention Saisonière';
          case 'de': return 'Saisonale Prävention';
          case 'ar': return 'الوقاية الموسمية';
          case 'id': return 'Pencegahan Musiman';
          case 'pt': return 'Prevenção Sazonal';
          case 'tr': return 'Mevsimsel Önleme';
          default: return 'Seasonal Prevention';
        }
      case 'monitoring':
        switch (lang) {
          case 'hi': return 'निगरानी';
          case 'es': return 'Monitoreo';
          case 'fr': return 'Surveillance';
          case 'de': return 'Überwachung';
          case 'ar': return 'المراقبة';
          case 'id': return 'Pemantauan';
          case 'pt': return 'Monitoramento';
          case 'tr': return 'Izleme';
          default: return 'Monitoring';
        }
      case 'how_to_protect':
        switch (lang) {
          case 'hi': return 'सुरक्षा कैसे करें';
          case 'es': return 'Cómo Proteger';
          case 'fr': return 'Comment Protéger';
          case 'de': return 'Schutzmaßnahmen';
          case 'ar': return 'كيفية الحماية';
          case 'id': return 'Cara Melindungi';
          case 'pt': return 'Como Proteger';
          case 'tr': return 'Nasıl Korunur';
          default: return 'How To Protect';
        }
      case 'for_humans':
        switch (lang) {
          case 'hi': return 'मानवों के लिए सुरक्षा';
          case 'es': return 'Para Humanos';
          case 'fr': return 'Pour les Humains';
          case 'de': return 'Für Menschen';
          case 'ar': return 'للبشر';
          case 'id': return 'Untuk Manusia';
          case 'pt': return 'Para Humanos';
          case 'tr': return 'İnsanlar İçin';
          default: return 'For Humans';
        }
      case 'for_plants':
        switch (lang) {
          case 'hi': return 'पौधों के लिए सुरक्षा';
          case 'es': return 'Para Plantas';
          case 'fr': return 'Pour les Plantes';
          case 'de': return 'Für Pflanzen';
          case 'ar': return 'النباتات';
          case 'id': return 'Untuk Tanaman';
          case 'pt': return 'Para Plantas';
          case 'tr': return 'Bitkiler İçin';
          default: return 'For Plants';
        }
      case 'environmental_safety':
        switch (lang) {
          case 'hi': return 'पर्यावरण सुरक्षा';
          case 'es': return 'Seguridad Ambiental';
          case 'fr': return 'Sécurité Environnementale';
          case 'de': return 'Umweltsicherheit';
          case 'ar': return 'السلامة البيئية';
          case 'id': return 'Keamanan Lingkungan';
          case 'pt': return 'Segurança Ambiental';
          case 'tr': return 'Çevre Güvenliği';
          default: return 'Environmental Safety';
        }
      case 'yield_loss':
        switch (lang) {
          case 'hi': return 'उपज में नुकसान';
          case 'es': return 'Pérdida de Rendimiento';
          case 'fr': return 'Perte de Rendement';
          case 'de': return 'Ertragsverlust';
          case 'ar': return 'خسارة المحصول';
          case 'id': return 'Kerugian Hasil Panen';
          case 'pt': return 'Perda de Rendimento';
          case 'tr': return 'Verim Kaybı';
          default: return 'Yield Loss';
        }
      case 'growth_effect':
        switch (lang) {
          case 'hi': return 'विकास पर प्रभाव';
          case 'es': return 'Efecto en el Crecimiento';
          case 'fr': return 'Effet sur la Croissance';
          case 'de': return 'Wachstumsauswirkung';
          case 'ar': return 'التأثير على النمو';
          case 'id': return 'Efek Pertumbuhan';
          case 'pt': return 'Efeito no Crescimento';
          case 'tr': return 'Büyüme Etkisi';
          default: return 'Growth Effect';
        }
      case 'spread_to_other_plants':
        switch (lang) {
          case 'hi': return 'अन्य पौधों में फैलने का खतरा';
          case 'es': return 'Propagación a Otras Plantas';
          case 'fr': return 'Propagation à d\'autres Plantes';
          case 'de': return 'Ausbreitung auf andere Pflanzen';
          case 'ar': return 'الانتشار إلى النباتات الأخرى';
          case 'id': return 'Penyebaran ke Tanaman Lain';
          case 'pt': return 'Propagação para Outras Plantas';
          case 'tr': return 'Diğer Bitkilere Yayılma';
          default: return 'Spread To Other Plants';
        }
      case 'safe_to_harvest':
        switch (lang) {
          case 'hi': return 'कटाई के लिए सुरक्षित';
          case 'es': return 'Seguro para Cosechar';
          case 'fr': return 'Sûr pour la Récolte';
          case 'de': return 'Sicher zur Ernte';
          case 'ar': return 'آمن للحصاد';
          case 'id': return 'Aman untuk Dipanen';
          case 'pt': return 'Seguro para Colher';
          case 'tr': return 'Hasat İçin Güvenli';
          default: return 'Safe To Harvest';
        }
      case 'waiting_days':
        switch (lang) {
          case 'hi': return 'प्रतीक्षा के दिन';
          case 'es': return 'Días de Espera';
          case 'fr': return 'Jours d\'Attente';
          case 'de': return 'Wartezeit (Tage)';
          case 'ar': return 'أيام الانتظار';
          case 'id': return 'Hari Menunggu';
          case 'pt': return 'Dias de Espera';
          case 'tr': return 'Bekleme Günleri';
          default: return 'Waiting Days';
        }
      case 'cost_estimate':
        switch (lang) {
          case 'hi': return 'अनुमानित लागत';
          case 'es': return 'Estimación de Costos';
          case 'fr': return 'Estimation des Coûts';
          case 'de': return 'Kostenschätzung';
          case 'ar': return 'تقدير التكلفة';
          case 'id': return 'Estimasi Biaya';
          case 'pt': return 'Estimativa de Custos';
          case 'tr': return 'Maliyet Tahmini';
          default: return 'Cost Estimate';
        }
      case 'risk_control':
        switch (lang) {
          case 'hi': return 'जोखिम नियंत्रण';
          case 'es': return 'Control de Riesgos';
          case 'fr': return 'Contrôle des Risques';
          case 'de': return 'Risikokontrolle';
          case 'ar': return 'التحكم في المخاطر';
          case 'id': return 'Pengendalian Risiko';
          case 'pt': return 'Controle de Riscos';
          case 'tr': return 'Risk Kontrolü';
          default: return 'Risk Control';
        }
      case 'urgency':
        switch (lang) {
          case 'hi': return 'आपातकाल/तात्कालिकता';
          case 'es': return 'Urgencia';
          case 'fr': return 'Urgence';
          case 'de': return 'Dringlichkeit';
          case 'ar': return 'الإلحاح والضرورة';
          case 'id': return 'Tingkat Urgensi';
          case 'pt': return 'Urgência';
          case 'tr': return 'Aciliyet';
          default: return 'Urgency';
        }
      case 'next_step':
        switch (lang) {
          case 'hi': return 'अगला कदम';
          case 'es': return 'Siguiente Paso';
          case 'fr': return 'Prochaine Étape';
          case 'de': return 'Nächster Schritt';
          case 'ar': return 'الخطوة التالية';
          case 'id': return 'Langkah Selanjutnya';
          case 'pt': return 'Próximo Passo';
          case 'tr': return 'Sonraki Adım';
          default: return 'Next Step';
        }
      case 'business_tip':
        switch (lang) {
          case 'hi': return 'व्यापार सलाह';
          case 'es': return 'Consejo Comercial';
          case 'fr': return 'Conseil Commercial';
          case 'de': return 'Geschäftstipp';
          case 'ar': return 'نصيحة تجارية';
          case 'id': return 'Tips Bisnis';
          case 'pt': return 'Dica Comercial';
          case 'tr': return 'Ticari İpucu';
          default: return 'Business Tip';
        }
      case 'causes':
        switch (lang) {
          case 'hi': return 'कारण';
          case 'es': return 'Causas';
          case 'fr': return 'Causes';
          case 'de': return 'Ursachen';
          case 'ar': return 'الأسباب';
          case 'id': return 'Penyebab';
          case 'pt': return 'Causas';
          case 'tr': return 'Nedenler';
          default: return 'Causes';
        }
      case 'transmission':
        switch (lang) {
          case 'hi': return 'संक्रमण का तरीका';
          case 'es': return 'Transmisión';
          case 'fr': return 'Transmission';
          case 'de': return 'Übertragung';
          case 'ar': return 'طريقة الانتقال';
          case 'id': return 'Penularan';
          case 'pt': return 'Transmissão';
          case 'tr': return 'Bulaşma Yolu';
          default: return 'Transmission';
        }
      case 'immediate':
        switch (lang) {
          case 'hi': return 'तत्काल कार्रवाई';
          case 'es': return 'Acción Inmediata';
          case 'fr': return 'Action Immédiate';
          case 'de': return 'Sofortmaßnahme';
          case 'ar': return 'الإجراء الفوري';
          case 'id': return 'Tindakan Langsung';
          case 'pt': return 'Ação Imediata';
          case 'tr': return 'Acil Eylem';
          default: return 'Immediate Action';
        }
      case 'stage':
        switch (lang) {
          case 'hi': return 'रोग का चरण';
          case 'es': return 'Etapa de la Enfermedad';
          case 'fr': return 'Stade de la Maladie';
          case 'de': return 'Krankheitsstadium';
          case 'ar': return 'مرحلة المرض';
          case 'id': return 'Tahap Penyakit';
          case 'pt': return 'Estágio da Doença';
          case 'tr': return 'Hastalık Evresi';
          default: return 'Disease Stage';
        }
      case 'category':
        switch (lang) {
          case 'hi': return 'श्रेणी';
          case 'es': return 'Categoría';
          case 'fr': return 'Catégorie';
          case 'de': return 'Kategorie';
          case 'ar': return 'الفئة';
          case 'id': return 'Kategori';
          case 'pt': return 'Categoria';
          case 'tr': return 'Kategori';
          default: return 'Category';
        }
      case 'habitat':
        switch (lang) {
          case 'hi': return 'प्राकृतिक आवास';
          case 'es': return 'Hábitat Natural';
          case 'fr': return 'Habitat Naturel';
          case 'de': return 'Natürlicher Lebensraum';
          case 'ar': return 'الموئل الطبيعي';
          case 'id': return 'Habitat Alami';
          case 'pt': return 'Hábitat Natural';
          case 'tr': return 'Doğal Yaşam Alanı';
          default: return 'Habitat';
        }
      case 'host_plants':
        switch (lang) {
          case 'hi': return 'मेजबान पौधे (Host Plants)';
          case 'es': return 'Plantas Hospedantes';
          case 'fr': return 'Plantes Hôtes';
          case 'de': return 'Wirtspflanzen';
          case 'ar': return 'النباتات العائلة';
          case 'id': return 'Tanaman Inang';
          case 'pt': return 'Plantas Hospedeiras';
          case 'tr': return 'Konukçu Bitkiler';
          default: return 'Host Plants';
        }
      case 'lifespan':
        switch (lang) {
          case 'hi': return 'जीवनकाल';
          case 'es': return 'Esperanza de Vida';
          case 'fr': return 'Durée de Vie';
          case 'de': return 'Lebensdauer';
          case 'ar': return 'مدة الحياة';
          case 'id': return 'Masa Hidup';
          case 'pt': return 'Expectativa de Vida';
          case 'tr': return 'Yaşam Süresi';
          default: return 'Lifespan';
        }
      case 'active_season':
        switch (lang) {
          case 'hi': return 'सक्रिय मौसम';
          case 'es': return 'Temporada Activa';
          case 'fr': return 'Saison Active';
          case 'de': return 'Aktive Saison';
          case 'ar': return 'الموسم النشط';
          case 'id': return 'Musim Aktif';
          case 'pt': return 'Temporada Ativa';
          case 'tr': return 'Aktif Mevsim';
          default: return 'Active Season';
        }
      case 'damage_type':
        switch (lang) {
          case 'hi': return 'क्षति का प्रकार';
          case 'es': return 'Tipo de Daño';
          case 'fr': return 'Type de Dégâts';
          case 'de': return 'Schadensart';
          case 'ar': return 'نوع الضرر';
          case 'id': return 'Jenis Kerusakan';
          case 'pt': return 'Tipo de Dano';
          case 'tr': return 'Hasar Türü';
          default: return 'Damage Type';
        }
      case 'severity_level':
        switch (lang) {
          case 'hi': return 'गंभीरता का स्तर';
          case 'es': return 'Nivel de Severidad';
          case 'fr': return 'Niveau de Gravité';
          case 'de': return 'Schweregrad';
          case 'ar': return 'مستوى الشدة';
          case 'id': return 'Tingkat Keparahan';
          case 'pt': return 'Nível de Severidade';
          case 'tr': return 'Ciddiyet Seviyesi';
          default: return 'Severity Level';
        }
      case 'economic_loss':
        switch (lang) {
          case 'hi': return 'आर्थिक नुकसान';
          case 'es': return 'Pérdida Económica';
          case 'fr': return 'Perte Économique';
          case 'de': return 'Wirtschaftlicher Verlust';
          case 'ar': return 'الخسارة الاقتصادية';
          case 'id': return 'Kerugian Ekonomi';
          case 'pt': return 'Perda Econômica';
          case 'tr': return 'Ekonomik Kayıp';
          default: return 'Economic Loss';
        }
      case 'breeding_rate':
        switch (lang) {
          case 'hi': return 'प्रजनन दर';
          case 'es': return 'Tasa de Reproducción';
          case 'fr': return 'Taux de Reproduction';
          case 'de': return 'Vermehrungsrate';
          case 'ar': return 'معدل التكاثر';
          case 'id': return 'Tingkat Reproduksi';
          case 'pt': return 'Taxa de Reprodução';
          case 'tr': return 'Üreme Oranı';
          default: return 'Breeding Rate';
        }
      case 'favorable_weather':
        switch (lang) {
          case 'hi': return 'अनुकूल मौसम';
          case 'es': return 'Clima Favorable';
          case 'fr': return 'Météo Favorable';
          case 'de': return 'Günstiges Wetter';
          case 'ar': return 'الطقس المواتي';
          case 'id': return 'Cuaca Menguntungkan';
          case 'pt': return 'Clima Favorável';
          case 'tr': return 'Elverişli Hava';
          default: return 'Favorable Weather';
        }
      case 'winter_behavior':
        switch (lang) {
          case 'hi': return 'सर्दियों का व्यवहार';
          case 'es': return 'Comportamiento en Invierno';
          case 'fr': return 'Comportement Hivernal';
          case 'de': return 'Winterverhalten';
          case 'ar': return 'السلوك في الشتاء';
          case 'id': return 'Perilaku Musim Dingin';
          case 'pt': return 'Comportamento no Inverno';
          case 'tr': return 'Kış Davranışı';
          default: return 'Winter Behavior';
        }
      case 'cultural':
        switch (lang) {
          case 'hi': return 'सांस्कृतिक/पारंपरिक उपाय';
          case 'es': return 'Control Cultural';
          case 'fr': return 'Contrôle Cultural';
          case 'de': return 'Kulturelle Maßnahmen';
          case 'ar': return 'المكافحة الزراعية/الثقافية';
          case 'id': return 'Pengendalian Budidaya';
          case 'pt': return 'Controle Cultural';
          case 'tr': return 'Kültürel Yöntemler';
          default: return 'Cultural Control';
        }
      case 'mechanical':
        switch (lang) {
          case 'hi': return 'यांत्रिक/भौतिक उपाय';
          case 'es': return 'Control Mecánico';
          case 'fr': return 'Contrôle Mécanique';
          case 'de': return 'Mechanische Maßnahmen';
          case 'ar': return 'المكافحة الميكانيكية';
          case 'id': return 'Pengendalian Mekanis';
          case 'pt': return 'Controle Mecânico';
          case 'tr': return 'Mekanik Yöntemler';
          default: return 'Mechanical Control';
        }
      case 'biological':
        switch (lang) {
          case 'hi': return 'जैविक नियंत्रण';
          case 'es': return 'Control Biológico';
          case 'fr': return 'Contrôle Biologique';
          case 'de': return 'Biologische Kontrolle';
          case 'ar': return 'المكافحة البيولوجية';
          case 'id': return 'Pengendalian Biologis';
          case 'pt': return 'Controle Biológico';
          case 'tr': return 'Biyolojik Kontrol';
          default: return 'Biological Control';
        }
      case 'chemical':
        switch (lang) {
          case 'hi': return 'रासायनिक नियंत्रण';
          case 'es': return 'Control Químico';
          case 'fr': return 'Contrôle Chimique';
          case 'de': return 'Chemische Kontrolle';
          case 'ar': return 'المكافحة الكيميائية';
          case 'id': return 'Pengendalian Kimia';
          case 'pt': return 'Controle Químico';
          case 'tr': return 'Kimyasal Kontrol';
          default: return 'Chemical Control';
        }
      case 'spread_rate':
        switch (lang) {
          case 'hi': return 'फैलने की दर';
          case 'es': return 'Tasa de Propagación';
          case 'fr': return 'Vitesse de Propagation';
          case 'de': return 'Ausbreitungsrate';
          case 'ar': return 'معدل الانتشار';
          case 'id': return 'Tingkat Penyebaran';
          case 'pt': return 'Taxa de Propagação';
          case 'tr': return 'Yayılma Oranı';
          default: return 'Spread Rate';
        }
      case 'threat_level':
        switch (lang) {
          case 'hi': return 'खतरे का स्तर';
          case 'es': return 'Nivel de Amenaza';
          case 'fr': return 'Niveau de Menace';
          case 'de': return 'Bedrohungsstufe';
          case 'ar': return 'مستوى التهديد';
          case 'id': return 'Tingkat Ancaman';
          case 'pt': return 'Nível de Ameaça';
          case 'tr': return 'Tehdit Seviyesi';
          default: return 'Threat Level';
        }
      case 'plant_fatality_risk':
        switch (lang) {
          case 'hi': return 'पौधे के नष्ट होने का जोखिम';
          case 'es': return 'Riesgo de Fatalidad de la Planta';
          case 'fr': return 'Risque de Mortalité de la Plante';
          case 'de': return 'Pflanzensterberisiko';
          case 'ar': return 'خطر موت النبات';
          case 'id': return 'Risiko Kematian Tanaman';
          case 'pt': return 'Risco de Fatalidade da Planta';
          case 'tr': return 'Bitki Ölum Riski';
          default: return 'Plant Fatality Risk';
        }
      case 'immediate_steps':
        switch (lang) {
          case 'hi': return 'तत्काल कदम';
          case 'es': return 'Pasos Inmediatos';
          case 'fr': return 'Étapes Immédiates';
          case 'de': return 'Sofortige Schritte';
          case 'ar': return 'الخطوات الفورية';
          case 'id': return 'Langkah Langsung';
          case 'pt': return 'Passos Imediatos';
          case 'tr': return 'Acil Adımlar';
          default: return 'Immediate Steps';
        }
      case '7_day_plan':
      case 'seven_day_plan':
        switch (lang) {
          case 'hi': return '7 दिवसीय योजना';
          case 'es': return 'Plan de 7 Días';
          case 'fr': return 'Plan sur 7 Jours';
          case 'de': return '7-Tage-Plan';
          case 'ar': return 'خطة 7 أيام';
          case 'id': return 'Rencana 7 Hari';
          case 'pt': return 'Plano de 7 Dias';
          case 'tr': return '7 Günlük Plan';
          default: return '7-Day Plan';
        }
      case 'long_term_management':
        switch (lang) {
          case 'hi': return 'दीर्घकालिक प्रबंधन';
          case 'es': return 'Gestión a Largo Plazo';
          case 'fr': return 'Gestion à Long Terme';
          case 'de': return 'Langfristiges Management';
          case 'ar': return 'الإدارة طويلة الأجل';
          case 'id': return 'Manajemen Jangka Panjang';
          case 'pt': return 'Gestão a Longo Prazo';
          case 'tr': return 'Uzun Vadeli Yönetim';
          default: return 'Long-Term Management';
        }
      default:
        final formatted = rawKey.replaceAll('_', ' ').toLowerCase();
        return formatted[0].toUpperCase() + formatted.substring(1);
    }
  }

  String _getGardenerProTipLabel(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (lang) {
      case 'hi': return 'माली की विशेष सलाह';
      case 'es': return 'Consejo del Jardinero';
      case 'fr': return 'Conseil du Jardinier';
      case 'de': return 'Gärtner-Profi-Tipp';
      case 'ar': return 'نصيحة المزارع المحترف';
      case 'id': return 'Tips Ahli Berkebun';
      case 'pt': return 'Dica do Jardineiro';
      case 'tr': return 'Bahçıvanın İpucu';
      default: return "Gardener's Pro Tip";
    }
  }

  String _getLocalizedValue(BuildContext context, String rawValue) {
    final lang = Localizations.localeOf(context).languageCode;
    final clean = rawValue.trim().toLowerCase();

    if (clean == 'yes' || clean == 'true') {
      switch (lang) {
        case 'hi': return 'हाँ';
        case 'es': return 'Sí';
        case 'fr': return 'Oui';
        case 'de': return 'Ja';
        case 'ar': return 'نعم';
        case 'id': return 'Ya';
        case 'pt': return 'Sim';
        case 'tr': return 'Evet';
        default: return 'Yes';
      }
    }
    if (clean == 'no' || clean == 'false') {
      switch (lang) {
        case 'hi': return 'नहीं';
        case 'es': return 'No';
        case 'fr': return 'Non';
        case 'de': return 'Nein';
        case 'ar': return 'لا';
        case 'id': return 'Tidak';
        case 'pt': return 'Não';
        case 'tr': return 'Hayır';
        default: return 'No';
      }
    }

    if (clean.contains('full sun') || clean.contains('full_sun')) {
      switch (lang) {
        case 'hi': return 'पूर्ण धूप';
        case 'es': return 'Pleno Sol';
        case 'fr': return 'Plein Soleil';
        case 'de': return 'Volle Sonne';
        case 'ar': return 'شمس كاملة';
        case 'id': return 'Sinar Matahari Penuh';
        case 'pt': return 'Sol Pleno';
        case 'tr': return 'Tam Güneş';
        default: return 'Full Sun';
      }
    }
    if (clean.contains('partial shade') || clean.contains('part sun') || clean.contains('semi shade')) {
      switch (lang) {
        case 'hi': return 'आंशिक छाया';
        case 'es': return 'Sombra Parcial';
        case 'fr': return 'Ombre Partielle';
        case 'de': return 'Halbschatten';
        case 'ar': return 'ظـل جزئي';
        case 'id': return 'Teduh Parsial';
        case 'pt': return 'Meia Sombra';
        case 'tr': return 'Yarı Gölge';
        default: return 'Partial Shade';
      }
    }

    if (clean == 'fast' || clean.contains('rapid')) {
      switch (lang) {
        case 'hi': return 'तेज';
        case 'es': return 'Rápido';
        case 'fr': return 'Rapide';
        case 'de': return 'Schnell';
        case 'ar': return 'سريع';
        case 'id': return 'Cepat';
        case 'pt': return 'Rápido';
        case 'tr': return 'Hızlı';
        default: return 'Fast';
      }
    }
    if (clean == 'medium' || clean == 'moderate') {
      switch (lang) {
        case 'hi': return 'मध्यम';
        case 'es': return 'Moderado';
        case 'fr': return 'Modéré';
        case 'de': return 'Mittel';
        case 'ar': return 'متوسط';
        case 'id': return 'Sedang';
        case 'pt': return 'Moderado';
        case 'tr': return 'Orta';
        default: return 'Moderate';
      }
    }
    if (clean == 'slow') {
      switch (lang) {
        case 'hi': return 'धीमा';
        case 'es': return 'Lento';
        case 'fr': return 'Lent';
        case 'de': return 'Langsam';
        case 'ar': return 'بطيء';
        case 'id': return 'Lambat';
        case 'pt': return 'Lento';
        case 'tr': return 'Yavaş';
        default: return 'Slow';
      }
    }

    // Soil types
    if (clean.contains('loam') || clean.contains('loamy')) {
      switch (lang) {
        case 'hi': return 'दोमट मिट्टी';
        case 'es': return 'Suelo Franco';
        case 'fr': return 'Sol Limoneux';
        case 'de': return 'Lehmboden';
        case 'ar': return 'تربة طميية';
        case 'id': return 'Tanah Lempung';
        case 'pt': return 'Solo Franco';
        case 'tr': return 'Tınlı Toprak';
        default: return 'Loam Soil';
      }
    }
    if (clean.contains('sandy')) {
      switch (lang) {
        case 'hi': return 'बलुई मिट्टी';
        case 'es': return 'Suelo Arenoso';
        case 'fr': return 'Sol Sableux';
        case 'de': return 'Sandboden';
        case 'ar': return 'تربة رملية';
        case 'id': return 'Tanah Berpasir';
        case 'pt': return 'Solo Arenoso';
        case 'tr': return 'Kumlanmış Toprak';
        default: return 'Sandy Soil';
      }
    }
    if (clean.contains('clay')) {
      switch (lang) {
        case 'hi': return 'चिकनी मिट्टी';
        case 'es': return 'Suelo Arcilloso';
        case 'fr': return 'Sol Argileux';
        case 'de': return 'Tonboden';
        case 'ar': return 'تربة طينية';
        case 'id': return 'Tanah Liat';
        case 'pt': return 'Solo Argiloso';
        case 'tr': return 'Killi Toprak';
        default: return 'Clay Soil';
      }
    }

    // Toxicity
    if (clean.contains('non-toxic') || clean.contains('non toxic') || clean.contains('safe for pets')) {
      switch (lang) {
        case 'hi': return 'गैर-विषैला (सुरक्षित)';
        case 'es': return 'No Tóxico (Seguro)';
        case 'fr': return 'Non Toxique';
        case 'de': return 'Nicht giftig';
        case 'ar': return 'غير سام (آمن)';
        case 'id': return 'Tidak Beracun';
        case 'pt': return 'Não Tóxico';
        case 'tr': return 'Zehirsiz';
        default: return 'Non-Toxic';
      }
    }

    // Seasons
    if (clean == 'spring' || clean.contains('early spring')) {
      switch (lang) {
        case 'hi': return 'बसंत ऋतु';
        case 'es': return 'Primavera';
        case 'fr': return 'Printemps';
        case 'de': return 'Frühling';
        case 'ar': return 'فصل الربيع';
        case 'id': return 'Musim Semi';
        case 'pt': return 'Primavera';
        case 'tr': return 'İlkbahar';
        default: return 'Spring';
      }
    }
    if (clean == 'summer' || clean.contains('late summer')) {
      switch (lang) {
        case 'hi': return 'ग्रीष्म ऋतु';
        case 'es': return 'Verano';
        case 'fr': return 'Été';
        case 'de': return 'Sommer';
        case 'ar': return 'فصل الصيف';
        case 'id': return 'Musim Panas';
        case 'pt': return 'Verão';
        case 'tr': return 'Yaz';
        default: return 'Summer';
      }
    }
    if (clean == 'autumn' || clean == 'fall') {
      switch (lang) {
        case 'hi': return 'शरद ऋतु';
        case 'es': return 'Otoño';
        case 'fr': return 'Automne';
        case 'de': return 'Herbst';
        case 'ar': return 'فصل الخريف';
        case 'id': return 'Musim Gugur';
        case 'pt': return 'Outono';
        case 'tr': return 'Sonbahar';
        default: return 'Autumn';
      }
    }
    if (clean == 'winter') {
      switch (lang) {
        case 'hi': return 'शीत ऋतु';
        case 'es': return 'Invierno';
        case 'fr': return 'Hiver';
        case 'de': return 'Winter';
        case 'ar': return 'فصل الشتاء';
        case 'id': return 'Musim Dingin';
        case 'pt': return 'Inverno';
        case 'tr': return 'Kış';
        default: return 'Winter';
      }
    }

    // Annual / Perennial
    if (clean.contains('annual')) {
      switch (lang) {
        case 'hi': return 'वार्षिक (Annual)';
        case 'es': return 'Planta Anual';
        case 'fr': return 'Plante Annuelle';
        case 'de': return 'Einjährig';
        case 'ar': return 'نبات سنوي';
        case 'id': return 'Tanaman Semusim';
        case 'pt': return 'Planta Anual';
        case 'tr': return 'Tek Yıllık Bitki';
        default: return 'Annual';
      }
    }
    if (clean.contains('perennial')) {
      switch (lang) {
        case 'hi': return 'बहुवर्षीय (Perennial)';
        case 'es': return 'Planta Perenne';
        case 'fr': return 'Plante Vivace';
        case 'de': return 'Mehrjährig';
        case 'ar': return 'نبات معمر';
        case 'id': return 'Tanaman Menahun';
        case 'pt': return 'Planta Perene';
        case 'tr': return 'Çok Yıllık Bitki';
        default: return 'Perennial';
      }
    }

    if (clean == 'easy' || clean.contains('beginner')) {
      switch (lang) {
        case 'hi': return 'आसान (शुरुआती)';
        case 'es': return 'Fácil';
        case 'fr': return 'Facile';
        case 'de': return 'Einfach';
        case 'ar': return 'سهل';
        case 'id': return 'Mudah';
        case 'pt': return 'Fácil';
        case 'tr': return 'Kolay';
        default: return 'Easy';
      }
    }
    if (clean == 'hard' || clean == 'difficult' || clean.contains('expert')) {
      switch (lang) {
        case 'hi': return 'कठिन (विशेषज्ञ)';
        case 'es': return 'Difícil';
        case 'fr': return 'Difficile';
        case 'de': return 'Schwierig';
        case 'ar': return 'صعب';
        case 'id': return 'Sulit';
        case 'pt': return 'Difícil';
        case 'tr': return 'Zor';
        default: return 'Hard';
      }
    }
    if (clean == 'high' || clean.contains('high demand')) {
      switch (lang) {
        case 'hi': return 'उच्च';
        case 'es': return 'Alto';
        case 'fr': return 'Élevé';
        case 'de': return 'Hoch';
        case 'ar': return 'عالي';
        case 'id': return 'Tinggi';
        case 'pt': return 'Alto';
        case 'tr': return 'Yüksek';
        default: return 'High';
      }
    }
    if (clean == 'low') {
      switch (lang) {
        case 'hi': return 'कम';
        case 'es': return 'Bajo';
        case 'fr': return 'Faible';
        case 'de': return 'Niedrig';
        case 'ar': return 'منخفض';
        case 'id': return 'Rendah';
        case 'pt': return 'Baixo';
        case 'tr': return 'Düşük';
        default: return 'Low';
      }
    }

    return rawValue;
  }

  Widget _buildBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Report Reason Picker â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ReportReasonPicker extends StatefulWidget {
  final VoidCallback onSubmit;
  const _ReportReasonPicker({required this.onSubmit});
  @override
  State<_ReportReasonPicker> createState() => _ReportReasonPickerState();
}

class _ReportReasonPickerState extends State<_ReportReasonPicker> {
  int? _selected;

  List<_ReportReason> _getReasons(AppLocalizations? l10n) => [
    _ReportReason(
      icon: Icons.swap_horiz_rounded,
      color: const Color(0xFFFF6B6B),
      title: l10n?.wrongPest ?? 'Wrong Pest Identified',
      subtitle: l10n?.wrongPestSub ?? 'The AI detected the wrong species',
    ),
    _ReportReason(
      icon: Icons.analytics_outlined,
      color: const Color(0xFFFFB347),
      title: l10n?.lowConfidence ?? 'Low Confidence Result',
      subtitle: l10n?.lowConfidenceSub ?? 'The result seems uncertain or inaccurate',
    ),
    _ReportReason(
      icon: Icons.healing_outlined,
      color: const Color(0xFF64B5F6),
      title: l10n?.wrongTreatment ?? 'Wrong Treatment Info',
      subtitle: l10n?.wrongTreatmentSub ?? 'Treatment suggestions are irrelevant or incorrect',
    ),
    _ReportReason(
      icon: Icons.image_not_supported_outlined,
      color: const Color(0xFFA78BFA),
      title: l10n?.poorImage ?? 'Poor Image Analysis',
      subtitle: l10n?.poorImageSub ?? 'AI misread the image or plant details',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reasons = _getReasons(l10n);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(reasons.length, (i) {
          final r = reasons[i];
          final selected = _selected == i;
          return GestureDetector(
            onTap: () {
              AnalyticsService.instance.logEvent('result_screen_onTap_tapped');
              return setState(() => _selected = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? r.color.withOpacity(0.12)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? r.color.withOpacity(0.6)
                      : Colors.white.withOpacity(0.1),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected
                          ? r.color.withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      r.icon,
                      color: selected ? r.color : Colors.white38,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: GoogleFonts.outfit(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          r.subtitle,
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, color: r.color, size: 20)
                  else
                    Icon(
                      Icons.radio_button_off_rounded,
                      color: Colors.white24,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 4),

        // ── Submit button ──────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: _selected != null
                  ? LinearGradient(
                colors: [
                  reasons[_selected!].color,
                  reasons[_selected!].color.withOpacity(0.7),
                ],
              )
                  : const LinearGradient(
                colors: [Color(0xFF333355), Color(0xFF222244)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: _selected != null
                  ? [
                BoxShadow(
                  color: reasons[_selected!].color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [],
            ),
            child: ElevatedButton.icon(
              onPressed: _selected != null ? widget.onSubmit : null,
              icon: const Icon(
                Icons.send_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                l10n?.submitReport ?? 'Submit Report',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportReason {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _ReportReason({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

// ─── Custom shrinking image header delegate ───────────────────────────────────
class _ResultImageDelegate extends SliverPersistentHeaderDelegate {
  final double expandedHeight;
  final double collapsedHeight;
  final ImageProvider? heroImage;
  final VoidCallback onBack;
  final VoidCallback onReport;

  const _ResultImageDelegate({
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.heroImage,
    required this.onBack,
    required this.onReport,
  });

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => collapsedHeight;

  @override
  bool shouldRebuild(covariant _ResultImageDelegate old) =>
      old.heroImage != heroImage ||
          old.expandedHeight != expandedHeight ||
          old.collapsedHeight != collapsedHeight ||
          old.onReport != onReport;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    // 0.0 = fully expanded, 1.0 = fully collapsed
    final progress = (shrinkOffset / (expandedHeight - collapsedHeight)).clamp(
      0.0,
      1.0,
    );
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image (always covers full area) ──────────────
          if (heroImage != null)
            Image(
              image: heroImage!,
              fit: BoxFit.cover,
              alignment: Alignment(0, -progress * 0.3), // subtle parallax
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.white24,
                ),
              ),
            )
          else
            Container(
              color: AppTheme.primaryColor.withOpacity(0.4),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 60,
                  color: Colors.white38,
                ),
              ),
            ),

          // ── Gradient overlay (gets darker as collapsed) ──
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.35 + progress * 0.25),
                  Colors.transparent,
                  Colors.black.withOpacity(0.2 + progress * 0.3),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // ── Back button ──────────────────────────────────
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

          // ── Report AI button (always visible top-right) ───
          Positioned(
            top: topPadding + 8,
            right: 12,
            child: GestureDetector(
              onTap: onReport,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child:  Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text(
                      AppLocalizations.of(context)?.reportAI ?? 'Report AI',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
