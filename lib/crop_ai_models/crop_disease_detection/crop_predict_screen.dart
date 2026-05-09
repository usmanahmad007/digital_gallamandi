import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../crop_disease_solution/PlantAdviceScreen.dart';
import 'crop_predict_service.dart';

class CropPredictScreen extends StatefulWidget {
  const CropPredictScreen({super.key});

  @override
  State<CropPredictScreen> createState() => _CropPredictScreenState();
}

class _CropPredictScreenState extends State<CropPredictScreen> {
  File? image;
  String? prediction;
  double confidence = 0.0;
  bool isLoading = false;

  final ImagePicker picker = ImagePicker();
  final Color primaryColor = const Color(0xFF2E7D32); // Modern Forest Green

  Future<void> _pickImage(ImageSource source) async {
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80, // Compress slightly for faster API upload
    );
    if (picked != null) {
      setState(() {
        image = File(picked.path);
        prediction = null; // Reset results for new image
      });
    }
  }

  Future<void> _analyzeImage() async {
    if (image == null) return;

    setState(() => isLoading = true);

    try {
      final responseString = await PredictService.uploadImage(image!);

      if (responseString != null) {
        final Map<String, dynamic> data = jsonDecode(responseString);
        debugPrint(data.toString());
        setState(() {
          prediction = data['prediction'];
          confidence = (data['confidence'] as num).toDouble();
        });
      } else {
        _showError("Server unreachable. Please check your connection.");
      }
    } catch (e) {
      _showError("Analysis failed. Please try a clearer photo.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        title: const Text("Crop Health AI", style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildImageFrame(),
              const SizedBox(height: 32),
              if (image != null && prediction == null) _buildAnalyzeButton(),
              if (prediction != null) _buildResultCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Digital Mandi AI",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        const Text("Plant Disease Detector",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1B1B1B))),
      ],
    );
  }

  Widget _buildImageFrame() {
    return GestureDetector(
      onTap: () => _showPickerOptions(),
      child: Container(
        height: 320,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))
          ],
          border: Border.all(color: Colors.white, width: 8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: image != null
              ? Stack(
            fit: StackFit.expand,
            children: [
              Image.file(image!, fit: BoxFit.cover),
              Positioned(
                bottom: 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                    onPressed: () => _showPickerOptions(),
                  ),
                ),
              )
            ],
          )
              : Container(
            color: primaryColor.withOpacity(0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_center_focus_rounded, size: 64, color: primaryColor),
                const SizedBox(height: 16),
                Text("Tap to Scan Leaf",
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isLoading ? null : _analyzeImage,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("RUN AI DIAGNOSIS",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildResultCard() {
    String readableName = prediction!.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 12))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DIAGNOSIS RESULT",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
          const SizedBox(height: 12),
          Text(readableName,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: primaryColor)),
          const SizedBox(height: 24),

          // Confidence Score UI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AI Confidence", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
              Text("${(confidence * 100).toStringAsFixed(1)}%",
                  style: TextStyle(fontWeight: FontWeight.w900, color: primaryColor)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 12,
              backgroundColor: primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text("Recommendation", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Isolate infected plants and consult your local Agri-Expert for specific fungicide treatment.",
            style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlantAdviceScreen(diseaseName: readableName,imageFile: image!,),
                  ),
                );
              },
              icon: const Icon(Icons.psychology_outlined),
              label: const Text("GET AI TREATMENT STEPS"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildPickerCircle(Icons.camera_rounded, "Camera", () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            }),
            _buildPickerCircle(Icons.photo_library_rounded, "Gallery", () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerCircle(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: primaryColor, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}