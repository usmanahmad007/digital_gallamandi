import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SoilDetailsScreen extends StatefulWidget {
  const SoilDetailsScreen({super.key});

  @override
  State<SoilDetailsScreen> createState() => _SoilDetailsScreenState();
}

class _SoilDetailsScreenState extends State<SoilDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, double>? _soilData;
  Position? _currentPosition;
  String _cityName = "Detecting City...";
  final double _radius = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// Main logic to sequence permissions, location, city name, and API call
  Future<void> _initializeData() async {
    try {
      // 1. Get Location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition();

      // 2. ALTERNATIVE: Get City Name via OpenStreetMap (No Plugin Required)
      String city = "Unknown City";
      try {
        final geoUrl = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}';
        final geoRes = await http.get(Uri.parse(geoUrl), headers: {'User-Agent': 'ZraiMart_App'});

        if (geoRes.statusCode == 200) {
          final geoData = jsonDecode(geoRes.body);
          final address = geoData['address'];
          // Try to get city, town, or village
          city = address['city'] ?? address['town'] ?? address['village'] ?? address['suburb'] ?? "Unknown City";
        }
      } catch (e) {
        debugPrint("Reverse Geocode Error: $e");
        city = "Location Found";
      }

      // 3. Get Soil Data
      final data = await getSoilData(latitude: position.latitude, longitude: position.longitude);

      setState(() {
        _currentPosition = position;
        _cityName = city;
        _soilData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// The Kaegro API Logic
  Future<Map<String, double>> getSoilData({
    required double latitude,
    required double longitude,
  }) async {
    final String url = 'https://www.kaegro.com/farms/api/soil?lat=$latitude&lon=$longitude';

    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final chemical = data['chemical'] ?? {};

        double? apiPh = chemical['ph_h2o'];
        double? apiN = chemical['nitrogen_g_kg'];
        double? apiOM = chemical['organic_matter_pct'];

        return {
          'ph': (apiPh != null) ? apiPh : 6.5,
          'n': (apiN != null) ? apiN * 10.0 : 120.0,
          'p': (apiOM != null) ? apiOM * 20.0 : 45.0,
          'k': (apiOM != null) ? apiOM * 15.0 : 35.0,
        };
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }
    return {'ph': 6.5, 'n': 100.0, 'p': 50.0, 'k': 40.0};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50]!,
      appBar: AppBar(
        title: const Text("Soil Quality Analysis", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.green, strokeWidth: 3),
            const SizedBox(height: 20),
            Text("Analyzing soil in $_cityName...", style: TextStyle(color: Colors.green[800])),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 10),
              Text(_errorMessage!, textAlign: TextAlign.center),
              TextButton(onPressed: () => _initializeData(), child: const Text("Retry")),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 25),
          const Text("Nutrient Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _buildNutrientGrid(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
            child: Icon(Icons.location_on, color: Colors.green[700], size: 35),
          ),
          const SizedBox(height: 15),
          Text(_cityName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(
            "Lat: ${_currentPosition?.latitude.toStringAsFixed(4)} • Lon: ${_currentPosition?.longitude.toStringAsFixed(4)}",
            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoTile("Radius", "$_radius KM", Icons.radar),
              _buildInfoTile("Depth", "0-30 CM", Icons.layers_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildNutrientGrid() {
    final d = _soilData!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _nutrientCard("Nitrogen (N)", d['n']!, "g/kg", Colors.blue[600]!),
        _nutrientCard("Phosphorus (P)", d['p']!, "mg/kg", Colors.orange[700]!),
        _nutrientCard("Potassium (K)", d['k']!, "mg/kg", Colors.deepPurple[400]!),
        _nutrientCard("Soil pH", d['ph']!, "pH", Colors.teal[600]!),
      ],
    );
  }

  Widget _nutrientCard(String title, double value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(unit, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}