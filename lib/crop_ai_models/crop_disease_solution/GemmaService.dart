import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GemmaService {
  // ✅ Valid model for google_generative_ai
 // static const String _modelName = 'gemini-1.5-flash';
//static const String _modelName = 'gemini-1.5-flash-8b';

// To this:
  static const String _modelName = 'gemini-3.1-flash-lite-preview';

// Option B: The current standard stable
// static const String _modelName = 'gemini-1.5-flash';
  //static const String _modelName = 'gemini-3-flash-preview';
  static String get _apiKey {
    final key = dotenv.env['SOLUTION_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception("API key not found in .env");
    }
    return key;
  }

  static Future<String> getPlantAdvice(String diseaseName, String language) async {
    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        systemInstruction: Content.system(
            "You are the 'Digital Galla Mandi' expert for You."
                "Provide a farmer safety and crop profit report for disease: $diseaseName.\n\n"
                "Include:\n"
                "1. Disease Identification\n"
                "2. Immediate Precautions\n"
                "3. Organic & Chemical Treatments\n"
                "4. Effect on Yield\n"
                "5. Market Impact\n"
                "6. Future Prevention\n\n"
                "Respond strictly in $language using bold headings and bullet points."
        ),
      );

      final prompt =
          "Generate a complete agricultural report for disease: $diseaseName.";

      final response = await model.generateContent([
        Content.text(prompt)
      ]);

      return response.text ?? "No response from AI.";
    } catch (e) {
      return "Service Error: $e";
    }
  }
}