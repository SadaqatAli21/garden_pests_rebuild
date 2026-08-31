import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScanState {
  final bool isLoading;
  final dynamic result;
  final String? error;
  final int dailyCount;
  final int totalCount;

  const ScanState({
    this.isLoading = false,
    this.result,
    this.error,
    this.dailyCount = 0,
    this.totalCount = 0,
  });

  ScanState copyWith({
    bool? isLoading,
    dynamic result,
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

final scanProvider =
StateNotifierProvider<ScanNotifier, ScanState>((ref) {
  return ScanNotifier();
});

class ScanNotifier extends StateNotifier<ScanState> {
  ScanNotifier() : super(const ScanState());

  Future<void> analyzeImage(
      String base64Image,
      String languageName, {
        String analysisType = 'pest',
      }) async {
    // Temporary only
    state = state.copyWith(isLoading: true);

    await Future.delayed(
      const Duration(seconds: 1),
    );

    state = state.copyWith(
      isLoading: false,
      dailyCount: state.dailyCount + 1,
      totalCount: state.totalCount + 1,
    );
  }

  void reset() {
    state = ScanState(
      dailyCount: state.dailyCount,
      totalCount: state.totalCount,
    );
  }
}