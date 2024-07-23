import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  GoogleMapController? _controller;
  Marker? _selectedMarker;
  LatLng? _pendingLatLng;
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  List<Marker> _searchResults = [];
  CollectionReference markersCollection = FirebaseFirestore.instance.collection('markers');

  static const LatLng _seoulCityHall = LatLng(37.5665, 126.9780);

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  Future<void> _loadMarkers() async {
    final QuerySnapshot querySnapshot = await markersCollection.get();
    setState(() {
      _markers.clear();
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(data['lat'], data['lng']),
          infoWindow: InfoWindow(
            title: data['title'],
            snippet: data['snippet'],
          ),
          icon: data['image'] != null
              ? BitmapDescriptor.fromBytes(Uint8List.fromList((data['image'] as List<dynamic>).cast<int>()))
              : BitmapDescriptor.defaultMarker,
          onTap: () {
            _onMarkerTapped(MarkerId(doc.id));
          },
        );
        _markers.add(marker);
      }
    });
  }


  Future<void> _saveMarker(Marker marker) async {
    await markersCollection.doc(marker.markerId.value).set({
      'title': marker.infoWindow.title,
      'snippet': marker.infoWindow.snippet,
      'lat': marker.position.latitude,
      'lng': marker.position.longitude,
      'image': marker.icon != BitmapDescriptor.defaultMarker
          ? await _bitmapDescriptorToBytes(marker.icon)
          : null,
    });
  }

  Future<void> _deleteMarker(Marker marker) async {
    await markersCollection.doc(marker.markerId.value).delete();
  }

  Future<Uint8List> _bitmapDescriptorToBytes(BitmapDescriptor descriptor) async {
    // BitmapDescriptor를 바이트로 변환하는 로직을 추가해야 합니다.
    return Uint8List(0);
  }

  Future<Uint8List> _fileToBytes(File file) async {
    return file.readAsBytes();
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _loadMarkers();
  }

  void _onMarkerTapped(MarkerId markerId) {
    final marker = _markers.firstWhere(
          (m) => m.markerId == markerId,
      orElse: () => throw Exception('Marker not found for ID: $markerId'),
    );

    setState(() {
      _selectedMarker = marker;
    });
    _showMarkerInfoBottomSheet(marker);
  }

  void _onMapTapped(LatLng latLng) {
    setState(() {
      _pendingLatLng = latLng;
    });
    _navigateToMarkerCreationScreen();
  }

  void _navigateToMarkerCreationScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => MarkerCreationScreen(),
      ),
    );

    if (result != null && _pendingLatLng != null) {
      final imageBytes =
      result['image'] != null ? await _fileToBytes(result['image']) : null;
      _addMarker(
          result['title'], result['snippet'], imageBytes, _pendingLatLng!);
      _pendingLatLng = null;
    }
  }

  void _showMarkerInfoBottomSheet(Marker marker) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => MarkerInfoBottomSheet(
        marker: marker,
        onEdit: (updatedMarker) {
          setState(() {
            _markers.remove(marker);
            _markers.add(updatedMarker);
            _saveMarker(updatedMarker);
            _updateSearchResults(_searchController.text);
          });
        },
        onDelete: () {
          setState(() {
            _markers.remove(marker);
            _deleteMarker(marker);
            _updateSearchResults(_searchController.text);
          });
          Navigator.pop(context); // Close the bottom sheet
        },
      ),
    );
  }

  void _addMarker(
      String? title, String? snippet, Uint8List? imageBytes, LatLng position) {
    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
      icon: imageBytes != null
          ? BitmapDescriptor.fromBytes(imageBytes)
          : BitmapDescriptor.defaultMarker,
      onTap: () {
        _onMarkerTapped(MarkerId(position.toString()));
      },
    );

    setState(() {
      _markers.add(marker);
      _saveMarker(marker);
      _updateSearchResults(_searchController.text);
    });
  }

  void _onSearchSubmitted(String query) {
    _updateSearchResults(query);
  }

  void _updateSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
    } else {
      setState(() {
        _searchResults = _markers.where((marker) {
          final title = marker.infoWindow.title?.toLowerCase() ?? '';
          return title.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: TextStyle(color: Colors.white),
          onChanged: _updateSearchResults,
          onSubmitted: _onSearchSubmitted,
        ),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _onSearchSubmitted(_searchController.text),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _seoulCityHall,
              zoom: 13.0,
            ),
            markers: Set<Marker>.from(
                _searchResults.isEmpty ? _markers : _searchResults),
            onTap: _onMapTapped,
          ),
          if (_searchResults.isNotEmpty) ...[
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final marker = _searchResults[index];
                    return ListTile(
                      title: Text(marker.infoWindow.title ?? 'Untitled'),
                      subtitle: Text(marker.infoWindow.snippet ?? ''),
                      onTap: () {
                        _controller?.animateCamera(
                          CameraUpdate.newLatLng(marker.position),
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


class MarkerCreationScreen extends StatefulWidget {
  @override
  State<MarkerCreationScreen> createState() => _MarkerCreationScreenState();
}

class _MarkerCreationScreenState extends State<MarkerCreationScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _snippetController = TextEditingController();
  File? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Marker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _snippetController,
              decoration: InputDecoration(labelText: 'Snippet'),
            ),
            SizedBox(height: 16),
            _image == null
                ? Text('No image selected.')
                : Image.file(_image!, height: 200),
            ElevatedButton(
              onPressed: () async {
                final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _image = File(pickedFile.path);
                  });
                }
              },
              child: Text('Pick Image'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'title': _titleController.text,
                  'snippet': _snippetController.text,
                  'image': _image,
                });
              },
              child: Text('Save Marker'),
            ),
          ],
        ),
      ),
    );
  }
}

class MarkerInfoBottomSheet extends StatelessWidget {
  final Marker marker;
  final void Function(Marker) onEdit;
  final VoidCallback onDelete;

  MarkerInfoBottomSheet({
    required this.marker,
    required this.onEdit,
    required this.onDelete,
  });

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _snippetController = TextEditingController();
  File? _image;

  @override
  Widget build(BuildContext context) {
    _titleController.text = marker.infoWindow.title ?? '';
    _snippetController.text = marker.infoWindow.snippet ?? '';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Title'),
          ),
          TextField(
            controller: _snippetController,
            decoration: InputDecoration(labelText: 'Snippet'),
          ),
          SizedBox(height: 16),
          _image == null
              ? Text('No image selected.')
              : Image.file(_image!, height: 200),
          ElevatedButton(
            onPressed: () async {
              final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                _image = File(pickedFile.path);
              }
            },
            child: Text('Pick Image'),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final updatedMarker = Marker(
                markerId: marker.markerId,
                position: marker.position,
                infoWindow: InfoWindow(
                  title: _titleController.text,
                  snippet: _snippetController.text,
                ),
                icon: _image != null
                    ? BitmapDescriptor.fromBytes(_image!.readAsBytesSync())
                    : marker.icon,
              );
              onEdit(updatedMarker);
              Navigator.pop(context);
            },
            child: Text('Update Marker'),
          ),
          ElevatedButton(
            onPressed: onDelete,
            child: Text('Delete Marker'),
          ),
        ],
      ),
    );
  }
}
