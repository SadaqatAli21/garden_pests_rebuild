import 'dart:io';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/app_theme.dart';
import '../core/services/analytics_services.dart';
import '../data/models/pest_results.dart';
import '../providers/history_provider.dart';
import 'result_screen.dart';
import '../widgets/app_dialogs.dart';
import '../../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class SavedScansScreen extends ConsumerStatefulWidget {
  final bool showAppBar;
  const SavedScansScreen({super.key, this.showAppBar = false});

  @override
  ConsumerState<SavedScansScreen> createState() => _SavedScansScreenState();
}

class _SavedScansScreenState extends ConsumerState<SavedScansScreen> {
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load ALL history, not just favorites
      ref.read(historyProvider.notifier).loadHistory();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }

      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(int id) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _deleteSelected() {
    AppDialogs.showConfirmDialog(
      context,
      title: AppLocalizations.of(context)!.removeSelectedTitle,
      message: AppLocalizations.of(
        context,
      )!.removeSelectedMessage(_selectedIds.length),
      confirmText: AppLocalizations.of(context)!.remove,
      isDestructive: true,
      onConfirm: () {
        for (var id in _selectedIds) {
          ref.read(historyProvider.notifier).deleteScan(id);
        }
        _exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.itemsRemoved,
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final savedScans = ref.watch(historyProvider);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: _buildAppBar(),
          body: savedScans.isEmpty
              ? _buildEmptyState()
              : TabBarView(
            children: [
              _buildFilteredContent(ref, savedScans, 'pest'),
              _buildFilteredContent(ref, savedScans, 'identify'),
              _buildFilteredContent(ref, savedScans, 'diagnose'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilteredContent(WidgetRef ref, List<PestResult> scans, String type) {
    final filtered = scans.where((s) => s.scanType == type).toList();

    if (filtered.isEmpty) {
      return _buildEmptyCategoryState(type);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return _buildGridView(ref, filtered, constraints);
        } else {
          return _buildListView(ref, filtered);
        }
      },
    );
  }

  Widget _buildEmptyCategoryState(String type) {
    final l10n = AppLocalizations.of(context);
    String message = l10n?.noSavedScans ?? "No scans yet";
    IconData icon = Icons.search_off_rounded;

    if (type == 'pest') message = l10n?.noPestsFound ?? "No Pest Scans found";
    if (type == 'identify') message = "${l10n?.identify ?? 'Plant Identification'} - ${l10n?.noSavedScans ?? 'None'}";
    if (type == 'diagnose') message = "${l10n?.diagnose ?? 'Health Diagnosis'} - ${l10n?.noSavedScans ?? 'None'}";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    final l10n = AppLocalizations.of(context);

    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          "${_selectedIds.length} ${l10n?.selected ?? 'Selected'}",
          style: GoogleFonts.outfit(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteSelected,
          ),
        ],
      );
    }

    if (widget.showAppBar) {
      return AppBar(
        title: Text(
          l10n?.savedScansTitle ?? 'Saved Scans',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.normal),
          tabs: [
            Tab(text: l10n?.aiScanner ?? "Pests", icon: const Icon(Icons.bug_report_outlined)),
            Tab(text: l10n?.identify ?? "Identify", icon: const Icon(Icons.search_rounded)),
            Tab(text: l10n?.diagnose ?? "Diagnose", icon: const Icon(Icons.health_and_safety_outlined)),
          ],
        ),
      );
    }

    return null;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bookmark_outline_rounded,
              size: 80,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noSavedScans,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.savedScansEmpty,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(WidgetRef ref, List<PestResult> scans) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: scans.length,
      itemBuilder: (context, index) {
        final scan = scans[index];
        final isSelected = _selectedIds.contains(scan.id);

        return GestureDetector(
          onLongPress: () => _enterSelectionMode(scan.id!),
          onTap: () {
            AnalyticsService.instance.logEvent(
              'saved_scans_screen_onTap_tapped',
            );

            if (_isSelectionMode) {
              _toggleSelection(scan.id!);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(result: scan),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Hero(
                          tag: 'saved_image_${scan.id}',
                          child: _buildImage(scan.imagePath),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22),
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildSeverityBadge(scan.severityLevel),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scan.getLocalizedDisplayName(context),
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              scan.getLocalizedSubtitle(context),
                              style: GoogleFonts.outfit(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_isSelectionMode)
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 20,
                          ),
                          onPressed: () {
                            AnalyticsService.instance.logEvent(
                              'saved_scans_screen_onPressed_tapped',
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ResultScreen(result: scan),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(
      WidgetRef ref,
      List<PestResult> scans,
      BoxConstraints constraints,
      ) {
    int crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
      ),
      itemCount: scans.length,
      itemBuilder: (context, index) {
        final scan = scans[index];
        final isSelected = _selectedIds.contains(scan.id);

        return GestureDetector(
          onLongPress: () => _enterSelectionMode(scan.id!),
          onTap: () {
            AnalyticsService.instance.logEvent(
              'saved_scans_screen_onTap_tapped',
            );

            if (_isSelectionMode) {
              _toggleSelection(scan.id!);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ResultScreen(result: scan),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor.withOpacity(0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22),
                          ),
                          child: Hero(
                            tag: 'saved_image_grid_${scan.id}',
                            child: _buildImage(scan.imagePath),
                          ),
                        ),
                      ),
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(22),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildSeverityBadge(
                          scan.severityLevel,
                          isSmall: true,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          scan.getLocalizedDisplayName(context),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scan.getLocalizedSubtitle(context),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildImage(String? path) {
    if (path == null) {
      return Container(
        color: Colors.grey[100],
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
          size: 40,
        ),
      );
    }

    if (File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.cover);
    } else {
      return Container(
        color: Colors.grey[100],
        child: Icon(
          Icons.image_not_supported_outlined,
          color: Colors.grey[400],
          size: 40,
        ),
      );
    }
  }

  Widget _buildSeverityBadge(String severity, {bool isSmall = false}) {
    Color color;
    Color bgColor;
    switch (severity.toLowerCase()) {
      case 'high':
        color = const Color(0xFFD32F2F);
        bgColor = const Color(0xFFFFEBEE);
        break;
      case 'medium':
        color = const Color(0xFFF57C00);
        bgColor = const Color(0xFFFFF3E0);
        break;
      default:
        color = AppTheme.primaryColor;
        bgColor = AppTheme.primaryColor.withOpacity(0.1);
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Text(
        _getLocalizedSeverity(context, severity).toUpperCase(),
        style: GoogleFonts.outfit(
          color: color,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.bold,
        ),
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
}
