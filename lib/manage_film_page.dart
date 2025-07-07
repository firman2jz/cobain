import 'dart:convert';
import 'package:flutter/material.dart';
import 'film_service.dart';
import 'film_model.dart';
import 'edit_film_page.dart';
import 'add_film_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> isAdmin() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  return doc.data()?['role'] == 'admin';
}

class ManageFilmPage extends StatelessWidget {
  final FilmService filmService = FilmService();

  ManageFilmPage({super.key});

  Future<void> _confirmDelete(BuildContext context, String filmId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Apakah Anda yakin ingin menghapus film ini beserta dari semua koleksi user?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Tidak"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await filmService.deleteFilmEverywhere(filmId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Film berhasil dihapus dari semua tempat.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAdmin(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.data!) {
          return const Scaffold(
            body: Center(child: Text("Akses ditolak. Anda bukan admin.")),
          );
        }

        // Jika user adalah admin
        return Scaffold(
          appBar: AppBar(title: const Text('Kelola Semua Film')),
          body: StreamBuilder<List<FilmModel>>(
            stream: filmService.streamAllFilms(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final films = snapshot.data!;
              return ListView.builder(
                itemCount: films.length,
                itemBuilder: (context, index) {
                  final film = films[index];
                  return ListTile(
                    leading: Image.memory(
                      base64Decode(film.imageBase64),
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                    title: Text(film.title),
                    subtitle: Text(film.category),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditFilmPage(film: film),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, film.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddFilmPage()),
              );
            },
            child: const Icon(Icons.add),
            tooltip: 'Tambah Film Baru',
          ),
        );
      },
    );
  }
}