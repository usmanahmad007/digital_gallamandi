import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/Notification/Notification.dart';
import 'package:zrai_mart/UI/auth/signInScreen.dart';
import 'package:zrai_mart/saller%20center/profile/sallerEditProfileScreen.dart';

import '../customGestureDetector/sallerCustomGestureDetector.dart';
import 'HelpCenterScreen.dart';
import 'LanguageSelectionScreen.dart';
import 'PrivacyPolicyScreen.dart';

class sallerProfilescreen extends StatefulWidget {
  const sallerProfilescreen({super.key});

  @override
  State<sallerProfilescreen> createState() => _sallerProfilescreenState();
}

class _sallerProfilescreenState extends State<sallerProfilescreen> {
  bool light = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = 'Loading...';
  String _email = 'Loading...';
  var profileImageUrl;
  String Balance='0.0';


  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('saller').doc(user.uid).get();

        if (userDoc.exists) {
          print(user.uid);
          setState(() {
            _name = userDoc['name'] ?? 'No name';
            _email = userDoc['email'] ?? 'No email';
            profileImageUrl=userDoc['profileImage'];
            Balance= userDoc['balance'].toString() ?? '0.0';


          });
        } else {
          print(user.uid);

          setState(() {
            _name = 'No name';
            _email = 'No email';
            profileImageUrl=null;
            Balance= '0.0';


          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _name = 'Error fetching name';
          _email = 'Error fetching email';
          profileImageUrl=null;
          Balance= '0.0';


        });
      }
    }
  }


  void handleNotificationTap() {
    Navigator.push(context, MaterialPageRoute(builder: (context)=>NotificationScreen(userId: FirebaseAuth.instance.currentUser!.uid, isSeller: true,)));
  }

  void handleLanguageTap() {
    Navigator.push(context, MaterialPageRoute(builder: (context)=>const LanguageSelectionScreen()));

  }

  void handlePrivacyPolicyTap() {
      Navigator.push(context, MaterialPageRoute(builder: (context)=>const PrivacyPolicyScreen()));

  }

  void handleHelpCenterTap() {
    Navigator.push(context, MaterialPageRoute(builder:(context)=>const HelpCenterScreen()));
  }



  void handleLogoutTap() {
    print('Logout tapped');
    _signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Signinscreen()),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signed out successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Profile"),
            Row(
              children: [
                const Text('PKR: '),

                Text(Balance.toString()),
              ],
            )
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            CircleAvatar(
              radius: 60,
              backgroundImage: profileImageUrl != null
                  ? NetworkImage(profileImageUrl!)
                  : const AssetImage('assets/img_2.png') as ImageProvider,
            ),
            Text(
              _name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(_email),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const sallerEditProfileScreen()),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.person),
                trailing: Icon(
                  Icons.keyboard_arrow_right,
                ),
                title: Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            sallerCustomGestureDetector(
              leadingIcon: Icons.notifications_active,
              title: 'Notification',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleNotificationTap,
            ),

            sallerCustomGestureDetector(
              leadingIcon: Icons.language,
              title: 'Language',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleLanguageTap,
            ),
            /*ListTile(
              leading: Icon(Icons.remove_red_eye_outlined),
              trailing: Switch(
                value: light,
                activeColor: Colors.green,
                onChanged: (bool value) {
                  setState(() {
                    light = value;
                  });
                },
              ),
              title: Text(
                'Dark Mode',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),*/

            sallerCustomGestureDetector(
              leadingIcon: Icons.lock_outline,
              title: 'Privacy Policy',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handlePrivacyPolicyTap,
            ),
            sallerCustomGestureDetector(
              leadingIcon: Icons.help_center_outlined,
              title: 'Help Center',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleHelpCenterTap,
            ),

            sallerCustomGestureDetector(
              leadingIcon: Icons.exit_to_app,
              leadingIconColor: Colors.red,
              title: 'Logout',
              titleColor: Colors.red,
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleLogoutTap,
            ),
          ],
        ),
      ),
    );
  }
}
