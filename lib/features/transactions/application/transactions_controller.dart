import 'package:flutter/foundation.dart';

import '../data/transactions_repository.dart';
import '../domain/transaction_models.dart';

enum TransactionsStatus { idle, loading, loaded, error }

class TransactionsController extends ChangeNotifier {
  TransactionsController(this.repository, {this.onChanged});
  final TransactionsRepository repository;
  final Future<void> Function()? onChanged;
  TransactionsStatus status = TransactionsStatus.idle;
  List<LedgerTransaction> rows = [];
  TransactionLookups? lookups;
  TransactionFilters filters = const TransactionFilters();
  int _page = 1;
  bool hasMore = false;
  bool loadingMore = false;

  Future<void> load({TransactionFilters? withFilters}) async {
    status = TransactionsStatus.loading;
    notifyListeners();
    try {
      filters = withFilters ?? filters;
      lookups ??= await repository.lookups();
      _page = 1;
      final result = await repository.page(filters, _page);
      rows = result.rows;
      hasMore = result.hasMore;
      status = TransactionsStatus.loaded;
    } catch (_) {
      status = TransactionsStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!hasMore || loadingMore) return;
    loadingMore = true;
    notifyListeners();
    try {
      final result = await repository.page(filters, ++_page);
      rows.addAll(result.rows);
      hasMore = result.hasMore;
    } catch (_) {
      _page--;
    }
    loadingMore = false;
    notifyListeners();
  }

  Future<void> update(
    LedgerTransaction row, {
    required double amount,
    required DateTime date,
    required String description,
    required String reference,
  }) async {
    await repository.update(
      row,
      amount: amount,
      date: date,
      description: description,
      reference: reference,
    );
    await load();
    await onChanged?.call();
  }

  Future<void> delete(String id) async {
    await repository.delete(id);
    await load();
    await onChanged?.call();
  }
}
