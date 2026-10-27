class LinkPlacePreview {
  const LinkPlacePreview({
    required this.url,
    required this.title,
    required this.address,
    this.latitude,
    this.longitude,
  });

  final String url;
  final String title;
  final String address;
  final double? latitude;
  final double? longitude;

  LinkPlacePreview copyWith({
    String? title,
    String? address,
    bool clearLocation = false,
  }) {
    return LinkPlacePreview(
      url: url,
      title: title ?? this.title,
      address: address ?? this.address,
      latitude: clearLocation ? null : latitude,
      longitude: clearLocation ? null : longitude,
    );
  }
}
