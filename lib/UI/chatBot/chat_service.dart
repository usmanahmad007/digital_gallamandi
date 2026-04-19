import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatService {
  // 2026 Standard Model
  // Option A: Very stable and fast
  // Change this:
  //static const String _modelName = 'gemini-1.5-flash-8b';

// To this:
  static const String _modelName = 'gemini-3.1-flash-lite-preview';

// Option B: The current standard stable
// static const String _modelName = 'gemini-1.5-flash';
  //static const String _modelName = 'gemini-3-flash-preview';
  static String get _apiKey {
    final key = dotenv.env['CHAT_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception("API key not found in .env");
    }
    return key;
  }
  final GenerativeModel _model;
  late final ChatSession _chat;


  ChatService()
      : _model = GenerativeModel(
          model: _modelName,
          apiKey: _apiKey,
          systemInstruction: Content.system(
              "You are the official Digital Galla Mandi Assistant for You "
              "You help farmers with: 1. Crop diseases, 2. Mandi rates, 3. Planting advice. "
              "Keep answers concise and rural-friendly."),
        ) {
    _chat = _model.startChat();
  }

  Future<String?> getResponse(String text, File? imageFile, String language) async {
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        // Add language instruction to the prompt dynamically
        String languagePrompt = " Please respond strictly in $language.";

        if (imageFile != null) {
          final imageBytes = await imageFile.readAsBytes();
          final prompt = TextPart((text.isEmpty ? "Analyze this image." : text) + languagePrompt);
          final imagePart = DataPart('image/jpeg', imageBytes);
          final response = await _model.generateContent([Content.multi([prompt, imagePart])]);
          return response.text;
        } else {
          final response = await _chat.sendMessage(Content.text(text + languagePrompt));
          return response.text;
        }
      } catch (e) {
        if (e.toString().contains('503')) {
          retryCount++;
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        return "Error: $e";
      }
    }
    return "Busy...";
  }
}
