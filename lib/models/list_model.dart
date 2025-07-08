class ListModel {
  final String id;
  final String name;
  final DateTime createdAt;
  final int markerCount;
  int collaboratorCount;

  ListModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.markerCount,
    this.collaboratorCount = 0,
  });

  ListModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    int? markerCount,
    int? collaboratorCount,
  }) {
    return ListModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      markerCount: markerCount ?? this.markerCount,
      collaboratorCount: this.collaboratorCount,
    );
  }
}
