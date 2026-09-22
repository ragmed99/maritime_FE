import '../../../core/network/api_client.dart';

class TrashRecord {
  const TrashRecord({
    required this.batch,
    required this.kind,
    required this.label,
    required this.deletedAt,
  });

  factory TrashRecord.fromJson(Map<String, dynamic> json) => TrashRecord(
    batch: json['batch'] as String,
    kind: json['kind'] as String,
    label: json['label'] as String,
    deletedAt: DateTime.parse(json['deleted_at'] as String),
  );

  final String batch;
  final String kind;
  final String label;
  final DateTime deletedAt;
}

class TrashRepository {
  const TrashRepository(this._api);
  final ApiClient _api;

  Future<List<TrashRecord>> records() async => (await _api.get<List<dynamic>>(
    'trash/',
  )).data!.cast<Map<String, dynamic>>().map(TrashRecord.fromJson).toList();

  Future<void> restore(String batch) =>
      _api.post<void>('trash/$batch/restore/').then((_) {});

  Future<void> purge(String batch) =>
      _api.post<void>('trash/$batch/purge/').then((_) {});
}
