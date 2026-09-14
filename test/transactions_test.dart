import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/features/transactions/domain/transaction_models.dart';

void main() {
  test('global transaction parses relations and audit creator', () {
    final row = LedgerTransaction.fromJson({
      'id': 'transaction-1',
      'transaction_type': 'CLIENT_PURCHASE',
      'amount': '475.25',
      'transaction_date': '2026-09-13',
      'created_at': '2026-09-13T12:30:00Z',
      'description': 'Poisson',
      'reference': 'REF-42',
      'ship': 'ship-1',
      'trip': 'trip-1',
      'client': 'client-1',
      'partner': null,
      'owner': null,
      'created_by': {'id': 3, 'username': 'operator'},
    });

    expect(row.amount, 475.25);
    expect(row.shipId, 'ship-1');
    expect(row.tripId, 'trip-1');
    expect(row.clientId, 'client-1');
    expect(row.recordedBy, 'operator');
  });

  test('filters generate backend pagination and relationship parameters', () {
    final query = TransactionFilters(
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 30),
      type: 'SHIP_EXPENSE',
      shipId: 'ship-1',
      search: 'fuel',
    ).toQuery(3);

    expect(query['page'], 3);
    expect(query['start_date'], '2026-09-01');
    expect(query['end_date'], '2026-09-30');
    expect(query['transaction_type'], 'SHIP_EXPENSE');
    expect(query['ship'], 'ship-1');
    expect(query['search'], 'fuel');
    expect(query.containsKey('client'), isFalse);
  });
}
