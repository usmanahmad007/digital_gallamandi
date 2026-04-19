import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../bottomTabs/sallerbottomTabs.dart';
import 'MapPicker.dart';

class StoreSettingsScreen extends StatefulWidget {
  final bool isFirstTime;
  const StoreSettingsScreen({super.key, this.isFirstTime = false});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();

  String? _logoUrl;
  String? _bgUrl;
  File? _pickedLogo;
  File? _pickedBg;
  bool _isLoading = false;

  // Track if user explicitly clicked 'Edit'
  bool _isUserEditing = false;

  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    if (!widget.isFirstTime) {
      _loadExistingData();
    } else {
      _isUserEditing = true;
    }
  }

  void _loadExistingData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('saller').doc(uid).get();
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['storeName'] ?? "";
          _descController.text = data['description'] ?? "";
          _addressController.text = data['address'] ?? "";
          _logoUrl = data['storeLogo'];
          _bgUrl = data['backgroundImage'];
          _lat = (data['latitude'] as num?)?.toDouble();
          _lng = (data['longitude'] as num?)?.toDouble();
        });
      }
    } catch (e) {
      debugPrint("Load error: $e");
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final String targetPath = p.join(tempDir.path, "${DateTime.now().millisecondsSinceEpoch}.jpg");
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path, targetPath, quality: 70, minWidth: 1024, minHeight: 1024,
    );
    return result != null ? File(result.path) : null;
  }

  Future<void> _pickImage(bool isLogo) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _isLoading = true);
      File? compressedFile = await _compressImage(File(pickedFile.path));
      setState(() {
        if (isLogo) { _pickedLogo = compressedFile; }
        else { _pickedBg = compressedFile; }
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    bool hasLogo = _pickedLogo != null || _logoUrl != null;
    bool hasBg = _pickedBg != null || _bgUrl != null;

    if (widget.isFirstTime && (!hasLogo || !hasBg)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Images are required!")));
      return;
    }

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      // 1. Fetch current status from Firestore to decide the new storeStatus
      DocumentSnapshot sellerDoc = await FirebaseFirestore.instance.collection('saller').doc(uid).get();
      Map<String, dynamic> currentData = sellerDoc.data() as Map<String, dynamic>? ?? {};

      bool isAdminApproved = currentData['isAdminApproved'] ?? false;
      bool isSellerRestricted = currentData['isSellerRestricted'] ?? false;

      // Logic:
      // If Approved and NOT Restricted -> set to 'pending' (Reviewing changes)
      // If NOT Approved and NOT Restricted -> keep 'editable'
      String newStoreStatus = 'editable';
      if (isAdminApproved == true && isSellerRestricted == false) {
        newStoreStatus = 'pending';
      } else if (isAdminApproved == false && isSellerRestricted == false) {
        newStoreStatus = 'editable';
      }

      String? finalLogo = _logoUrl;
      String? finalBg = _bgUrl;

      if (_pickedLogo != null) {
        var ref = FirebaseStorage.instance.ref().child('sallersStore/$uid/logo.jpg');
        await ref.putFile(_pickedLogo!, SettableMetadata(contentType: 'image/jpeg'));
        finalLogo = await ref.getDownloadURL();
      }
      if (_pickedBg != null) {
        var ref = FirebaseStorage.instance.ref().child('sallersStore/$uid/bg.jpg');
        await ref.putFile(_pickedBg!, SettableMetadata(contentType: 'image/jpeg'));
        finalBg = await ref.getDownloadURL();
      }

      // 2. Save data with the calculated storeStatus
      await FirebaseFirestore.instance.collection('saller').doc(uid).set({
        'storeName': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'address': _addressController.text.trim(),
        'latitude': _lat,
        'longitude': _lng,
        'storeLogo': finalLogo,
        'backgroundImage': finalBg,
        'hasSetupStore': true,
        'storeStatus': newStoreStatus, // 🔥 Dynamic Status
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (widget.isFirstTime) {
        Navigator.pushAndRemoveUntil(
            context, MaterialPageRoute(builder: (context) => const sallerBottomTabs()), (route) => false);
      } else {
        setState(() {
          _isUserEditing = false;
          _pickedBg = null;
          _pickedLogo = null;
        });
        _loadExistingData();

        // Dynamic SnackBar message
        String msg = newStoreStatus == 'pending'
            ? "Changes submitted for admin review!"
            : "Profile updated successfully!";

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      debugPrint("Save error: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPickerScreen()));
    if (result != null) {
      setState(() {
        _lat = result["lat"];
        _lng = result["lng"];
        _addressController.text = result["address"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('saller').doc(uid).snapshots(),
      builder: (context, snapshot) {
        bool canEditInDb = false;
        bool setupIncomplete = true;
        String lockMessage = "Profile Locked";

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          String status = (data['storeStatus'] ?? "").toString().toLowerCase();
          bool isAdminApproved = data['isAdminApproved'] == true;
          bool isRestricted = data['isSellerRestricted'] == true;
          bool hasSetupStore = data['hasSetupStore'] == true;

          setupIncomplete = !hasSetupStore;

          // --- STRICT CONDITION ---
          if (!hasSetupStore) {
            // Always allow editing for brand new accounts
            canEditInDb = true;
          } else {
            // ONLY allow editing if Approved AND NOT Restricted AND status is specifically 'editable'
            if (isAdminApproved && !isRestricted && status == "editable") {
              canEditInDb = true;
            }
          }

          // Dynamic lock messages for the user
          if (isRestricted) {
            lockMessage = "Account Restricted";
          } else if (!isAdminApproved && hasSetupStore) {
            lockMessage = "Waiting for Admin Approval";
          } else if (status != "editable" && hasSetupStore) {
            // This catches 'pending', 'rejected', or any other non-editable status
            lockMessage = "Profile is Under Review";
          }
        }

        // Final check: Fields are only interactive if (Allowed by DB AND User clicked Edit)
        // OR if the account hasn't been set up yet.
        bool fieldsAreEnabled = (canEditInDb && _isUserEditing) || setupIncomplete || widget.isFirstTime;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(setupIncomplete || widget.isFirstTime ? "Launch Store" : "Store Profile"),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0.5,
            foregroundColor: Colors.black,
            actions: [
              // Only show the edit toggle if the store is already setup and DB allows editing
              if (canEditInDb && !setupIncomplete && !widget.isFirstTime)
                IconButton(
                  icon: Icon(_isUserEditing ? Icons.close : Icons.edit, color: Colors.green),
                  onPressed: () {
                    setState(() {
                      _isUserEditing = !_isUserEditing;
                      if (!_isUserEditing) _loadExistingData();
                    });
                  },
                )
            ],
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                physics: !fieldsAreEnabled ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 250,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildCoverPhoto(!fieldsAreEnabled),
                            _buildFloatingLogo(!fieldsAreEnabled),
                          ],
                        ),
                      ),
                      const SizedBox(height: 50),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle("Shop Details"),
                            _buildStyledInput(
                                controller: _nameController,
                                label: "Store Name",
                                hint: "Enter brand name",
                                icon: Icons.storefront_rounded,
                                readOnly: !fieldsAreEnabled),
                            const SizedBox(height: 15),
                            _buildStyledInput(
                                controller: _descController,
                                label: "Tagline / Bio",
                                hint: "Short description",
                                icon: Icons.auto_awesome_outlined,
                                maxLines: 3,
                                readOnly: !fieldsAreEnabled),
                            const SizedBox(height: 25),
                            _sectionTitle("Store Location"),
                            _buildLocationSelector(!fieldsAreEnabled),
                            const SizedBox(height: 40),
                            if (fieldsAreEnabled) _buildSubmitButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Show Lock Overlay ONLY if not setup AND DB locks it
              if (!canEditInDb && !setupIncomplete && !widget.isFirstTime)
                _buildLockOverlay(lockMessage),

              if (_isLoading) _buildLoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockOverlay(String message) {
    return Container(
      color: Colors.white.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_rounded, size: 80, color: Colors.blueGrey[300]),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Text("Editing is disabled by our team. Please contact support to update your details.",
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
    // First, validate the form to ensure basic requirements are met
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Submit for Review?"),
          content: const Text(
              "Please make sure all information is correct. Once submitted, your profile will be locked until the admin approves the changes."
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _saveSettings(); // Proceed to actual save
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("SUBMIT", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  Widget _buildCoverPhoto(bool isLocked) {
    return GestureDetector(
      onTap: isLocked ? null : () => _pickImage(false),
      child: Container(
        height: 180, width: double.infinity, margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          image: _pickedBg != null ? DecorationImage(image: FileImage(_pickedBg!), fit: BoxFit.cover)
              : (_bgUrl != null ? DecorationImage(image: NetworkImage(_bgUrl!), fit: BoxFit.cover) : null),
        ),
        child: isLocked ? const Icon(Icons.lock, color: Colors.black12, size: 40)
            : (_pickedBg == null && _bgUrl == null ? const Icon(Icons.add_a_photo_outlined) : null),
      ),
    );
  }

  Widget _buildFloatingLogo(bool isLocked) {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Center(
        child: GestureDetector(
          onTap: isLocked ? null : () => _pickImage(true),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: CircleAvatar(
              radius: 50, backgroundColor: Colors.green[50],
              backgroundImage: _pickedLogo != null ? FileImage(_pickedLogo!)
                  : (_logoUrl != null ? NetworkImage(_logoUrl!) as ImageProvider : null),
              child: isLocked ? const Icon(Icons.lock, color: Colors.white)
                  : (_pickedLogo == null && _logoUrl == null ? const Icon(Icons.camera_alt) : null),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector(bool isLocked) {
    return Column(
      children: [
        _buildStyledInput(controller: _addressController, label: "Full Address", hint: "Pick from map...", icon: Icons.map_outlined, readOnly: true),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: isLocked ? null : _pickLocation,
          icon: const Icon(Icons.my_location, size: 18),
          label: const Text("Select Exact Location"),
          style: ElevatedButton.styleFrom(
            backgroundColor: isLocked ? Colors.grey[200] : Colors.white,
            foregroundColor: isLocked ? Colors.grey : Colors.green,
            elevation: 0, side: BorderSide(color: isLocked ? Colors.grey[300]! : Colors.green, width: 1.5),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Colors.green, Color(0xFF2E7D32)]),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        // 🔥 Changed from _saveSettings to _showConfirmationDialog
        onPressed: _showConfirmationDialog,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
        child: const Text("SAVE STORE PROFILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
  );

  Widget _buildLoadingOverlay() => Container(
    color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: Colors.green)),
  );

  Widget _buildStyledInput({required TextEditingController controller, required String label, required String hint, required IconData icon, int maxLines = 1, bool readOnly = false}) {
    return TextFormField(
      controller: controller, maxLines: maxLines, readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label, hintText: hint, prefixIcon: Icon(icon, color: readOnly ? Colors.grey : Colors.green),
        filled: true, fillColor: readOnly ? Colors.grey[100] : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[200]!)),
      ),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }
}