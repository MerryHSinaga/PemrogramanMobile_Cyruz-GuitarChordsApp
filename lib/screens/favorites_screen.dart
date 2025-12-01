import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<Map<String, dynamic>> favorites = [];
  List<Map<String, dynamic>> _allGuitars = [];
  bool _loading = true;

  final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');

  final List<String> _currencies = ['IDR', 'USD', 'EUR', 'JPY'];
  String _selectedCurrency = 'IDR';
  Map<String, double> _rates = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadSavedCurrency();
    await _fetchRates();
    await _fetchAllGuitars();
    await _loadFavoritesAndResolve();
    setState(() => _loading = false);
  }

  Future<void> _loadSavedCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString('currency_favorite') ?? 'IDR';
  }

  Future<void> _saveCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_favorite', _selectedCurrency);
  }

  Future<void> _fetchRates() async {
    try {
      final res =
          await http.get(Uri.parse("https://open.er-api.com/v6/latest/IDR"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data["rates"] is Map) {
          _rates = (data["rates"] as Map).map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        }
      }
    } catch (e) {
      _rates = {};
    }
  }

  Future<void> _fetchAllGuitars() async {
    try {
      final res = await http.get(
          Uri.parse('https://guitar-price-api-kaize.vercel.app/api/guitar'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          _allGuitars = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['data'] is List) {
          _allGuitars = (data['data'] as List).cast<Map<String, dynamic>>();
        }
      }
    } catch (_) {}
  }

  Future<void> _loadFavoritesAndResolve() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('favorites') ?? [];
    final List<Map<String, dynamic>> resolved = [];

    for (final item in raw) {
      Map<String, dynamic>? decoded;

      try {
        decoded = jsonDecode(item);
      } catch (_) {}

      if (decoded != null && decoded.containsKey('name')) {
        resolved.add(decoded);
        continue;
      }

      final match = _allGuitars.firstWhere(
        (g) => (g['name'] ?? '').toString() == item,
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        resolved.add(Map<String, dynamic>.from(match));
      } else {
        resolved.add({'name': item});
      }
    }

    setState(() => favorites = resolved);
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final cleaned = v.replaceAll(',', '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  double _convertPrice(dynamic idr) {
    final priceIdr = _toDouble(idr);
    if (_selectedCurrency == "IDR") return priceIdr;

    if (_rates.containsKey(_selectedCurrency)) {
      final rate = _rates[_selectedCurrency]!;
      return priceIdr * rate;
    }
    return priceIdr;
  }

  Future<void> _removeFavorite(Map<String, dynamic> g) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('favorites') ?? [];

    final name = g['name'] ?? '';

    final newList = raw.where((item) {
      try {
        final d = jsonDecode(item);
        if (d is Map && d['name'] != null) {
          return d['name'] != name;
        }
      } catch (_) {
        return item != name;
      }
      return true;
    }).toList();

    await prefs.setStringList('favorites', newList);
    await _loadFavoritesAndResolve();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Dihapus dari favorit",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A2B5B),
      ),
    );
  }

  Widget _currencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B5B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCurrency,
          isDense: true,
          iconSize: 18,
          dropdownColor: Colors.white,
          iconEnabledColor: Colors.white,
          style: const TextStyle(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          items: _currencies.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(
                c,
                style: const TextStyle(fontSize: 12, color: Color(0xFF1A2B5B)),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _selectedCurrency = val;
            });
            _saveCurrency();
          },
        ),
      ),
    );
  }

  Widget _buildGuitarCard(Map<String, dynamic> g) {
    final name = g['name'] ?? '';
    final type = g['type'] ?? '';
    final imageUrl = g['image_url'] ?? '';
    final priceRaw = g['price_idr'] ?? g['price'] ?? g['price_id'];
    final convertedPrice = _convertPrice(priceRaw);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFBFC6D0).withOpacity(0.10),
            const Color.fromARGB(255, 103, 139, 232),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 170,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color.fromARGB(255, 18, 33, 84),
                        width: 1.5),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete,
                        size: 18, color: Color.fromARGB(255, 29, 33, 111)),
                    onPressed: () => _removeFavorite(g),
                  ),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2B5B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  type,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "${_formatter.format(convertedPrice)} $_selectedCurrency",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A2B5B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _currencyDropdown(),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 15, 100, 185), Color(0xFF1A2B5B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A2B5B)))
          : favorites.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada favorit.",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (_, i) => _buildGuitarCard(favorites[i]),
                ),
    );
  }
}
