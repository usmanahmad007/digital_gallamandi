import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> getSoilData({
  required double latitude,
  required double longitude,
}) async {
  const String baseUrl = 'https://rest.isric.org/soilgrids/v2.0/properties/query';

  // Request all needed properties at once
  final uri = Uri.parse(
    '$baseUrl?lon=$longitude&lat=$latitude&property=phh2o&property=ocd&property=ocd&property=soc&property=nitrogen&depth=0-5cm',
  );

  try {
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final layers = jsonData['properties']['layers'] as List;

      double extractProperty(String propertyName) {
        final layer = layers.firstWhere(
              (l) => l['name'] == propertyName,
          orElse: () => null,
        );

        if (layer == null || layer['depths'] == null) return -1;

        for (var depth in layer['depths']) {
          final mean = depth['values']?['mean'];
          if (mean != null && mean is num) {
            return mean.toDouble();
          }
        }
        return -1;
      }

      double ph = extractProperty('phh2o');
      double nitrogen = extractProperty('nitrogen'); // total nitrogen content
      double p = extractProperty('ocd'); // Organic Carbon Density (rough proxy for phosphorus)
      double k = extractProperty('soc'); // Soil Organic Carbon (used here as potassium proxy)

      // Provide fallback values if any property is missing or invalid
      return {
        'pH': ph != -1 ? ph : 6.5,
        'n': nitrogen != -1 ? nitrogen : 90.0,
        'p': p != -1 ? p : 45.0,
        'k': k != -1 ? k : 30.0,
      };
    } else {
      throw Exception('Failed to fetch soil data: ${response.statusCode}');
    }
  } catch (e) {
    print("Error: $e");
    return {
      'pH': 6.5,
      'n': 90.0,
      'p': 45.0,
      'k': 30.0,
    };
  }
}
