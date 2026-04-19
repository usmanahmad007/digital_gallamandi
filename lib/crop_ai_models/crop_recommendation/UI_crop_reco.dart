import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import '../../UI/HomeScreen/weather/WeatherService.dart';
import 'getSoilData.dart';
import 'get_crop_recommendation.dart';

class CropReccommendation extends StatefulWidget {
  const CropReccommendation({super.key});

  @override
  State<CropReccommendation> createState() => _CropReccommendationState();
}

class _CropReccommendationState extends State<CropReccommendation> {
  String? recommendedCrop;
  bool isLoading = false;
  String loadingStatus = "Initializing GPS...";

  double liveN = 0.0, liveP = 0.0, liveK = 0.0, livePH = 0.0;
  double liveTemp = 0.0, liveHumidity = 0.0, liveRainfall = 0.0;

  @override
  void initState() {
    super.initState();
    _runFullAnalysis();
  }

  Future<void> _runFullAnalysis() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      recommendedCrop = null;
      loadingStatus = "Fetching Location...";
    });

    try {
      // 1. Get Position using your WeatherService
      Position position = await WeatherService.determinePosition();

      if (mounted) setState(() => loadingStatus = "Checking Weather & Soil...");

      // 2. Fetch Weather and Soil data in Parallel (Faster)
      final results = await Future.wait([
        WeatherService.fetchWeatherData(position.latitude, position.longitude),
        getSoilData(latitude: position.latitude, longitude: position.longitude),
      ]);

      final weatherData = results[0] as Map<String, dynamic>;
      final soilData = results[1] as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          // Map Soil Data
          liveN = (soilData['n'] ?? 0.0).toDouble();
          liveP = (soilData['p'] ?? 0.0).toDouble();
          liveK = (soilData['k'] ?? 0.0).toDouble();
          livePH = (soilData['pH'] ?? soilData['ph'] ?? 6.5).toDouble();

          // Map Weather Data
          liveTemp = (weatherData['current']['temperature_2m'] ?? 0.0).toDouble();
          liveHumidity = (weatherData['hourly']['relative_humidity_2m'][0] ?? 0.0).toDouble();
          liveRainfall = (weatherData['hourly']['precipitation'][0] ?? 0.0).toDouble();

          loadingStatus = "AI Calculating Best Crop...";
        });
      }

      // 3. Call AI Recommendation
      final result = await getCropRecommendation(
        n: liveN,
        p: liveP,
        k: liveK,
        temperature: liveTemp,
        humidity: liveHumidity,
        ph: livePH,
        rainfall: liveRainfall,
      );

      if (mounted) setState(() => recommendedCrop = result);

    } catch (e) {
      debugPrint("Analysis Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF004D40); // Deep Teal Green

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("AI Field Report",
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D40), Color(0xFF00796B), Color(0xFF26A69A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: isLoading
              ? _buildLoadingUI()
              : recommendedCrop != null
              ? _buildModernDashboard(primaryColor)
              : _buildErrorUI(),
        ),
      ),
    );
  }

  Widget _buildLoadingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/animations/loading.json',
          width: 250,
          errorBuilder: (context, e, s) => const CircularProgressIndicator(color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(loadingStatus,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Text("Our AI is scanning satellite data and soil sensors to find the perfect crop.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildModernDashboard(Color primary) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildHeroImageSection(),
            const SizedBox(height: 20),
            _buildEnvironmentalPills(),
            const SizedBox(height: 20),
            _buildNutrientCard(),
            const SizedBox(height: 25),
            _buildActionButtons(primary),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImageSection() {
    String crop = recommendedCrop!.toLowerCase().trim().replaceAll(' ', '_');
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Image.asset(
              'assets/Images/RecomendationCrops/$crop.jpg',
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 150,
                color: Colors.white10,
                child: const Icon(Icons.eco_rounded, size: 80, color: Colors.white30),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(recommendedCrop!.toUpperCase(),
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                const Text("IDEAL SEED RECOMMENDATION",
                    style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEnvironmentalPills() {
    return Row(
      children: [
        _pillItem(Icons.thermostat, "${liveTemp.toStringAsFixed(1)}°C", "Temp"),
        const SizedBox(width: 10),
        _pillItem(Icons.water_drop, "${liveHumidity.toStringAsFixed(0)}%", "Humidity"),
        const SizedBox(width: 10),
        _pillItem(Icons.cloudy_snowing, "${liveRainfall.toStringAsFixed(1)}mm", "Rain"),
      ],
    );
  }

  Widget _pillItem(IconData icon, String val, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.tealAccent, size: 20),
            Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: Colors.tealAccent, size: 18),
              SizedBox(width: 10),
              Text("SOIL NUTRIENT PROFILE",
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const Divider(color: Colors.white12, height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nutrientStat("N", liveN, Colors.orange),
              _nutrientStat("P", liveP, Colors.blue),
              _nutrientStat("K", liveK, Colors.purple),
              _nutrientStat("pH", livePH, Colors.greenAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _nutrientStat(String label, double val, Color color) {
    return Column(
      children: [
        Container(
          height: 45, width: 45,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 2),
          ),
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(val.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButtons(Color primary) {
    return ElevatedButton(
      onPressed: _runFullAnalysis,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.tealAccent.shade700,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.refresh_rounded),
          SizedBox(width: 10),
          Text("REFRESH SATELLITE SCAN", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off, size: 80, color: Colors.white30),
        const SizedBox(height: 20),
        const Text("Scan Failed", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const Text("Please check your internet connection.", style: TextStyle(color: Colors.white60)),
        const SizedBox(height: 30),
        TextButton(onPressed: _runFullAnalysis, child: const Text("RETRY SCAN", style: TextStyle(color: Colors.tealAccent))),
      ],
    );
  }
}