import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _guitars = [];
  List<Map<String, dynamic>> _filtered = [];
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['All', 'Electric', 'Acoustic', 'Bass'];
  String _selectedCategory = "All";
  final List<String> _currencies = ['IDR', 'USD', 'EUR', 'JPY'];
  String _selectedCurrency = 'IDR';
  Map<String, double> _rates = {};
  final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  Set<String> _favorites = {};
  Map<String, bool> _isAnimating = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _fetchGuitars();
    _fetchRates();
    _searchController.addListener(_applyFilter);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favList = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favorites = favList.toSet();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }

  Future<void> _fetchGuitars() async {
    try {
      final res = await http.get(
          Uri.parse('https://guitar-price-api-kaize.vercel.app/api/guitar'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List) {
          _guitars = data.cast<Map<String, dynamic>>();
        } else if (data is Map && data['data'] is List) {
          _guitars = (data['data'] as List).cast<Map<String, dynamic>>();
        } else {
          _guitars = [];
        }
        _filtered = List.from(_guitars);
      }
    } catch (e) {
      _guitars = [];
      _filtered = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _fetchRates() async {
    try {
      final res =
          await http.get(Uri.parse('https://open.er-api.com/v6/latest/IDR'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is Map && data['rates'] is Map) {
          final Map raw = data['rates'];
          _rates = raw.map(
              (k, v) => MapEntry(k.toString(), (v as num).toDouble()));
        }
      }
    } catch (e) {
      _rates = {};
    }
    if (!mounted) return;
    setState(() {});
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

  double _convertPrice(dynamic priceIdrRaw) {
    final priceIdr = _toDouble(priceIdrRaw);
    if (_selectedCurrency == 'IDR') return priceIdr;
    if (_rates.containsKey(_selectedCurrency)) {
      final rate = _rates[_selectedCurrency]!;
      return priceIdr * rate;
    }
    return priceIdr;
  }

  void _applyFilter() {
    final s = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _guitars.where((g) {
        final name = (g['name'] ?? '').toString().toLowerCase();
        final type = (g['type'] ?? '').toString().toLowerCase();
        final matchesSearch = name.contains(s);
        bool matchesCategory = true;
        if (_selectedCategory != "All") {
          matchesCategory = type.contains(_selectedCategory.toLowerCase());
        }
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _toggleFavorite(String name) {
    final isFav = _favorites.contains(name);
    setState(() {
      if (!isFav) {
        _favorites.add(name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ditambahkan ke favorit',
                style: TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 1),
            backgroundColor: const Color(0xFF1A2B5B),
          ),
        );
      } else {
        _favorites.remove(name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Dihapus dari favorit',
                style: TextStyle(color: Colors.white)),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.grey,
          ),
        );
      }
      _saveFavorites();
      _isAnimating[name] = true;
    });
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) {
        setState(() {
          _isAnimating[name] = false;
        });
      }
    });
  }

  void _showZoomImage(String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF1A2B5B),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildGuitarCard(Map<String, dynamic> g, double cardHeight) {
    final converted = _convertPrice(g['price_idr']);
    final name = g['name'] ?? '';
    final type = g['type'] ?? '';
    final isFavorite = _favorites.contains(name);
    final isAnim = _isAnimating[name] ?? false;
    final imageHeight = cardHeight * 0.48;

    return GestureDetector(
      onLongPress: () => _showZoomImage(g['image_url'] ?? ''),
      child: Container(
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
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: imageHeight,
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      g['image_url'] ?? '',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    height: 32,
                    width: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF1A2B5B), width: 1.5),
                      color: Colors.white.withOpacity(0.9),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: AnimatedScale(
                      scale: isAnim ? 1.25 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: IconButton(
                        padding: const EdgeInsets.all(4),
                        icon: Icon(
                          Icons.star,
                          size: 20,
                          color:
                              isFavorite ? Colors.amber : const Color(0xFF1A2B5B),
                        ),
                        onPressed: () => _toggleFavorite(name),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A2B5B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_formatter.format(converted)} $_selectedCurrency',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1A2B5B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledDropdownSmall({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2B5B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2B5B)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          alignment: Alignment.center,
          dropdownColor: Colors.white,
          iconEnabledColor: Colors.white,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          selectedItemBuilder: (context) {
            return items.map<Widget>((item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  item,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList();
          },
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2B5B),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxis = screenWidth >= 900
        ? 4
        : screenWidth >= 700
            ? 3
            : 2;
    final double cardHeight =
        screenWidth >= 900 ? 310 : screenWidth >= 700 ? 330 : 360;
    final double gridChildAspect =
        screenWidth >= 900 ? 0.62 : screenWidth >= 700 ? 0.63 : 0.65;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF1A2B5B)))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Simplify guitar price checking in seconds.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2B5B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color:
                                Color(0xFF1A2B5B).withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search guitar by name...',
                          prefixIcon: Icon(Icons.search,
                              color: Color(0xFF1A2B5B)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: _styledDropdownSmall(
                            value: _selectedCategory,
                            items: _categories,
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedCategory = v);
                                _applyFilter();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _styledDropdownSmall(
                            value: _selectedCurrency,
                            items: _currencies,
                            onChanged: (v) {
                              if (v != null) {
                                setState(
                                    () => _selectedCurrency = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(
                              child: Text("No guitars found.",
                                  style: TextStyle(
                                      color: Colors.black54)))
                          : GridView.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxis,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: gridChildAspect,
                              ),
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) =>
                                  _buildGuitarCard(
                                      _filtered[index],
                                      cardHeight),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
