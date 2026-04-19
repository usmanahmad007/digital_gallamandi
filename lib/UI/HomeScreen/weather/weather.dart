import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../app_colors.dart';
import '../../../saller center/homeScreen/RecomandedProductsScreen.dart';
import '../../chatBot/SafetyMeasuresScreen.dart';
import 'WeatherService.dart'; // Import the backend logic

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});
  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic>? weatherData;
  String errorMessage = '';
  Position? _currentPosition;
  String cityName = 'Locating...';
  bool isSaller = false;

  @override
  void initState() {
    super.initState();
    _initWeatherFlow();
  }

  Future<void> _initWeatherFlow() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() => errorMessage = 'Permission denied');
      return;
    }

    try {
      // Use Backend Service
      isSaller = await WeatherService.checkIfSeller();
      _currentPosition = await WeatherService.determinePosition();
      cityName = await WeatherService.getCityName(_currentPosition!.latitude, _currentPosition!.longitude);
      weatherData = await WeatherService.fetchWeatherData(_currentPosition!.latitude, _currentPosition!.longitude);
      setState(() {});
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppColors.primaryGreen;
    final weatherInfo = WeatherService.getWeatherDetails(weatherData?['current']['weather_code']);

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      appBar: AppBar(
        title: const Text("Weather Forecast", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: weatherData == null
          ? Center(child: errorMessage.isNotEmpty ? Text(errorMessage) : const CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildMainCard(primaryColor, weatherInfo),
            const SizedBox(height: 30),
            _buildHourlyList(primaryColor),
            const SizedBox(height: 30),
            _buildActionButtons(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(Color primary, Map<String, dynamic> info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text(cityName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(DateFormat('EEEE, d MMMM').format(DateTime.now()), style: TextStyle(color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 20),
          Icon(info['icon'], size: 80, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            "${weatherData!['current']['temperature_2m']}°C",
            style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w200),
          ),
          Text(info['label'].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _weatherDetailItem(Icons.air, "${weatherData!['current']['wind_speed_10m']} m/s", "Wind"),
              _weatherDetailItem(Icons.water_drop, "${weatherData!['hourly']['relative_humidity_2m'][0]}%", "Humidity"),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHourlyList(Color primary) {
    final now = DateTime.now();
    final hourlyData = weatherData!['hourly'];
    final List<dynamic> times = hourlyData['time'];

    int startIndex = 0;
    String currentHourString = DateFormat("yyyy-MM-ddTHH:00").format(now);

    for (int i = 0; i < times.length; i++) {
      if (times[i].startsWith(currentHourString)) {
        startIndex = i;
        break;
      }
    }

    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 24,
        itemBuilder: (context, index) {
          final actualIndex = startIndex + index+1;
          if (actualIndex >= times.length) return const SizedBox.shrink();
          final hourWeather = WeatherService.getWeatherDetails(hourlyData['weather_code'][actualIndex]);

          return Container(
            width: 75,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(hourlyData['time'][actualIndex].substring(11, 16), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Icon(hourWeather['icon'], color: primary, size: 28),
                const SizedBox(height: 8),
                Text("${hourlyData['temperature_2m'][actualIndex]}°", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(Color primary) {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            "Product Recommendations",
            Icons.shopping_basket_outlined,
            primary,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => RecommandedProductsScreen(

            ))),
          ),
        ),
        const SizedBox(width: 15),


        const SizedBox(width: 15),
        Expanded(
          child: _actionButton(
            "Precaution Measures",
            Icons.health_and_safety_outlined,
            primary,
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => SafetyMeasuresScreen(
              city: cityName,
              temperature: weatherData!['current']['temperature_2m'],
              windSpeed: weatherData!['current']['wind_speed_10m'],
              currentDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            ))),
          ),
        ),
      ],
    );
  }

  Widget _weatherDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _actionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}