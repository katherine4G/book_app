import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../model/book.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final Book book;
  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final FlutterTts flutterTts = FlutterTts();
  bool isPlaying = false;

  Future<void> _abrirLectorEspecial(BuildContext context, Book book) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    String? textoFinal;

    try {
      final response = await http.get(
        Uri.parse(
          'https://gutendex.com/books/?search=${Uri.encodeComponent(book.title)}',
        ),
      );
      final data = json.decode(response.body);

      // Verificamos antes de cerrar el Dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (data['results'] != null && data['results'].isNotEmpty) {
        Map<String, dynamic> formats = data['results'][0]['formats'];
        String? textUrl =
            formats['text/plain; charset=utf-8'] ?? formats['text/plain'];

        if (textUrl != null) {
          final textRes = await http.get(Uri.parse(textUrl));
          textoFinal = textRes.body;
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      debugPrint("Error: $e");
    }

    // Verificamos antes de navegar a la nueva pantalla
    if (!mounted) return;

    textoFinal ??= book.description;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ReaderScreen(fullText: textoFinal!, title: book.title),
      ),
    );
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("es-ES");
    if (isPlaying) {
      await flutterTts.stop();
      setState(() => isPlaying = false);
    } else {
      setState(() => isPlaying = true);
      await flutterTts.speak(text);
      flutterTts.setCompletionHandler(() => setState(() => isPlaying = false));
    }
  }

  void _showSubscriptionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        height: 250,
        child: Column(
          children: [
            const Icon(Icons.stars, color: Colors.amber, size: 40),
            const Text(
              "EXPERIENCIA PREMIUM",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Desbloquea Audiolibros e IA por solo \$4.99/mes.",
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Suscribirse ahora",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(
          widget.book.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.book.thumbnailUrl,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              widget.book.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.book.authors,
              style: const TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionStep(
                  icon: isPlaying ? Icons.stop : Icons.play_arrow,
                  label: "Escuchar",
                  color: const Color(0xFFE94560),
                  onTap: () => _speak(widget.book.description),
                ),
                _buildActionStep(
                  icon: Icons.psychology,
                  label: "IA Tutor",
                  color: const Color(0xFF0F3460),
                  onTap: () => _showSubscriptionModal(context),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // BOTÓN PRINCIPAL
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22A39F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                onPressed: () => _abrirLectorEspecial(context, widget.book),
                child: const Text(
                  "LEER LIBRO COMPLETO",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // BOTÓN DE FUENTE EXTERNA (Solo para libros de IT)
            if (widget.book.source == 'IT_BOOKSTORE')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton.icon(
                  onPressed: () async {
                    final url = Uri.parse(widget.book.infoUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 18,
                    color: Colors.blueGrey,
                  ),
                  label: const Text(
                    "Ver detalles en fuente externa",
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                  ),
                ),
              ),

            const SizedBox(height: 40),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SINOPSIS",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(color: Colors.white10),
            Text(
              widget.book.description,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildActionStep({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ],
    );
  }
}
