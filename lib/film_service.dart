import 'package:cloud_firestore/cloud_firestore.dart';
import 'film_model.dart';

class FilmService {
  final _filmRef = FirebaseFirestore.instance.collection('films');

  // Ambil film berdasarkan kategori
  Future<List<FilmModel>> getFilmsByCategory(String category) async {
    try {
      final querySnapshot = await _filmRef.where('category', isEqualTo: category).get();
      return querySnapshot.docs.map((doc) {
        return FilmModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print("Error getting films: $e");
      return [];
    }
  }

  // Stream film berdasarkan kategori
  Stream<List<FilmModel>> streamFilmsByCategory(String category) {
    return _filmRef.where('category', isEqualTo: category).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) {
        return FilmModel.fromMap(doc.data(), doc.id);
      }).toList(),
    );
  }

  // Tambah film ke koleksi umum
  Future<void> addFilm(FilmModel film) async {
    try {
      await _filmRef.add({
        'title': film.title,
        'category': film.category,
        'description': film.description,
        'imageBase64': film.imageBase64,
        'trailerUrl': film.trailerUrl, // Ditambahkan trailerUrl
      });
    } catch (e) {
      print('Error menambahkan film: $e');
      rethrow;
    }
  }

  Future<void> deleteFilmEverywhere(String filmId) async {
    final usersRef = FirebaseFirestore.instance.collection('users');

    try {
      await _filmRef.doc(filmId).delete();

      final usersSnapshot = await usersRef.get();
      for (var userDoc in usersSnapshot.docs) {
        final savedFilmRef = usersRef.doc(userDoc.id).collection('saved_films').doc(filmId);
        final savedFilmDoc = await savedFilmRef.get();
        if (savedFilmDoc.exists) {
          await savedFilmRef.delete();
        }
      }

      print("Film dan semua salinannya berhasil dihapus.");
    } catch (e) {
      print("Error saat menghapus film dari semua tempat: $e");
      rethrow;
    }
  }

  // Stream film yang disimpan oleh user
  Stream<List<FilmModel>> streamSavedFilms(String userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('saved_films')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return FilmModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Stream semua film (untuk admin)
  Stream<List<FilmModel>> streamAllFilms() {
    return _filmRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FilmModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

Future<void> addReview(String filmId, String userId, String username, String content) async {
  final reviewRef = FirebaseFirestore.instance
      .collection('films')
      .doc(filmId)
      .collection('reviews')
      .doc();

  await reviewRef.set({
    'id': reviewRef.id,
    'userId': userId,
    'username': username, // ← ganti dari userEmail
    'content': content,
    'timestamp': FieldValue.serverTimestamp(),
  });
}



Stream<List<Map<String, dynamic>>> streamReviews(String filmId) {
  return FirebaseFirestore.instance
      .collection('films')
      .doc(filmId)
      .collection('reviews')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id; // pastikan ID dokumen selalu diikutkan di hasil stream
            return data;
          }).toList());
}


}
