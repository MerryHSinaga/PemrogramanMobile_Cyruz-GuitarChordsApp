import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

const String geoapifyApiKey = '1d21dc8a501a42dbb18ceb7b5ebf4361';

class MapMusicScreen extends StatefulWidget {
  const MapMusicScreen({super.key});

  @override
  State<MapMusicScreen> createState() => _MapMusicScreenState();
}

class _MapMusicScreenState extends State<MapMusicScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _stores = [];
  List<Marker> _markers = [];
  List<Polyline> _route = [];
  bool _isLoading = true;
  String? _error;
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
  }

  Future<void> _initLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Layanan lokasi tidak aktif.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen.');
      }

      // Posisi awal
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentPos = LatLng(position.latitude, position.longitude);

      setState(() => _currentPosition = currentPos);

      //Data toko musik 
      await _fetchMusicStores(currentPos);

      //Lokasi
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 2, 
        ),
      );

      _positionStream!.listen((Position position) {
        final newPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentPosition = newPos;
        });
        _updateUserMarker(newPos);
        _updateDistances(newPos);
      });
    } catch (e) {
      print("❌ Error lokasi: $e");
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMusicStores(LatLng pos) async {
    try {
      final url =
          'https://api.geoapify.com/v2/places?categories=commercial.hobby.music&filter=circle:${pos.longitude},${pos.latitude},15000&bias=proximity:${pos.longitude},${pos.latitude}&limit=20&apiKey=$geoapifyApiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception("Geoapify error ${response.statusCode}");
      }

      final data = jsonDecode(response.body);
      final features = data['features'] as List;

      List<Map<String, dynamic>> stores = [];
      List<Marker> newMarkers = [];

      for (var item in features) {
        final coords = item['geometry']['coordinates'];
        final name = item['properties']['name'] ?? 'Toko Musik';
        final address = item['properties']['formatted'] ?? '-';
        final distance = item['properties']['distance'] ?? 0.0;

        final store = {
          'name': name,
          'address': address,
          'distance': distance,
          'lat': coords[1],
          'lon': coords[0],
        };
        stores.add(store);

        newMarkers.add(
          Marker(
            width: 60,
            height: 60,
            point: LatLng(coords[1], coords[0]),
            child: GestureDetector(
              onTap: () => _showStoreDetails(store),
              child: const Icon(Icons.location_on, color: Colors.red, size: 40),
            ),
          ),
        );
      }

      // Lokasi pengguna
      newMarkers.add(
        Marker(
          width: 60,
          height: 60,
          point: pos,
          child: const Icon(Icons.person_pin_circle,
              color: Colors.blueAccent, size: 45),
        ),
      );

      setState(() {
        _stores = stores;
        _markers = newMarkers;
      });
    } catch (e) {
      setState(() => _error = "Gagal memuat data toko musik: $e");
    }
  }

  void _updateUserMarker(LatLng newPos) {
    final userMarker = Marker(
      width: 60,
      height: 60,
      point: newPos,
      child: const Icon(Icons.person_pin_circle,
          color: Colors.blueAccent, size: 45),
    );

    final otherMarkers = _markers.where((m) =>
        m.child is! Icon || (m.child as Icon).icon != Icons.person_pin_circle);

    setState(() {
      _markers = [...otherMarkers, userMarker];
    });
  }

  void _updateDistances(LatLng newPos) {
    const Distance distance = Distance();
    final updatedStores = _stores.map((store) {
      final dist = distance(
        newPos,
        LatLng(store['lat'], store['lon']),
      );
      return {
        ...store,
        'distance': dist,
      };
    }).toList();

    setState(() => _stores = updatedStores);
  }

  void _goToMyLocation() {
    if (_currentPosition != null) {
      _mapController.move(_currentPosition!, 16);
    }
  }

  void _showStoreList() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView.builder(
          itemCount: _stores.length,
          itemBuilder: (context, index) {
            final store = _stores[index];
            return ListTile(
              title: Text(store['name']),
              subtitle: Text(store['address']),
              trailing: Text("${store['distance'].toStringAsFixed(0)} m"),
              onTap: () {
                Navigator.pop(context);
                _mapController.move(LatLng(store['lat'], store['lon']), 16);
                _showStoreDetails(store);
              },
            );
          },
        );
      },
    );
  }

  void _showStoreDetails(Map<String, dynamic> store) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(store['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text(store['address']),
              const SizedBox(height: 8),
              Text("Jarak: ${store['distance'].toStringAsFixed(0)} meter"),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showRouteToStore(LatLng(store['lat'], store['lon']));
                },
                icon: const Icon(Icons.alt_route),
                label: const Text("Tunjukkan Rute"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRouteToStore(LatLng destination) async {
    if (_currentPosition == null) return;

    final url =
        'https://api.geoapify.com/v1/routing?waypoints=${_currentPosition!.latitude},${_currentPosition!.longitude}|${destination.latitude},${destination.longitude}&mode=drive&apiKey=$geoapifyApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      print("Gagal ambil rute: ${response.body}");
      return;
    }

    final data = jsonDecode(response.body);
    final coords =
        data['features'][0]['geometry']['coordinates'][0] as List<dynamic>;

    final points =
        coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

    setState(() {
      _route = [
        Polyline(points: points, strokeWidth: 5, color: Colors.deepPurple)
      ];
    });

    _mapController.move(destination, 14);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: GradientAppBar(title: "Memuat Lokasi..."),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const GradientAppBar(title: "Kesalahan"),
        body: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const GradientAppBar(title: "Toko Musik Terdekat."),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition!,
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://maps.geoapify.com/v1/tile/carto/{z}/{x}/{y}.png?apiKey=$geoapifyApiKey',
            userAgentPackageName: 'com.example.app',
            tileProvider: NetworkTileProvider(),
          ),
          PolylineLayer(polylines: _route),
          MarkerLayer(markers: _markers),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'my_location',
            backgroundColor: Colors.blue,
            onPressed: _goToMyLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'list_stores',
            backgroundColor: const Color.fromARGB(255, 166, 45, 193),
            onPressed: _showStoreList,
            child: const Icon(Icons.list),
          ),
        ],
      ),
    );
  }
}

class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const GradientAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 190, 44, 206), Colors.indigo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
