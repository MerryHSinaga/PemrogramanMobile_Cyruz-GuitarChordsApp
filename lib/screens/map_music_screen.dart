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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final currentPos = LatLng(position.latitude, position.longitude);

      setState(() => _currentPosition = currentPos);

      await _fetchMusicStores(currentPos);

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
              child: const Icon(Icons.location_on,
                  color: Color.fromARGB(255, 21, 180, 74), size: 40),
            ),
          ),
        );
      }

      newMarkers.add(
        Marker(
          width: 60,
          height: 60,
          point: pos,
          child: const Icon(
            Icons.person_pin_circle,
            color: Color.fromARGB(255, 19, 46, 93),
            size: 45,
          ),
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
        m.child is! Icon ||
        (m.child as Icon).icon != Icons.person_pin_circle);

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

  //list store music

  void _showStoreList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: _stores.length,
          itemBuilder: (context, index) {
            final store = _stores[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 231, 233, 255), //daftar toko
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ListTile(
                title: Text(
                  store['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2B5B),
                  ),
                ),
                subtitle: Text(
                  store['address'],
                  style: const TextStyle(color: Colors.black54),
                ),
                trailing: Text(
                  "${store['distance'].toStringAsFixed(0)} m",
                  style: const TextStyle(
                    color: Color(0xFF1A2B5B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _mapController.move(
                      LatLng(store['lat'], store['lon']), 16);
                  _showStoreDetails(store);
                },
              ),
            );
          },
        );
      },
    );
  }

  //Detail store music
  void _showStoreDetails(Map<String, dynamic> store) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                store['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: Color(0xFF1A2B5B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                store['address'],
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Jarak: ${store['distance'].toStringAsFixed(0)} meter",
                style: const TextStyle(
                  color: Color(0xFF1A2B5B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2B5B),
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _showRouteToStore(
                        LatLng(store['lat'], store['lon']));
                  },
                  icon: const Icon(Icons.alt_route, size: 20),
                  label: const Text("Tunjukkan Rute",
                      style: TextStyle(fontSize: 16)),
                ),
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
      return;
    }

    final data = jsonDecode(response.body);
    final coords =
        data['features'][0]['geometry']['coordinates'][0] as List<dynamic>;

    final points =
        coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

    setState(() {
      _route = [
        Polyline(
          points: points,
          strokeWidth: 5,
          color: const Color.fromARGB(255, 54, 123, 241),
        )
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
            backgroundColor: const Color(0xFF1A2B5B),
            onPressed: _goToMyLocation,
            child: const Icon(Icons.my_location, color: Color.fromARGB(255, 255, 255, 255)),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'list_stores',
            backgroundColor: const Color.fromARGB(255, 25, 177, 76),
            onPressed: _showStoreList,
            child: const Icon(Icons.list, color: Colors.white),
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
      title: Text(
        title,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 31, 73, 131),
              Color.fromARGB(255, 8, 41, 140),
            ],
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
