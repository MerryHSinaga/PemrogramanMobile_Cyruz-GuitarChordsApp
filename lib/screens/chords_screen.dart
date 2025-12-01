import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chord_detail_screen.dart';

class ChordsScreen extends StatefulWidget {
  const ChordsScreen({super.key});

  @override
  State<ChordsScreen> createState() => _ChordsScreenState();
}

class _ChordsScreenState extends State<ChordsScreen> {
  List<dynamic> _chords = [];
  List<dynamic> _filteredChords = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';

  final List<String> _chordTypes = [
    'All',
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
  ];

  @override
  void initState() {
    super.initState();
    fetchChords();
  }

  Future<void> fetchChords() async {
    final Uri url = Uri.parse("https://guitar-chords-api-kaize.vercel.app/");
    try {
      final response = await http.get(url, headers: {"Accept": "application/json"});
      if (response.statusCode == 200) {
        String body = response.body.trim();
        final jsonResponse = jsonDecode(body);
        if (jsonResponse is List) {
          setState(() {
            _chords = jsonResponse;
            _filteredChords = _chords;
            _isLoading = false;
          });
        } else if (jsonResponse is Map &&
            jsonResponse["status"] == "success" &&
            jsonResponse["data"] != null) {
          setState(() {
            _chords = jsonResponse["data"];
            _filteredChords = _chords;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading chords: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _filterChords(String query) {
    setState(() {
      _filteredChords = _chords
          .where((chord) =>
              chord['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
      if (_selectedFilter != 'All') {
        _filteredChords = _filteredChords
            .where((chord) => chord['name'].toString().startsWith(_selectedFilter))
            .toList();
      }
    });
  }

  void _applyLetterFilter(String letter) {
    setState(() {
      _selectedFilter = letter;
      if (letter == 'All') {
        _filteredChords = _chords;
      } else {
        _filteredChords =
            _chords.where((c) => c['name'].toString().startsWith(letter)).toList();
      }
    });
  }

  Widget _buildChordCard(Map<String, dynamic> chord) {
    final String imageUrl = chord['image_url'] ?? '';
    final String name = chord['name'] ?? 'Unknown';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF1A2B5B).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        color: Colors.white,
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 40),
                      ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFBFC6D0).withOpacity(0.10),
                  Color.fromARGB(255, 103, 139, 232),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            child: Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A2B5B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxis = screenWidth >= 900 ? 4 : screenWidth >= 700 ? 3 : 2;
    final double gridChildAspect = screenWidth >= 900
        ? 0.78
        : screenWidth >= 700
            ? 0.8
            : 0.82;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Let your fingers tell the story through every chord.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1A2B5B),
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF1A2B5B).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  style: const TextStyle(color: Color(0xFF1A2B5B)),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, color: Color(0xFF1A2B5B)),
                    hintText: 'Search chord...',
                    hintStyle: TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  ),
                  onChanged: _filterChords,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Filter by:", style: TextStyle(color: Colors.black54)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2B5B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1A2B5B)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isDense: true,
                        alignment: Alignment.center,
                        dropdownColor: Colors.white,
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        selectedItemBuilder: (context) {
                          return _chordTypes.map<Widget>((item) {
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items: _chordTypes.map((letter) {
                          return DropdownMenuItem<String>(
                            value: letter,
                            child: Text(
                              letter,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A2B5B),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) _applyLetterFilter(value);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF1A2B5B)),
                      )
                    : _filteredChords.isEmpty
                        ? const Center(
                            child: Text(
                              'No chords found',
                              style: TextStyle(color: Colors.black54),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxis,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: gridChildAspect,
                            ),
                            itemCount: _filteredChords.length,
                            itemBuilder: (context, index) {
                              final chord = _filteredChords[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChordDetailScreen(
                                        name: chord['name'],
                                        imageUrl: chord['image_url'],
                                      ),
                                    ),
                                  );
                                },
                                child: _buildChordCard(chord),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
