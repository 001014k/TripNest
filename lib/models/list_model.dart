class ListModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final int markerCount;

  ListModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.markerCount,
  });

  ListModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? markerCount,
  }) {
    return ListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      markerCount: markerCount ?? this.markerCount,
    );
  }
}
