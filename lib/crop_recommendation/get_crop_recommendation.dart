import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getCropRecommendation({
  required double n,
  required double p,
  required double k,
  required double temperature,
  required double humidity,
  required double ph,
  required double rainfall,
}) async {
  final url = Uri.parse("https://crop-recommendation-61xz.onrender.com/predict");
  print("GIFT");

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "N": n,
      "P": p,
      "K": k,
      "temperature": temperature,
      "humidity": humidity,
      "ph": ph,
      "rainfall": rainfall,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['recommended_crop'];
  } else {
    throw Exception("Failed to get crop recommendation: ${response.body}");
  }
}
