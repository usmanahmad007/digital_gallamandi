import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey = "AIzaSyD-FImFWKlIukrpz7ynrORquWCIFAN6PM8"; // Replace with your API Key
  final String baseUrl = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent";

  Future<String> getAIResponse(String prompt) async {
    final uri = Uri.parse("$baseUrl?key=$apiKey");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {"parts": [{"text": prompt}]}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"];
    } else {
      return "Error: ${response.statusCode} - ${response.body}";
    }
  }
}
