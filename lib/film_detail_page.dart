import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'film_model.dart';
import 'film_service.dart';

class FilmDetailPage extends StatefulWidget {
  final FilmModel film;
  final bool isFromCollection;

  const FilmDetailPage({
    super.key,
    required this.film,
    this.isFromCollection = false,
  });

  @override
  State<FilmDetailPage> createState() => _FilmDetailPageState();
}

class _FilmDetailPageState extends State<FilmDetailPage> {
  final TextEditingController reviewController = TextEditingController();

  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    fetchLikeStatus();
  }

  Future<void> fetchLikeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likeDoc = await FirebaseFirestore.instance
        .collection('films')
        .doc(widget.film.id)
        .collection('likes')
        .doc(user.uid)
        .get();

    final likesSnapshot = await FirebaseFirestore.instance
        .collection('films')
        .doc(widget.film.id)
        .collection('likes')
        .get();

    setState(() {
      isLiked = likeDoc.exists;
      likeCount = likesSnapshot.size;
    });
  }

  Future<void> toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likeRef = FirebaseFirestore.instance
        .collection('films')
        .doc(widget.film.id)
        .collection('likes')
        .doc(user.uid);

    if (isLiked) {
      await likeRef.delete();
    } else {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
    }

    fetchLikeStatus();
  }

  Future<void> saveFilmToCollection(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_films')
          .doc(widget.film.id)
          .set({
        'title': widget.film.title,
        'description': widget.film.description,
        'imageBase64': widget.film.imageBase64,
        'category': widget.film.category,
        'trailerUrl': widget.film.trailerUrl,
        'savedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Film berhasil disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _launchTrailer(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka URL Trailer')),
      );
    }
  }

  Future<void> addReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || reviewController.text.trim().isEmpty) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final username = userDoc.data()?['username'] ?? 'Pengguna';

    await FilmService().addReview(
      widget.film.id,
      user.uid,
      username,
      reviewController.text.trim(),
    );

    reviewController.clear();
  }

  Widget buildReviewInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: reviewController,
            decoration: const InputDecoration(
              hintText: 'Tulis ulasan...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: addReview,
        ),
      ],
    );
  }

  Widget buildReviewList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FilmService().streamReviews(widget.film.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!;
        if (reviews.isEmpty) return const Text("Belum ada ulasan.");

        final user = FirebaseAuth.instance.currentUser;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            final timestamp = (review['timestamp'] as Timestamp?)?.toDate();
            final isOwner = user != null && user.uid == review['userId'];

            return GestureDetector(
              onLongPress: isOwner
                  ? () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Hapus Ulasan'),
                          content: const Text('Yakin ingin menghapus ulasan ini?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('films')
                            .doc(widget.film.id)
                            .collection('reviews')
                            .doc(review['id'])
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ulasan berhasil dihapus.')),
                        );
                      }
                    }
                  : null,
              child: ListTile(
                leading: const Icon(Icons.person),
                title: Text(review['username'] ?? 'Pengguna'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['content']),
                    if (timestamp != null)
                      Text("${timestamp.day}-${timestamp.month}-${timestamp.year} "
                          "${timestamp.hour}:${timestamp.minute}"),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.film.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(widget.film.imageBase64),
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.film.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategori: ${widget.film.category}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Deskripsi:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(widget.film.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            if (widget.isFromCollection)
              const Chip(
                label: Text('Sudah disimpan', style: TextStyle(color: Colors.white)),
                backgroundColor: Colors.green,
              ),
            const SizedBox(height: 16),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!widget.isFromCollection)
                    ElevatedButton.icon(
                      onPressed: () => saveFilmToCollection(context),
                      icon: const Icon(Icons.bookmark),
                      label: const Text("Simpan"),
                    ),
                  if (!widget.isFromCollection) const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: widget.film.trailerUrl.isNotEmpty
                        ? () => _launchTrailer(context, widget.film.trailerUrl)
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text("Trailer"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 👍 Tombol Like
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.thumb_up,
                    color: isLiked ? Colors.blue : Colors.grey,
                  ),
                  onPressed: toggleLike,
                ),
                Text('$likeCount suka'),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Ulasan Pengguna:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            buildReviewInput(),
            const SizedBox(height: 8),
            buildReviewList(),
          ],
        ),
      ),
    );
  }
}
