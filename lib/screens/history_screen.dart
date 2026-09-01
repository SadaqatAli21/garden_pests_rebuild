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

class HistoryScreen extends ConsumerStatefulWidget {
  final bool showAppBar;

  const HistoryScreen({super.key, this.showAppBar = false});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final Set<int> _selectedIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    // Load data based on mode - exclusively HISTORY
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).loadHistory(isHistory: true);
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
    final history = ref.watch(historyProvider);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(),
        body: history.isEmpty
            ? _buildEmptyState()
            : LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return _buildGridView(ref, history, constraints);
            } else {
              return _buildListView(ref, history);
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          "${_selectedIds.length} ${AppLocalizations.of(context)!.selected}",
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
          AppLocalizations.of(context)!.historyTitle,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        centerTitle: true,
        elevation: 0,
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
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 80,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noHistory,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.historyEmpty,
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

  Widget _buildListView(WidgetRef ref, List<PestResult> history) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final scan = history[index];
        final isSelected = _selectedIds.contains(scan.id);

        return GestureDetector(
          onLongPress: () => _enterSelectionMode(scan.id!),
          onTap: () {
            AnalyticsService.instance.logEvent('history_screen_onTap_tapped');

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
                    // Hero Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: Hero(
                          tag: 'pest_image_${scan.id}',
                          child: _buildImage(scan.imagePath),
                        ),
                      ),
                    ),
                    // Selection Overlay
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
                    // Severity Badge on top right
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildSeverityBadge(scan.severityLevel),
                    ),
                    // Date Badge on top left
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              scan.dateScanned != null
                                  ? scan.dateScanned.toString().substring(0, 10)
                                  : AppLocalizations.of(context)!.unknown,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                        ElevatedButton(
                          onPressed: () {
                            AnalyticsService.instance.logEvent(
                              'history_screen_onPressed_tapped',
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ResultScreen(result: scan),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor.withOpacity(
                              0.1,
                            ),
                            foregroundColor: AppTheme.primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.viewDetails,
                          ),
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
      List<PestResult> history,
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
      itemCount: history.length,
      itemBuilder: (context, index) {
        final scan = history[index];
        final isSelected = _selectedIds.contains(scan.id);

        return GestureDetector(
          onLongPress: () => _enterSelectionMode(scan.id!),
          onTap: () {
            AnalyticsService.instance.logEvent('history_screen_onTap_tapped');

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
                          ), // Match outer radius minus border
                          child: Hero(
                            tag: 'pest_image_grid_${scan.id}',
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
                          scan.dateScanned != null
                              ? scan.dateScanned.toString().substring(0, 10)
                              : AppLocalizations.of(context)!.unknown,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
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

  // Helper methods
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

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey[400],
              size: 40,
            ),
          );
        },
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
        color = const Color(0xFFD32F2F); // Darker Red
        bgColor = const Color(0xFFFFEBEE); // Light Red
        break;
      case 'medium':
        color = const Color(0xFFF57C00); // Darker Orange
        bgColor = const Color(0xFFFFF3E0); // Light Orange
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
          letterSpacing: 0.5,
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
