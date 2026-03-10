import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CityNameApp extends StatefulWidget {
  const CityNameApp({super.key});

  @override
  _CityNameAppState createState() => _CityNameAppState();
}

class _CityNameAppState extends State<CityNameApp> {
  String? selectedCity;
  Map<String, dynamic>? jsonData;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestStoragePermission();
  }

  // List of cities in Pakistan (without provinces)
  final List<String> cities = [
    'Lahore',
    'Faisalabad',
    'Rawalpindi',
    'Multan',
    'Gujranwala',
    'Sialkot',
    'Bahawalpur',
    'Sargodha',
    'Sheikhupura',
    'Gujrat',
    'Kasur',
    'Rahim Yar Khan',
    'Sahiwal',
    'Okara',
    'Jhelum',
    'Mianwali',
    'Dera Ghazi Khan',
    'Chakwal',
    'Narowal',
    'Attock',
    'Islamabad',
    'Gilgit',
    'Skardu',
    'Hunza',
    'Ghizer',
    'Ghanche',
    'Nagar',
    'Muzaffarabad',
    'Mirpur',
    'Kotli',
    'Bhimber',
    'Bagh',
    'Rawalakot',
    'Sudhanoti',
    'Peshawar',
    'Abbottabad',
    'Mardan',
    'Swat (Mingora)',
    'Kohat',
    'Dera Ismail Khan',
    'Charsadda',
    'Mansehra',
    'Bannu',
    'Nowshera',
    'Karachi',
    'Hyderabad',
    'Sukkur',
    'Larkana',
    'Nawabshah (Shaheed Benazirabad)',
    'Mirpurkhas',
    'Khairpur',
    'Jacobabad',
    'Shikarpur',
    'Quetta',
    'Gwadar',
    'Turbat',
    'Khuzdar',
    'Sibi',
    'Chaman',
    'Zhob',
    'Panjgur',
  ];

  Future<void> readJsonResult() async {
    try {
      final path = await getPublicDirectory();
      final file = File('$path/filename.json');

      if (file.existsSync()) {
        final data = await file.readAsString();

        if (data.isEmpty) {
          setState(() {
            jsonData = {"error": "JSON file is empty!"};
          });
          return;
        }

        setState(() {
          jsonData = json.decode(data);
        });
      } else {
        setState(() {
          jsonData = {"error": "JSON file not found!"};
        });
      }
    } catch (e) {
      setState(() {
        jsonData = {"error": "Error reading file: $e"};
      });
    }
  }

  Future<void> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Storage permission is required to access files.")),
      );
       _requestStoragePermission();
    }
  }


  Future<String> getPublicDirectory() async {
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      String path = directory.path.split('Android')[0];
      return "$path/CityFiles";
    }
    throw Exception("Unable to get public directory");
  }

  Future<void> writeCityName(String city) async {
    try {
      _requestStoragePermission();
      final path = await getPublicDirectory();
      final directory = Directory(path);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }
      final file = File('$path/city.txt');
      await file.writeAsString(city);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("City name '$city' saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error writing file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recommendation Crops"),backgroundColor: Colors.green,foregroundColor: Colors.white,),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select a City",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      initialValue: selectedCity,
                      items: cities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),

                      onChanged: (value) {
                        setState(() {
                          selectedCity = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selectedCity != null
                  ? () => writeCityName(selectedCity!)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Save Selected City"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: readJsonResult,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Load JSON Result"),
            ),
            const SizedBox(height: 20),
            if (jsonData != null)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.9, // Fix width division
                child: Card(
                  color: jsonData!.containsKey('error') ? Colors.red[100] : Colors.green[100],
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: jsonData!.containsKey('error')
                        ? Text(
                      jsonData!['error'],
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    )
                        : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Recommended Crops:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (jsonData!.containsKey('recommended_crops') && jsonData!['recommended_crops'] != null)
                          ...List.generate(
                            jsonData!['recommended_crops'].length,
                                (index) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.asset(
                                          'assets/Images/Seasonal Crops/${jsonData!['recommended_crops'][index]}.jpg',
                                          width: 150,
                                          height: 200,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Image.asset(
                                                'assets/Images/Seasonal Crops/${jsonData!['recommended_crops'][index]}.jfif',
                                                width: 150,
                                                height: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Image.asset(

                                                      'assets/Images/Seasonal Crops/${jsonData!['recommended_crops'][index]}.jpeg',
                                                      width: 150,
                                                      height: 200,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) =>
                                                          Image.asset(
                                                            'assets/Images/RecomendationCrops/${jsonData!['recommended_crops'][index]}.jpg',
                                                            width: 150,
                                                            height: 200,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) =>
                                                                const Icon(Icons.image, size: 150, color: Colors.grey),
                                                          ),
                                                    ),
                                              ),
                                        ),
                                      ),
                                      Text(" ${jsonData!['recommended_crops'][index]}",style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold,fontSize: 22),),
                                    ],
                                  ),
                                ),
                          )
                        else
                          const Text("No recommended crops available."),
                        const SizedBox(height: 10),
                        if (jsonData!.containsKey('temperature'))
                          Text(
                            "Temperature: ${jsonData!['temperature']}°C",
                            style: const TextStyle(fontSize: 16),
                          ),
                        if (jsonData!.containsKey('humidity'))
                          Text(
                            "Humidity: ${jsonData!['humidity']}%",
                            style: const TextStyle(fontSize: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}

