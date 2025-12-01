import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //1) CHORD API 
  static const String chordBaseUrl =
      "https://guitar-chords-api-kaize.vercel.app";

  Future<List<dynamic>> getChordList() async {
    final url = Uri.parse("$chordBaseUrl/api/chords");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat daftar chord");
    }
  }

  Future<Map<String, dynamic>> getChordDetail(String chordName) async {
    final url = Uri.parse("$chordBaseUrl/api/chords/$chordName");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat detail chord");
    }
  }

  // 2) GUITAR PRICE API 
  static const String guitarBaseUrl =
      "https://guitar-price-api-kaize.vercel.app/api/guitar";

  Future<List<dynamic>> getGuitarList() async {
    final url = Uri.parse(guitarBaseUrl);
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal memuat daftar gitar");
    }
  }

  //3) CURRENCY CONVERTER API 
  static const String currencyBaseUrl = "http://open.er-api.com/v6/latest";

  Future<Map<String, dynamic>> getCurrencyRates(String baseCode) async {
    final url = Uri.parse("$currencyBaseUrl/$baseCode");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal mengambil data kurs");
    }
  }

  double convertCurrency({
    required double amount,
    required double rateTo,
  }) {
    return amount * rateTo;
  }

  //4) GEOAPIFY STORE LOCATOR 
  static const String geoapifyBaseUrl =
      "https://api.geoapify.com/v2/places";

  
  Future<Map<String, dynamic>> getMusicStores({
    required double lat,
    required double lon,
    int radius = 15000,
    required String apiKey,
  }) async {
    final url = Uri.parse(
      "$geoapifyBaseUrl?"
      "categories=entertainment.music"
      "&filter=circle:$lon,$lat,$radius"
      "&limit=20"
      "&apiKey=$apiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Gagal mengambil data toko musik");
    }
  }
}
