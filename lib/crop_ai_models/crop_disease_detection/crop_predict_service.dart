import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PredictService {
  static const String apiUrl = "http://46.225.103.125:31678/predict";
  static const String apiKey = "zqmQGAhUNBNIT3IL";

  static Future<String?> uploadImage(File imageFile) async {
    debugPrint("🚀 Sending image to API: ${imageFile.path}");

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse(apiUrl),
      );

      request.headers.addAll({
        "accept": "application/json",
        "X-API-Key": apiKey,
      });

      /// Important fix → set content type
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();

      debugPrint("📡 Status Code: ${response.statusCode}");

      final responseBody = await response.stream.bytesToString();

      debugPrint("📨 Response: $responseBody");

      if (response.statusCode == 200) {
        return responseBody;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
      return null;
    }
  }
}