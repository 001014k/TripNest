class InstagramPlaceSource {
  final String name;
  final String? address;

  const InstagramPlaceSource({
    required this.name,
    this.address,
  });

  @override
  String toString() {
    return 'InstagramPlaceSource(name: $name, address: $address)';
  }
}