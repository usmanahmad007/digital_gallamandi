import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class SafetyMeasuresScreen extends StatefulWidget {
  final String city;
  final double temperature;
  final double windSpeed;
  final String currentDate;

  const SafetyMeasuresScreen({super.key, 
    required this.city,
    required this.temperature,
    required this.windSpeed,
    required this.currentDate,
  });

  @override
  _SafetyMeasuresScreenState createState() => _SafetyMeasuresScreenState();
}

class _SafetyMeasuresScreenState extends State<SafetyMeasuresScreen> {
  late final GenerativeModel _model;
  String _response = "";
  bool isLoading = false;
  String displayText = "Fetching Current City";
  String? selectedProduct;
  TextEditingController customProductController = TextEditingController();

  final List<String> crops = [
    'rice', 'maize', 'jute', 'cotton', 'coconut', 'papaya', 'orange', 'apple',
    'muskmelon', 'watermelon', 'grapes', 'mango', 'banana', 'pomegranate',
    'lentil', 'blackgram', 'mungbean', 'mothbeans', 'pigeonpeas', 'kidneybeans',
    'chickpea', 'coffee', 'wheat', 'jowar', 'dates', 'garlic', 'pear',
    'soybean', 'sorghum', 'bajra', 'bitter gourd', 'barley', 'tobacco', 'tomato',
    'pulses', 'oilseeds', 'gram', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: 'AIzaSyDxpj15XzIo5P4WWAYATUVaoWiBccYDtvo',
    );
  }

  void _displayTextChange() {
    List<String> messages = [
      "Fetching Current City",
      "Fetching Current Temperature",
      "Fetching Current Wind Speed",
      "Fetching Current Date",
      "Loading Model...",
      "Please wait"
    ];

    int index = 0;

    void showNextMessage() {
      if (index < messages.length) {
        setState(() {
          displayText = messages[index];
        });
        index++;
        Future.delayed(const Duration(seconds: 1), showNextMessage);
      }
    }

    showNextMessage();
  }

  Future<void> _fetchSafetyMeasures() async {
    _displayTextChange();
    String productName = selectedProduct == "Other"
        ? customProductController.text
        : selectedProduct ?? "Unknown Crop";

    String prompt =
        "Considering the city of ${widget.city}, where the current temperature is ${widget.temperature}°C and the wind speed is ${widget.windSpeed} km/h, provide essential safety measures for agricultural workers handling $productName in the area. Include precautions related to machinery safety, pesticide handling, protective gear, weather-related risks (considering the current weather conditions), livestock safety, and injury prevention. Ensure the guidelines are tailored to the present weather conditions, which are as of ${widget.currentDate}. Provide practical, actionable safety practices to ensure worker safety in different agricultural settings.";

    setState(() {
      isLoading = true;
      _response = "Loading...";
    });

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      setState(() {
        _response = response.text?.replaceAll('*', '') ?? "Server Down, Please try Again later";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = "Error fetching response: $e";
        isLoading = false;
      });
    }
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select a Crop',
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: selectedProduct != null ? Colors.greenAccent.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
      initialValue: selectedProduct,
      items: crops.map((crop) {
        return DropdownMenuItem<String>(
          value: crop,
          child: Text(crop),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedProduct = value;
        });
      },
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      iconEnabledColor: Colors.green,
      validator: (value) {
        if (value == null) {
          return 'Please select a crop';
        }
        return null;
      },
    );
  }

  Widget _buildTextField() {
    return TextFormField(
      controller: customProductController,
      decoration: InputDecoration(
        labelText: "Enter custom crop name",
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(25),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(25),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width=MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text("Safety Measures")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownField(),
            const SizedBox(height: 20),
            if (selectedProduct == "Other") _buildTextField(),
            const SizedBox(height: 20),
            SizedBox(
              width: width*0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green,foregroundColor: Colors.white),
                onPressed: _fetchSafetyMeasures,
                child: const Text("Get Safety Measures"),
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? Center(
                  child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 10),
                  Text(displayText, style: const TextStyle(color: Colors.black)),
                                ],
                              ),
                )
                : Expanded(
              child: SingleChildScrollView(
                child: Text(isLoading == false ? _response : "", style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
