import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/EditProfileScreen.dart';
import 'package:zrai_mart/UI/signInScreen.dart';

import 'CustomGestureDetector.dart';

class Profilescreen extends StatefulWidget {
  const Profilescreen({super.key});

  @override
  State<Profilescreen> createState() => _ProfilescreenState();
}

class _ProfilescreenState extends State<Profilescreen> {
  bool light = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _name = 'Loading...';
  String _email = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          print(user.uid);
          setState(() {
            _name = userDoc['name'] ?? 'No name';
            _email = userDoc['email'] ?? 'No email';
          });
        } else {
          print(user.uid);

          setState(() {
            _name = 'No name';
            _email = 'No email';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _name = 'Error fetching name';
          _email = 'Error fetching email';
        });
      }
    }
  }

  void handleAddressTap() {
    print('Address tapped');
  }

  void handleNotificationTap() {
    print('Notification tapped');
  }

  void handlePaymentTap() {
    print('Payment tapped');
  }

  void handleSecurityTap() {
    print('Security tapped');
  }

  void handleLanguageTap() {
    print('Language tapped');
  }

  void handlePrivacyPolicyTap() {
    print('Privacy Policy tapped');
  }

  void handleHelpCenterTap() {
    print('Help Center tapped');
  }

  void handleInviteFriendsTap() {
    print('Invite Friends tapped');
  }

  void handleLogoutTap() {
    print('Logout tapped');
    _signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Signinscreen()),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signed out successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        title: Text("Profile"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 30),
            GestureDetector(
              onTap: () {},
              child: Stack(
                children: [
                  Center(
                    child: Image.asset("assets/img_2.png", width: 125, height: 125),
                  ),
                  Positioned(
                    top: 80,
                    left: 220,
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(Icons.edit),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(_email),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              height: 1,
              color: Colors.grey.withOpacity(0.3),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditProfileScreen()),
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
            CustomGestureDetector(
              leadingIcon: Icons.location_on_outlined,
              title: 'Address',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleAddressTap,
            ),
            CustomGestureDetector(
              leadingIcon: Icons.notifications_active,
              title: 'Notification',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleNotificationTap,
            ),
            CustomGestureDetector(
              leadingIcon: Icons.wallet,
              title: 'Payment',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handlePaymentTap,
            ),
            CustomGestureDetector(
              leadingIcon: Icons.security,
              title: 'Security',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleSecurityTap,
            ),
            CustomGestureDetector(
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
            CustomGestureDetector(
              leadingIcon: Icons.lock_outline,
              title: 'Privacy Policy',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handlePrivacyPolicyTap,
            ),
            CustomGestureDetector(
              leadingIcon: Icons.help_center_outlined,
              title: 'Help Center',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleHelpCenterTap,
            ),
            CustomGestureDetector(
              leadingIcon: Icons.person_add_alt_1_outlined,
              title: 'Invite Friends',
              trailingIcon: Icons.keyboard_arrow_right,
              onTap: handleInviteFriendsTap,
            ),
            CustomGestureDetector(
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
