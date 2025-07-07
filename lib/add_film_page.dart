import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'film_model.dart';
import 'film_service.dart';

class AddFilmPage extends StatefulWidget {
  const AddFilmPage({super.key});

  @override
  State<AddFilmPage> createState() => _AddFilmPageState();
}

class _AddFilmPageState extends State<AddFilmPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _trailerUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> kategoriList = ['Sedang Tayang', 'Segera Tayang'];
  String? selectedKategori;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveFilm() async {
    if (!_formKey.currentState!.validate() || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data dan pilih gambar')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final newFilm = FilmModel(
        id: '',
        title: _titleController.text.trim(),
        category: selectedKategori ?? '',
        description: _descriptionController.text.trim(),
        imageBase64: base64Image,
        trailerUrl: _trailerUrlController.text.trim(),
      );

      await FilmService().addFilm(newFilm);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Film berhasil ditambahkan')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan film: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _trailerUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Film')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Film'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                value: selectedKategori,
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
                validator: (value) => value == null ? 'Pilih kategori terlebih dahulu' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi Film'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _trailerUrlController,
                decoration: const InputDecoration(labelText: 'Trailer URL'),
              ),
              const SizedBox(height: 12),
              _selectedImage == null
                  ? const Text('Belum ada gambar yang dipilih')
                  : Image.file(_selectedImage!, height: 200),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar'),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveFilm,
                      child: const Text('Simpan Film'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}