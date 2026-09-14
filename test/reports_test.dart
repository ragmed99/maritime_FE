import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/features/reports/domain/report_models.dart';

void main() {
  test('ship report request supports multiple selected trips', () {
    final request = StatementRequest(
      kind: ReportKind.ship,
      entityId: 'ship-1',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 1, 31),
      tripIds: const ['trip-1', 'trip-2'],
    );

    expect(request.resource, 'ships');
    expect(request.query['trips'], 'trip-1,trip-2');
    expect(request.query['start_date'], '2026-01-01');
    expect(request.query['end_date'], '2026-01-31');
  });

  test('statement preview parses backend totals, rows, and trip results', () {
    final report = StatementData.fromJson({
      'subject': {'id': 'ship-1', 'name': 'Al Bahri'},
      'summary': {
        'total_revenue': '500.00',
        'total_expenses': '110.00',
        'remaining_result': '390.00',
      },
      'transactions': {
        'results': [
          {
            'date': '2026-01-02',
            'time': '09:30:00',
            'transaction_type': 'SHIP_REVENUE',
            'amount': '500.00',
            'description': 'Sale',
            'ship': {'id': 'ship-1', 'name': 'Al Bahri'},
            'trip': null,
            'client': null,
            'created_by': {'id': 1, 'username': 'reporter'},
          },
        ],
      },
      'trip_summaries': [
        {
          'trip_id': 'trip-1',
          'departure_date': '2026-01-01',
          'return_date': null,
          'revenue': '500.00',
          'expenses': '110.00',
          'client_purchases': '75.00',
          'remaining_result': '390.00',
        },
      ],
    });

    expect(report.subjectName, 'Al Bahri');
    expect(report.summary['remaining_result'], 390);
    expect(report.transactions.single.createdBy, 'reporter');
    expect(report.tripSummaries.single.purchases, 75);
  });
}
