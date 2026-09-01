import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_helper.dart';
import '../data/models/pest_results.dart';

final databaseHelperProvider = Provider((ref) => DatabaseHelper());

class HistoryNotifier extends StateNotifier<List<PestResult>> {
  final DatabaseHelper _databaseHelper;
  bool? _isHistoryFilter;
  bool? _isFavoriteFilter;

  HistoryNotifier(this._databaseHelper) : super([]) {
    // Default to loading everything or you can pick a default
    loadHistory();
  }

  Future<void> loadHistory({bool? isHistory, bool? isFavorite}) async {
    _isHistoryFilter = isHistory;
    _isFavoriteFilter = isFavorite;
    final list = await _databaseHelper.getScans(
      isHistory: isHistory,
      isFavorite: isFavorite,
    );
    state = list;
  }

  Future<void> deleteScan(int id) async {
    await _databaseHelper.deleteScan(id);
    await loadHistory(
      isHistory: _isHistoryFilter,
      isFavorite: _isFavoriteFilter,
    );
  }

  Future<int> saveScan(PestResult scan) async {
    final id = await _databaseHelper.insertScan(scan);
    await loadHistory(
      isHistory: _isHistoryFilter,
      isFavorite: _isFavoriteFilter,
    );
    return id;
  }

  Future<void> updateScan(PestResult scan) async {
    await _databaseHelper.updateScan(scan);
    await loadHistory(
      isHistory: _isHistoryFilter,
      isFavorite: _isFavoriteFilter,
    );
  }
}

final historyProvider =
StateNotifierProvider<HistoryNotifier, List<PestResult>>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return HistoryNotifier(dbHelper);
});
