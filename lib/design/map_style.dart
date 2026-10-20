// Shared by the main map and place previews.
const String tripNestMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#f2f3f4"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#727579"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
    {"featureType":"poi","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#deeee3"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e6e7e8"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#d2e3ed"}]}
  ]
  ''';
