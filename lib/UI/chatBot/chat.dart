import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:file_picker/file_picker.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _chatHistory = [];
  String? _file;
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'AIzaSyDNNyYTgn09z8hHXT2ISVUlbHpsfjkKTQQ'); // Replace with your API key
    _visionModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'AIzaSyDNNyYTgn09z8hHXT2ISVUlbHpsfjkKTQQ'); // Replace with your API key
    _chat = _model.startChat();
  }

  void getAnswer(String text) async {
    setState(() {
      _chatHistory.add({
        "time": DateTime.now(),
        "message": "Loading...", // Show loading state
        "isSender": false,
        "isImage": false,
        "isLoading": true, // New field to indicate loading
      });
    });

    late final GenerateContentResponse response;

    if (_file != null) {
      final firstImage = await File(_file!).readAsBytes();
      final prompt = TextPart(text);
      final imageParts = [DataPart('image/jpeg', firstImage)];

      response = await _visionModel.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);
      _file = null;
    } else {
      var content = Content.text(text);
      response = await _chat.sendMessage(content);
    }

    setState(() {
      _chatHistory.removeWhere((msg) => msg["isLoading"] == true); // Remove loading
      _chatHistory.add({
        "time": DateTime.now(),
        "message": response.text,
        "isSender": false,
        "isImage": false
      });
      _file = null;
    });

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chat",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 160,
            child: ListView.builder(
              itemCount: _chatHistory.length,
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                return Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Align(
                    alignment:
                    chat["isSender"] ? Alignment.topRight : Alignment.topLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                        color: chat["isSender"]
                            ? const Color(0xFFF69170)
                            : Colors.white,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: chat["isImage"]
                          ? Image.file(File(chat["message"]), width: 200)
                          : Text(
                        chat["message"],
                        style: TextStyle(
                          fontSize: 15,
                          color: chat["isSender"]
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: [
                  MaterialButton(
                    onPressed: () async {
                      FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['jpg', 'jpeg', 'png'],
                      );
                      if (result != null) {
                        setState(() {
                          _file = result.files.first.path;
                        });
                      }
                    },
                    minWidth: 42.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0)),
                    padding: const EdgeInsets.all(0.0),
                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 57, 182, 25),
                              Color.fromARGB(255, 255, 255, 255),
                            ]),
                        borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 42.0, minHeight: 36.0),
                        alignment: Alignment.center,
                        child: Icon(
                          _file == null ? Icons.image : Icons.check,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: "Type a message",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(8.0),
                          ),
                          controller: _chatController,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  MaterialButton(
                    onPressed: () {
                      setState(() {
                        if (_chatController.text.isNotEmpty || _file != null) {
                          if (_file != null) {
                            _chatHistory.add({
                              "time": DateTime.now(),
                              "message": _file,
                              "isSender": true,
                              "isImage": true,
                            });
                          }

                          if (_chatController.text.isNotEmpty) {
                            _chatHistory.add({
                              "time": DateTime.now(),
                              "message": _chatController.text,
                              "isSender": true,
                              "isImage": false,
                            });
                          }

                          _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent);
                          getAnswer(_chatController.text);
                          _chatController.clear();
                        }
                      });
                    },
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(80.0)),
                    padding: const EdgeInsets.all(0.0),

                    child: Ink(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 52, 209, 52),
                              Color.fromARGB(255, 255, 255, 255),
                            ]),
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                      child: Container(
                        constraints: const BoxConstraints(
                            minWidth: 88.0, minHeight: 36.0),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
