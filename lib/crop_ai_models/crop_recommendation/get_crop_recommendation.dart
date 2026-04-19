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
  // Use your Hugging Face Direct URL
  // Note: We use query parameters (?) instead of a JSON body
  final String baseUrl = "https://usman0007-crop-recommender-api.hf.space/predict";
  final url = Uri.parse(
      "$baseUrl?n=$n&p=$p&k=$k&temp=$temperature&hum=$humidity&ph=$ph&rain=$rainfall"
  );

  print("Calling API: $url");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Based on your Hugging Face main.py:
      // If your API returns {"crop": "rice"}, use data['crop']
      // If it returns a number, you'll need the mapping we discussed
      return data['crop'].toString().toLowerCase();
    } else {
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      throw Exception("API Error: ${response.statusCode}");
    }
  } catch (e) {
    print("Network Error: $e");
    throw Exception("Failed to connect to Hugging Face");
  }
}