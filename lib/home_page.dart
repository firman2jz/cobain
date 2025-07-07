import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'film_service.dart';
import 'film_model.dart';
import 'login_page.dart';
import 'film_detail_page.dart';
import 'collection_page.dart';
import 'user_service.dart';
import 'manage_film_page.dart';
import 'profile_tab.dart';

class MovieMatePage extends StatefulWidget {
  const MovieMatePage({super.key});

  @override
  State<MovieMatePage> createState() => _MovieMatePageState();
}

class _MovieMatePageState extends State<MovieMatePage> {
  int currentIndex = 0;
  String userRole = 'user';
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    final role = await _userService.getUserRole();
    setState(() {
      userRole = role ?? 'user';
    });
  }

  final TextEditingController homeSearchController = TextEditingController();
  final FilmService _filmService = FilmService();

  Widget buildFilmGrid(List<FilmModel> films) {
    if (films.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("Film tidak ditemukan."),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: films.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.6,
        ),
        itemBuilder: (context, index) {
          final film = films[index];
          final imageWidget = film.imageBase64.isNotEmpty
              ? Image.memory(base64Decode(film.imageBase64), fit: BoxFit.cover)
              : Image.asset('assets/placeholder.jpg', fit: BoxFit.cover);

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FilmDetailPage(film: film)),
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageWidget,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  film.title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

 Widget buildHomeTab() {
  final query = homeSearchController.text.toLowerCase();

  return Column(
    children: [
      // Banner tetap
      Image.asset('assets/banner.png', width: double.infinity, height: 180, fit: BoxFit.cover),

      // TextField dikeluarkan dari StreamBuilder
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: TextField(
          controller: homeSearchController,
          decoration: InputDecoration(
            hintText: 'Cari film...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (_) {
            setState(() {}); // hanya untuk rebuild bagian list
          },
        ),
      ),

      // StreamBuilder untuk film di bawah TextField
      Expanded(
        child: StreamBuilder<List<FilmModel>>(
          stream: _filmService.streamAllFilms(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada film yang ditemukan.'));
            }

            final films = snapshot.data!;
            final filteredFilms = films.where((film) =>
              film.title.toLowerCase().contains(query)
            ).toList();

            final segeraTayang = filteredFilms
                .where((film) => film.category.toLowerCase() == 'segera tayang')
                .toList();

            final sedangTayang = filteredFilms
                .where((film) => film.category.toLowerCase() == 'sedang tayang')
                .toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (segeraTayang.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('Segera Tayang',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    buildFilmGrid(segeraTayang),
                  ],
                  if (sedangTayang.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Text('Sedang Tayang',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    buildFilmGrid(sedangTayang),
                  ],
                  if (segeraTayang.isEmpty && sedangTayang.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Film tidak ditemukan.')),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}


  Widget buildSavedTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text("Anda belum login."));
    }

    return StreamBuilder<List<FilmModel>>(
      stream: _filmService.streamSavedFilms(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tidak ada film yang disimpan.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: buildFilmGrid(snapshot.data!),
        );
      },
    );
  }

  Widget buildProfileTab() {
    return const ProfileTab();
  }

  Widget buildBody() {
    if (currentIndex == 0) return buildHomeTab();
    if (currentIndex == 1) return CollectionPage();
    return buildProfileTab();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cinevo'),
        actions: [
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ManageFilmPage()),
                );
              },
            ),
        ],
      ),
      body: buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Koleksi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
