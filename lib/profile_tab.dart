import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';
import 'ubah_password_page.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> openFAQ() async {
    const faqUrl = 'https://cinevo.rf.gd/';
    final uri = Uri.parse(faqUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<Map<String, dynamic>> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return {
      'username': doc.data()?['username'] ?? 'Tidak diketahui',
      'role': doc.data()?['role'] ?? 'user',
      'email': user.email ?? 'Tanpa Email',
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getUserData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final username = data['username'];
        final email = data['email'];
        final role = data['role'];

        return Scaffold(
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Center(
                child: Column(
                  children: const [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 60, color: Colors.white),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),

              // Nama Pengguna
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text("Nama"),
                subtitle: Text(username),
              ),
              const Divider(),

              // Email
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text("Email"),
                subtitle: Text(email),
              ),
              const Divider(),

              // Role
              ListTile(
                leading: const Icon(Icons.verified_user),
                title: const Text("Role"),
                subtitle: Text(role == 'admin' ? 'Admin' : 'User'),
              ),
              const Divider(),

              // Bantuan
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text("Bantuan (FAQ)"),
                onTap: openFAQ,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const Divider(),
 
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text("Ubah Password"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
                  );
                },
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const Divider(),


              const SizedBox(height: 24),

              // Tombol Logout
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      return AlertDialog(
                        title: const Text("Konfirmasi"),
                        content: Text("Apakah Anda yakin ingin keluar dari akun $username?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop();
                              await signOut(context);
                            },
                            child: const Text("Ya, Keluar"),
                          ),
                        ],
                      );
                    },
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text("Keluar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
