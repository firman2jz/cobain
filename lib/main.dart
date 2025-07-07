import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';

// Melakukan inisialisasi Flutter dan Firebase, lalu menjalankan aplikasi.
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();
  runApp(const MyApp());
}

// Merender tampilan berdasarkan status autentikasi (login atau tidak).
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

/// Menentukan apakah pengguna akan diarahkan ke halaman login atau home.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Jika user sudah login, arahkan ke halaman utama (home)
        if (snapshot.hasData && snapshot.data != null) {
          return const MovieMatePage();
        }
        // Jika user belum login, arahkan ke halaman login
        return const LoginPage();
      },
    );
  }
}
