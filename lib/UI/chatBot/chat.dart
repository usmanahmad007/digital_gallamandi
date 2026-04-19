import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Changed to image_picker
import 'chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final ChatService _service = ChatService();
  final ImagePicker _picker = ImagePicker(); // Initialize picker

  File? _selectedFile;
  bool _isTyping = false;
  bool _isPickerActive = false; // Prevents the PlatformException
  String? _selectedLanguage;

  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color accentGreen = Color(0xFFE8F5E9);
  static const Color background = Color(0xFFF4F7F4);

  // Function to pick image safely
  Future<void> _pickImage(ImageSource source) async {
    if (_isPickerActive) return;

    setState(() => _isPickerActive = true);
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Optimizes image for faster AI processing
      );

      if (pickedFile != null) {
        setState(() => _selectedFile = File(pickedFile.path));
      }
    } finally {
      setState(() => _isPickerActive = false);
    }
  }

  // Modern Bottom Sheet for Image Selection
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select Image Source", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: accentGreen, child: Icon(Icons.camera_alt, color: primaryGreen)),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: accentGreen, child: Icon(Icons.photo_library, color: primaryGreen)),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _setLanguage(String lang) {
    setState(() {
      _selectedLanguage = lang;
      String greeting = lang == "Urdu"
          ? "اسلام علیکم! میں آپ کی کیسے مدد کر سکتا ہوں؟"
          : lang == "Russian" ? "Здравствуйте! Чем я могу вам помочь?" : "Hello! How can I help you today?";
      _messages.add({"msg": greeting, "isMe": false, "isImg": false});
    });
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    final tempFile = _selectedFile;
    setState(() {
      if (tempFile != null) _messages.add({"msg": tempFile.path, "isMe": true, "isImg": true});
      if (text.isNotEmpty) _messages.add({"msg": text, "isMe": true, "isImg": false});
      _isTyping = true;
      _controller.clear();
      _selectedFile = null;
    });
    _scrollToBottom();

    final response = await _service.getResponse(text, tempFile, _selectedLanguage!);

    setState(() {
      _isTyping = false;
      _messages.add({"msg": response ?? "No response", "isMe": false, "isImg": false});
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Agri-Bot", style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
        actions: [
          if (_selectedLanguage != null)
            IconButton(
              icon: const Icon(Icons.translate),
              onPressed: () => setState(() => _selectedLanguage = null),
            )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, background],
          ),
        ),
        child: _selectedLanguage == null ? _buildLanguageSelector() : _buildChatArea(),
      ),
    );
  }

  // ... (Keep _buildLanguageSelector and _langCard same as your previous code) ...

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: accentGreen, shape: BoxShape.circle),
            child: const Icon(Icons.psychology_outlined, size: 80, color: primaryGreen),
          ),
          const SizedBox(height: 24),
          const Text("Choose your language",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Text("آپ کی زبان کا انتخاب کریں",
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 40),
          _langCard("English", "🇺🇸", "Standard Support"),
          _langCard("Urdu", "🇵🇰", "مقامی مدد"),
          _langCard("Russian", "🇷🇺", "Русская поддержка"),
          const Spacer(),

          // --- PROPER PRIVACY MESSAGE ---
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: primaryGreen.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Text(
                    "End-to-End Privacy Guaranteed",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Your conversations are temporary and are not saved on our servers.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "آپ کا ڈیٹا کہیں بھی محفوظ نہیں کیا جاتا۔",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontFamily: 'UrduFont', // If you have a specific Urdu font
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _langCard(String title, String flag, String sub) {
    return GestureDetector(
      onTap: () => _setLanguage(title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 30)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: primaryGreen),
          ],
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: _messages.length,
            itemBuilder: (context, i) => _buildBubble(_messages[i]),
          ),
        ),
        if (_isTyping)
          const Padding(
            padding: EdgeInsets.only(left: 24, bottom: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text("Bot is analyzing...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))),
          ),
        _buildModernInput(),
      ],
    );
  }

  Widget _buildBubble(Map<String, dynamic> m) {
    bool isMe = m["isMe"];
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMe ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: m["isImg"]
            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(m["msg"])))
            : Text(m["msg"], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16, height: 1.4)),
      ),
    );
  }

  Widget _buildModernInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedFile != null)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(image: FileImage(_selectedFile!), fit: BoxFit.cover)),
                child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.white),
                        onPressed: () => setState(() => _selectedFile = null))),
              ),
            Row(
              children: [
                GestureDetector(
                  onTap: _showImageSourceOptions, // Calls the Bottom Sheet
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: accentGreen, borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.camera_alt_rounded, color: primaryGreen),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Ask anything...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: primaryGreen, blurRadius: 8, offset: Offset(0, 3))]
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}