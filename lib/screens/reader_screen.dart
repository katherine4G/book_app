//lib/screens/reader_screen.dart
import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class ReaderScreen extends StatefulWidget {
  final String fullText;
  final String title;

  const ReaderScreen({super.key, required this.fullText, required this.title});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // El "ojo" que mira el scroll
  double _progreso = 0.0;
  late List<String> paragraphs;

  @override
  void initState() {
    super.initState();
    paragraphs = widget.fullText
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    // Escuchamos el movimiento del scroll
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        setState(() {
          // Calculamos el porcentaje (de 0.0 a 1.0)
          _progreso = (currentScroll / maxScroll).clamp(0.0, 1.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Limpieza para evitar fugas de memoria
    super.dispose();
  }

  // Lógica de IA corregida y limpia
  void _mostrarRespuestaIA(String pregunta) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.blueGrey),
      ),
    );

    // Simulemos una espera de 1 segundo para probar el scroll y el diálogo
    await Future.delayed(const Duration(seconds: 1));
    String respuestaSimulada =
        "¡El scroll ya debería funcionar! Estoy analizando '${widget.title}' para responderte sobre: $pregunta";

    if (!mounted) return;
    Navigator.pop(context); // Cierra el loading

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          "Tutor IA",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            respuestaSimulada, // <--- Ahora sí verás texto aquí
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Entendido",
              style: TextStyle(color: Colors.blueGrey),
            ),
          ),
        ],
      ),
    );
  }

  void _preguntarIA(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 25,
          right: 25,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "¿En qué te ayudo con este libro?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Ej: Resúmeme este capítulo...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E4E59),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  if (_controller.text.trim().isEmpty) return;
                  String q = _controller.text;
                  _controller.clear();
                  Navigator.pop(context);
                  _mostrarRespuestaIA(q);
                },
                child: const Text(
                  "Enviar consulta",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1E9),
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            Text(
              "${(_progreso * 100).toInt()}% leído", // Marcador de página
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE8E2D2),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3.0),
          child: LinearProgressIndicator(
            value: _progreso,
            backgroundColor: Colors.black12,
            color: const Color(0xFF3E4E59),
            minHeight: 3,
          ),
        ),
      ),
      body: Scrollbar(
        controller: _scrollController,
        interactive: true,
        thickness: 8,
        child: ListView.builder(
          controller: _scrollController, // Vinculamos el controlador
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          itemCount: paragraphs.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                paragraphs[index].trim(),
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.8,
                  fontFamily: 'Serif',
                  color: Color(0xFF2C2C2C),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF3E4E59),
        onPressed: () => _preguntarIA(context),
        label: const Text(
          "Tutor IA",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.psychology, color: Colors.white),
      ),
    );
  }
}
