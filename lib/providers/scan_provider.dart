import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_logger.dart';
import '../core/app_constrants.dart';
import '../data/models/pest_results.dart';
import '../data/openaservice.dart';

// State for the scan process
class ScanState {
  final bool isLoading;
  final PestResult? result;
  final String? error;
  final int dailyCount;
  final int totalCount;

  ScanState({
    this.isLoading = false,
    this.result,
    this.error,
    this.dailyCount = 0,
    this.totalCount = 0,
  });

  ScanState copyWith({
    bool? isLoading,
    PestResult? result,
    String? error,
    int? dailyCount,
    int? totalCount,
  }) {
    return ScanState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: error ?? this.error,
      dailyCount: dailyCount ?? this.dailyCount,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// Provider for OpenAIService
final openAIServiceProvider = Provider((ref) => OpenAIService());

// Global provider for ScanNotifier
final scanProvider = StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  final openAIService = ref.watch(openAIServiceProvider);
  return ScanNotifier(openAIService);
});

class ScanNotifier extends StateNotifier<ScanState> {
  final OpenAIService _openAIService;

  ScanNotifier(this._openAIService) : super(ScanState()) {
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final lastScanDate = prefs.getString(AppConstants.lastScanDateKey);
      int count = prefs.getInt(AppConstants.dailyScanCountKey) ?? 0;
      int total = prefs.getInt(AppConstants.totalScanCountKey) ?? 0;

      if (lastScanDate != todayStr) {
        count = 0;
        await prefs.setString(AppConstants.lastScanDateKey, todayStr);
        await prefs.setInt(AppConstants.dailyScanCountKey, 0);
      }
      state = state.copyWith(dailyCount: count, totalCount: total);
    } catch (e) {
      // safe fail
    }
  }

  Future<void> analyzeImage(String base64Image, String languageName, {String analysisType = 'pest'}) async {
    // Keep dailyCount when starting load
    state = state.copyWith(isLoading: true, error: null, result: null);

    // Check Daily Limit
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final lastScanDate = prefs.getString(AppConstants.lastScanDateKey);
    int dailyCount = prefs.getInt(AppConstants.dailyScanCountKey) ?? 0;

    if (lastScanDate != todayStr) {
      dailyCount = 0;
      await prefs.setString(AppConstants.lastScanDateKey, todayStr);
      await prefs.setInt(AppConstants.dailyScanCountKey, 0);
    }

    // Sync state count
    state = state.copyWith(dailyCount: dailyCount);

    int attempts = 0;
    const int maxAttempts = 2; // Initial attempt + 1 retry

    while (attempts < maxAttempts) {
      try {
        attempts++;
        if (attempts > 1) {
          AppLogger.info(
            "Retrying image analysis (Attempt $attempts/$maxAttempts, type: $analysisType)...",
            "ScanNotifier",
          );
        } else {
          AppLogger.info("Starting image analysis ($analysisType)...", "ScanNotifier");
        }

        // Pass language name AND analysis type
        final result = await _openAIService.analyzeImage(
          base64Image,
          languageName,
          analysisType: analysisType,
        );

        // Increment count on success
        dailyCount++;
        int totalCount =
            (prefs.getInt(AppConstants.totalScanCountKey) ?? 0) + 1;
        await prefs.setInt(AppConstants.dailyScanCountKey, dailyCount);
        await prefs.setInt(AppConstants.totalScanCountKey, totalCount);

        state = state.copyWith(
          isLoading: false,
          result: result,
          dailyCount: dailyCount,
          totalCount: totalCount,
        );
        return; // Success, exit method
      } catch (e, stackTrace) {
        if (attempts >= maxAttempts) {
          AppLogger.error(
            "ScanNotifier Error after $maxAttempts attempts",
            e,
            stackTrace,
            "ScanNotifier",
          );
          state = state.copyWith(isLoading: false, error: e.toString());
          break; // Max attempts reached
        }
        // Wait a bit before retrying
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }

  void reset() {
    // preserve counts
    state = ScanState(
      dailyCount: state.dailyCount,
      totalCount: state.totalCount,
    );
  }
}
