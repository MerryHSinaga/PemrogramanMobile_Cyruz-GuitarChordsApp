import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map_music_screen.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _fromCurrency = 'IDR';
  String _toCurrency = 'USD';
  double? _convertedPrice;
  bool _isLoading = false;

  static const Color mainColor = Color(0xFF9C27B0);
  final List<String> _currencies = ['USD', 'IDR', 'EUR', 'JPY'];
  final NumberFormat _inputFormatter = NumberFormat('#,###', 'en_US');
  final NumberFormat _outputFormatter = NumberFormat('#,##0.00', 'en_US');
  bool _isFormatting = false;

  List<Map<String, dynamic>> _recentConversions = [];
  final String _currentUser = 'user_login_123';
  bool _showRecent = true;

  @override
  void initState() {
    super.initState();
    _loadRecentConversions();

    _priceController.addListener(() {
      if (_isFormatting) return;
      String raw = _priceController.text.replaceAll(',', '');
      if (raw.isEmpty) return;
      final parsed = double.tryParse(raw);
      if (parsed == null) return;
      final formatted = _inputFormatter.format(parsed.round());
      if (formatted != _priceController.text) {
        _isFormatting = true;
        _priceController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
        _isFormatting = false;
      }
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentConversions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('conversions_$_currentUser');
    if (saved != null) {
      final List<dynamic> decoded = json.decode(saved);
      setState(() {
        _recentConversions = decoded.cast<Map<String, dynamic>>();
      });
    }
  }

  Future<void> _saveConversion(
      String name, double fromValue, double toValue) async {
    final prefs = await SharedPreferences.getInstance();

    final newItem = {
      'name': name,
      'from': '$_fromCurrency : ${_inputFormatter.format(fromValue)}',
      'to': '$_toCurrency : ${_outputFormatter.format(toValue)}',
    };

    _recentConversions.insert(0, newItem);
    if (_recentConversions.length > 3) {
      _recentConversions = _recentConversions.sublist(0, 3);
    }

    await prefs.setString(
        'conversions_$_currentUser', json.encode(_recentConversions));
    setState(() {});
  }

  void _swapCurrencies() {
    setState(() {
      final tmp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = tmp;
      _convertedPrice = null;
    });
  }

  Future<void> _convertPrice() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan harga terlebih dahulu!')),
      );
      return;
    }

    final cleanText = _priceController.text.replaceAll(',', '');
    final price = double.tryParse(cleanText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga tidak valid')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _convertedPrice = null;
    });

    final uri = Uri.parse('https://open.er-api.com/v6/latest/$_fromCurrency');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['result'] == 'success' || data['result'] == null) &&
            data['rates'] != null) {
          final rates = data['rates'] as Map<String, dynamic>;
          if (rates.containsKey(_toCurrency)) {
            final rate = (rates[_toCurrency] as num).toDouble();
            final result = price * rate;
            setState(() {
              _convertedPrice = result;
            });
            await _saveConversion(_nameController.text, price, result);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mata uang tujuan tidak ditemukan')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data konversi tidak valid')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal mengambil data (${response.statusCode})')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan koneksi: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _currencyDropdown(String value, bool isFrom) {
    return DropdownButton<String>(
      dropdownColor: Colors.grey[900],
      value: value,
      onChanged: (v) {
        if (v != null) {
          setState(() {
            if (isFrom) {
              _fromCurrency = v;
            } else {
              _toCurrency = v;
            }
            _convertedPrice = null;
          });
        }
      },
      items: _currencies
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.png', fit: BoxFit.cover),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                children: [
                  // Judul
                  const Text(
                    "Simplify guitar price checks, wherever music takes you.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.purpleAccent,
                          blurRadius: 10,
                          offset: Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Input tipe gitar
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: 'Guitar Type',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input harga gitar
                  TextField(
                    controller: _priceController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white10,
                      hintText: 'Price',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pilih mata uang
                  Row(
                    children: [
                      Expanded(child: _currencyDropdown(_fromCurrency, true)),
                      IconButton(
                        onPressed: _swapCurrencies,
                        icon: const Icon(Icons.swap_horiz, color: mainColor),
                        tooltip: 'Swap currencies',
                      ),
                      Expanded(child: _currencyDropdown(_toCurrency, false)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tombol Convert
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _convertPrice,
                    icon: const Icon(Icons.currency_exchange,
                        color: Colors.white),
                    label: Text(
                      _isLoading ? 'Loading...' : 'Convert',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Hasil konversi
                  if (_isLoading)
                    const Center(
                        child: CircularProgressIndicator(color: mainColor))
                  else if (_convertedPrice != null)
                    _buildResultCard(_nameController.text,
                        _formatInputPriceSafely(), _convertedPrice!),

                  // Recent convert
                  if (_recentConversions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => setState(() => _showRecent = !_showRecent),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Recent Converts',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            _showRecent
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.purpleAccent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_showRecent)
                      for (var item in _recentConversions)
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: mainColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'],
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 164, 55, 189),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  )),
                              const SizedBox(height: 6),
                              Text(item['from'],
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 16)),
                              Text(item['to'],
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 16)),
                            ],
                          ),
                        ),
                  ],

                  // Tombol cari toko musik
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MapMusicScreen()),
                      );
                    },
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text(
                      'Find the nearest music store',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(String name, String fromVal, double toVal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mainColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gitar: $name',
              style: const TextStyle(color: Colors.pinkAccent, fontSize: 16)),
          const SizedBox(height: 8),
          Text('$_fromCurrency : $fromVal',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text('$_toCurrency : ${_outputFormatter.format(toVal)}',
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatInputPriceSafely() {
    final raw = _priceController.text.replaceAll(',', '');
    if (raw.isEmpty) return '0';
    final parsed = double.tryParse(raw);
    if (parsed == null) return _priceController.text;
    return _inputFormatter.format(parsed.round());
  }
}
