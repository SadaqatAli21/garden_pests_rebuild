import 'package:flutter/material.dart';
import 'package:garden_pests_rebuild/screens/pest_details_screen.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../core/services/analytics_services.dart';

class GuideScreen extends StatefulWidget {
  final bool showAppBar;
  const GuideScreen({super.key, this.showAppBar = false});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSeverity = 'All';

  List<Map<String, dynamic>> _getAllPests(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        'name': l10n.pestAphidName,
        'severity': 'Medium',
        'description': l10n.pestAphidDesc,
        'icon': Icons.bug_report,
        'color': Colors.orange,
        'imageAsset': 'assets/images/pests/aphids.jpg',
        'symptoms': l10n.pestAphidSymptoms,
        'treatment': l10n.pestAphidTreatment,
        'prevention': l10n.pestAphidPrevention,
      },
      {
        'name': l10n.pestSpiderMiteName,
        'severity': 'High',
        'description': l10n.pestSpiderMiteDesc,
        'icon': Icons.coronavirus,
        'color': Colors.red,
        'imageAsset': 'assets/images/pests/spider mite.webp',
        'symptoms': l10n.pestSpiderMiteSymptoms,
        'treatment': l10n.pestSpiderMiteTreatment,
        'prevention': l10n.pestSpiderMitePrevention,
      },
      {
        'name': l10n.pestWhiteflyName,
        'severity': 'Medium',
        'description': l10n.pestWhiteflyDesc,
        'icon': Icons.flutter_dash,
        'color': Colors.orange,
        'imageAsset': 'assets/images/pests/whitefly.jpg',
        'symptoms': l10n.pestWhiteflySymptoms,
        'treatment': l10n.pestWhiteflyTreatment,
        'prevention': l10n.pestWhiteflyPrevention,
      },
      {
        'name': l10n.pestCaterpillarName,
        'severity': 'Low',
        'description': l10n.pestCaterpillarDesc,
        'icon': Icons.pest_control,
        'color': Colors.green,
        'imageAsset': 'assets/images/pests/caterpiller.jpg',
        'symptoms': l10n.pestCaterpillarSymptoms,
        'treatment': l10n.pestCaterpillarTreatment,
        'prevention': l10n.pestCaterpillarPrevention,
      },
      {
        'name': l10n.pestThripsName,
        'severity': 'Medium',
        'description': l10n.pestThripsDesc,
        'icon': Icons.grass,
        'color': Colors.orange,
        'imageAsset': 'assets/images/pests/thrips.webp',
        'symptoms': l10n.pestThripsSymptoms,
        'treatment': l10n.pestThripsTreatment,
        'prevention': l10n.pestThripsPrevention,
      },
      {
        'name': l10n.pestMealybugName,
        'severity': 'High',
        'description': l10n.pestMealybugDesc,
        'icon': Icons.adb,
        'color': Colors.red,
        'imageAsset': 'assets/images/pests/mealybug.webp',
        'symptoms': l10n.pestMealybugSymptoms,
        'treatment': l10n.pestMealybugTreatment,
        'prevention': l10n.pestMealybugPrevention,
      },
      {
        'name': l10n.pestLeafBeetleName,
        'severity': 'Medium',
        'description': l10n.pestLeafBeetleDesc,
        'icon': Icons.bug_report_outlined,
        'color': Colors.orange,
        'imageAsset': 'assets/images/pests/leaf beetle.jpg',
        'symptoms': l10n.pestLeafBeetleSymptoms,
        'treatment': l10n.pestLeafBeetleTreatment,
        'prevention': l10n.pestLeafBeetlePrevention,
      },
      {
        'name': l10n.pestSlugName,
        'severity': 'Low',
        'description': l10n.pestSlugDesc,
        'icon': Icons.spa,
        'color': Colors.green,
        'imageAsset': 'assets/images/pests/slug.jpg',
        'symptoms': l10n.pestSlugSymptoms,
        'treatment': l10n.pestSlugTreatment,
        'prevention': l10n.pestSlugPrevention,
      },
      {
        'name': l10n.pestSnailName,
        'severity': 'Low',
        'description': l10n.pestSnailDesc,
        'icon': Icons.spa_outlined,
        'color': Colors.green,
        'imageAsset': 'assets/images/pests/snail.jpg',
        'symptoms': l10n.pestSnailSymptoms,
        'treatment': l10n.pestSnailTreatment,
        'prevention': l10n.pestSnailPrevention,
      },
      {
        'name': l10n.pestGrasshopperName,
        'severity': 'Medium',
        'description': l10n.pestGrasshopperDesc,
        'icon': Icons.bug_report_rounded,
        'color': Colors.orange,
        'imageAsset': 'assets/images/pests/grasshopper.webp',
        'symptoms': l10n.pestGrasshopperSymptoms,
        'treatment': l10n.pestGrasshopperTreatment,
        'prevention': l10n.pestGrasshopperPrevention,
      },
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredPests {
    final allPests = _getAllPests(context);
    return allPests.where((pest) {
      final matchesSearch =
          pest['name'].toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
              pest['description'].toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
      final matchesSeverity =
          _selectedSeverity == 'All' || pest['severity'] == _selectedSeverity;
      return matchesSearch && matchesSeverity;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: widget.showAppBar
          ? AppBar(
        title: Text(
          AppLocalizations.of(context)!.treatmentGuide.replaceAll('\n', ' '),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
      )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _filteredPests.isEmpty
                  ? _buildEmptyState()
                  : LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive grid decision
                  final isWide = constraints.maxWidth > 700;
                  final isTablet = constraints.maxWidth > 450;
                  final crossAxisCount = isWide ? 3 : (isTablet ? 2 : 1);

                  // Adjust aspect ratios to prevent overflow
                  // Lower ratio = Taller card
                  final double aspectRatio = isWide
                      ? 1.2
                      : (crossAxisCount == 1
                      ? 1.4 // Made cards taller for mobile text
                      : 0.75); // Made cards even taller for mobile

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: aspectRatio,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _filteredPests.length,
                    itemBuilder: (context, index) {
                      return _buildPestCard(_filteredPests[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: widget.showAppBar ? AppTheme.background : AppTheme.primaryColor,
        borderRadius: widget.showAppBar
            ? null
            : const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: widget.showAppBar
            ? null
            : [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.showAppBar) ...[
            Text(
              AppLocalizations.of(context)!.pestGuide,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.pestGuideSubtitle,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchPests,
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primaryColor,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('High'),
                const SizedBox(width: 8),
                _buildFilterChip('Medium'),
                const SizedBox(width: 8),
                _buildFilterChip('Low'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String severityKey) {
    // severityKey: 'All', 'High', 'Medium', 'Low' (matches what's in _getAllPests)
    final isSelected = _selectedSeverity == severityKey;

    Color selectedColor;
    switch (severityKey) {
      case 'High':
        selectedColor = AppTheme.highSeverity;
        break;
      case 'Medium':
        selectedColor = AppTheme.mediumSeverity;
        break;
      case 'Low':
        selectedColor = AppTheme.lowSeverity;
        break;
      default:
        selectedColor = AppTheme.primaryColor;
    }

    return FilterChip(
      label: Text(_getLocalizedSeverity(context, severityKey)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedSeverity = severityKey;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: selectedColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      elevation: isSelected ? 2 : 0,
    );
  }

  Widget _buildPestCard(Map<String, dynamic> pest) {
    Color severityColor;
    switch (pest['severity']) {
      case 'High':
        severityColor = AppTheme.highSeverity;
        break;
      case 'Medium':
        severityColor = AppTheme.mediumSeverity;
        break;
      default:
        severityColor = AppTheme.primaryColor;
    }

    final hasImage = pest['imageAsset'] != null;

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AnalyticsService.instance.logEvent('guide_screen_onTap_tapped');

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PestDetailScreen(pest: pest),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: hasImage
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Section
              Expanded(
                flex: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.asset(
                        pest['imageAsset'],
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Severity Badge Overlay
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getLocalizedSeverity(
                            context,
                            pest['severity'],
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content Section
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pest['name'],
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          pest['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.readGuide,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (pest['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        pest['icon'],
                        color: pest['color'],
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: severityColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getLocalizedSeverity(context, pest['severity']),
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  pest['name'],
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  pest['description'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.readGuide,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noPestsFound,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.adjustSearch,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  String _getLocalizedSeverity(BuildContext context, String label) {
    if (label == 'High') return AppLocalizations.of(context)!.high;
    if (label == 'Medium') return AppLocalizations.of(context)!.medium;
    if (label == 'Low') return AppLocalizations.of(context)!.low;
    if (label == 'All') return AppLocalizations.of(context)!.all;
    return label;
  }
}
