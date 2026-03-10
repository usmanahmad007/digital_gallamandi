import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';

import 'getSoilData.dart';
import 'get_crop_recommendation.dart';

class CropReccommendation extends StatefulWidget {
  final double n;
  final double p;
  final double k;
  final double temperature;
  final double humidity;
  final double ph;
  final double rainfall;
  final Position currentPosition;

  const CropReccommendation({
    super.key,
    required this.n,
    required this.p,
    required this.k,
    required this.temperature,
    required this.humidity,
    required this.ph,
    required this.rainfall,
    required this.currentPosition
  });

  @override
  State<CropReccommendation> createState() => _CropReccommendationState();
}

class _CropReccommendationState extends State<CropReccommendation> {
  String? recommendedCrop;
  bool isLoading = false;

  void fetchSoilInfo() async {
    print("HI");
    try {
      double lat = widget.currentPosition.latitude;
      double lon = widget.currentPosition.longitude;
      print("HI$lat/$lon");

      final data = await getSoilData(latitude: lat, longitude: lon);

      print("HIIHIH$data");
      print("pH: ${data['pH']}");
      print("N: ${data['n']}");
      print("P: ${data['p']}");
      print("K: ${data['k']}");

    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _getRecommendation() async {
    setState(() => isLoading = true);
    try {
      final result = await getCropRecommendation(
        n: widget.n,
        p: widget.p,
        k: widget.k,
        temperature: widget.temperature,
        humidity: widget.humidity,
        ph: widget.ph,
        rainfall: widget.rainfall,
      );
      setState(() => recommendedCrop = result);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get crop recommendation')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchSoilInfo();
    _getRecommendation();
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Recommended Crop"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: isLoading==true?const Center(child: CircularProgressIndicator(color: Colors.green,),) :Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: isLoading
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/animations/loading.json', width: 180),
                const SizedBox(height: 16),
                const Text(
                  "Analyzing soil and weather...",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                )
              ],
            )
                : recommendedCrop != null
                ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Crop image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/Images/Seasonal Crops/$recommendedCrop.jpg',
                            width: 180,
                            height: 220,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                                  'assets/Images/RecomendationCrops/$recommendedCrop.jpg',
                                  width: 180,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                    color: Colors.white70,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          recommendedCrop!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Divider(color: Colors.white70),
                        const SizedBox(height: 10),
                        // Details
                        _buildDetailRow("Nitrogen (N)", widget.n.toStringAsFixed(2)),
                        _buildDetailRow("Phosphorus (P)", widget.p.toStringAsFixed(2)),
                        _buildDetailRow("Potassium (K)", widget.k.toStringAsFixed(2)),
                        _buildDetailRow("Temperature", "${widget.temperature+2.0}°C"),
                        _buildDetailRow("Humidity", "${widget.humidity}%"),
                        _buildDetailRow("Rainfall", "${widget.rainfall} mm"),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _getRecommendation,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Try Again"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.3),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                : const Text(
              "No data available.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
