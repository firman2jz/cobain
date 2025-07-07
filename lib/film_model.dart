class FilmModel {
  final String id;
  final String title;
  final String category;
  final String imageBase64;
  final String description;
  final String trailerUrl;


  FilmModel({
    required this.id,
    required this.title,
    required this.category,
    required this.imageBase64,
      required this.description,
       required this.trailerUrl,

  });

  // Buat model dari Firestore
  factory FilmModel.fromMap(Map<String, dynamic> data, String documentId) {
    return FilmModel(
      id: documentId,  // ← Ambil ID dokumen Firestore
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      imageBase64: data['imageBase64'] ?? '',
      description: data['description'] ?? '',
      trailerUrl: data['trailerUrl'] ?? '',
    );
  }

  // Konversi ke map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'imageBase64': imageBase64,
      'description': description,
      'trailerUrl': trailerUrl,
    };
  }
}
