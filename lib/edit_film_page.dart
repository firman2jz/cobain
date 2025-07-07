import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'film_model.dart';

class EditFilmPage extends StatefulWidget {
  final FilmModel film;

  const EditFilmPage({super.key, required this.film});

  @override
  State<EditFilmPage> createState() => _EditFilmPageState();
}

class _EditFilmPageState extends State<EditFilmPage> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;

  final List<String> kategoriList = ['Sedang Tayang', 'Segera Tayang'];
  String? selectedKategori;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.film.title);
    descriptionController = TextEditingController(text: widget.film.description);
    selectedKategori = widget.film.category;
  }

  Future<void> updateFilm() async {
    if (titleController.text.trim().isEmpty ||
        selectedKategori == null ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua data wajib diisi')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('films')
        .doc(widget.film.id)
        .update({
      'title': titleController.text.trim(),
      'category': selectedKategori,
      'description': descriptionController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Film berhasil diupdate')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Film')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Judul'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedKategori,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: kategoriList.map((kategori) {
                return DropdownMenuItem<String>(
                  value: kategori,
                  child: Text(kategori),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedKategori = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateFilm,
              child: const Text('Update Film'),
            ),
          ],
        ),
      ),
    );
  }
}
