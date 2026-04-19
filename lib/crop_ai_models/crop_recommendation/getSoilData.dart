import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, double>> getSoilData({
  required double latitude,
  required double longitude,
}) async {
  final String url = 'https://www.kaegro.com/farms/api/soil?lat=$latitude&lon=$longitude';

  // DEBUG: Track the request
  print("--- Soil API Request ---");
  print("URL: $url");

  try {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

    // DEBUG: Track response status
    print("Status Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      // DEBUG: View raw body
      print("Raw Response Body: ${response.body}");

      final Map<String, dynamic> data = jsonDecode(response.body);
      final chemical = data['chemical'];

      // DEBUG: Check if 'chemical' key exists
      if (chemical == null) {
        print("WARNING: 'chemical' key is missing in response!");
      }

      double? apiPh = chemical?['ph_h2o'];
      double? apiN = chemical?['nitrogen_g_kg'];
      double? apiOM = chemical?['organic_matter_pct'];

      // DEBUG: Log extracted values before fallback
      print("Extracted - pH: $apiPh, N: $apiN, OM: $apiOM");

      final result = {
        'ph': (apiPh != null) ? apiPh : 6.5,
        'n': (apiN != null) ? apiN * 10.0 : 120.0,
        'p': (apiOM != null) ? apiOM * 20.0 : 45.0,
        'k': (apiOM != null) ? apiOM * 15.0 : 35.0,
      };

      print("Final Map to be returned: $result");
      print("------------------------");
      return result;
    } else {
      print("Error: API returned status ${response.statusCode}");
    }
  } catch (e, stacktrace) {
    // DEBUG: Log the full error and where it happened
    print("CRITICAL Error fetching from Kaegro: $e");
    print("Stacktrace: $stacktrace");
  }

  print("Returning Fallback Data...");
  print("------------------------");
  return {'ph': 6.5, 'n': 100.0, 'p': 50.0, 'k': 40.0};
}