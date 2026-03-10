import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State {
  String selectedLanguage = 'English'; // Default language

  @override
  Widget build(BuildContext context) {
    String? selectedOption = 'English';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [



              const SizedBox(height: 16),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black
                  )
                ),

                child: ListTile(
                  title: const Text('English'),
                  leading: Radio<String>(
                    value: 'English',
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}