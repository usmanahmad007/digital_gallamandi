import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zrai_mart/crop_ai_models/crop_disease_solution/GemmaService.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
class PlantAdviceScreen extends StatefulWidget {
  final String diseaseName;
  final File imageFile; // Receive the image from the previous screen

  const PlantAdviceScreen({
    super.key,
    required this.diseaseName,
    required this.imageFile,
  });

  @override
  State<PlantAdviceScreen> createState() => _PlantAdviceScreenState();
}

class _PlantAdviceScreenState extends State<PlantAdviceScreen> {
  String result = "";
  bool loading = false;
  String selectedLanguage = "English";
  final Color primaryColor = const Color(0xFF2E7D32);
  final List<String> languages = ["English", "Urdu", "Punjabi", "Russian"];

  @override
  void initState() {
    super.initState();
    _fetchAdvice();
  }

  void _fetchAdvice() async {
    setState(() {
      loading = true;
      result = "";
    });

    // Calling the static method with image and language
    final response = await GemmaService.getPlantAdvice(
      widget.diseaseName,
      selectedLanguage,

    );

    setState(() {
      result = response;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("AI Treatment Plan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        actions: [
          _buildLanguagePicker(),
          if (result.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: result));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Advice copied to clipboard")),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildImageBanner(),
          Expanded(
            child: loading
                ? const Center(child: _LoadingWidget())
                : _buildDataDisplay(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePicker() {
    return DropdownButton<String>(
      value: selectedLanguage,
      underline: const SizedBox(),
      icon: Icon(Icons.translate, color: primaryColor),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() => selectedLanguage = newValue);
          _fetchAdvice();
        }
      },
      items: languages.map((String value) {
        return DropdownMenuItem(value: value, child: Text(value));
      }).toList(),
    );
  }

  Widget _buildImageBanner() {
    return Container(
      height: 220,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        image: DecorationImage(
          image: FileImage(widget.imageFile),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("DIAGNOSIS FOR:",
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            Text(
              widget.diseaseName.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataDisplay() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Markdown(
        data: result,
        physics: const BouncingScrollPhysics(),
        styleSheet: MarkdownStyleSheet(
          p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
          h1: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          h2: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          listBullet: const TextStyle(color: Colors.green, fontSize: 18),
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Color(0xFF2E7D32), strokeWidth: 3),
        const SizedBox(height: 20),
        Text("Consulting Digital Galla Mandi Expert...",
            style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
      ],
    );
  }
}