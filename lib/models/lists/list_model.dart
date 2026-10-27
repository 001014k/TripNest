class ListModel {
  final String id;
  final String name;
  final bool isOwner;
  final String? coverTitle;
  final List<String> keywords;
  final DateTime createdAt;
  final int markerCount;
  int collaboratorCount;

  ListModel({
    required this.id,
    required this.name,
    this.isOwner = false,
    this.coverTitle,
    this.keywords = const [],
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
      isOwner: isOwner,
      coverTitle: coverTitle,
      keywords: keywords,
      createdAt: createdAt ?? this.createdAt,
      markerCount: markerCount ?? this.markerCount,
      collaboratorCount: collaboratorCount ?? this.collaboratorCount,
    );
  }
}
