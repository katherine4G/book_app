//lib/main.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'model/book.dart';
import 'screens/book_detail.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Book>> fetchBooks() async {
    List<Book> allBooks = [];

    try {
      // 1. Traer de IT Bookstore (Tecnología)
      final itRes = await http.get(
        Uri.parse('https://api.itbook.store/1.0/search/flutter'),
      );
      if (itRes.statusCode == 200) {
        final data = json.decode(itRes.body);
        allBooks.addAll(
          (data['books'] as List).take(8).map((i) => Book.fromITBook(i)),
        );
      }

      // 2. Traer de Gutendex (Clásicos)
      final gutRes = await http.get(Uri.parse('https://gutendex.com/books/'));
      if (gutRes.statusCode == 200) {
        final data = json.decode(gutRes.body);
        allBooks.addAll(
          (data['results'] as List).take(8).map((i) => Book.fromGutendex(i)),
        );
      }

      // 3. Traer de Open Library (Ficción/Varios)
      final olRes = await http.get(
        Uri.parse('https://openlibrary.org/subjects/fiction.json?limit=8'),
      );
      if (olRes.statusCode == 200) {
        final data = json.decode(olRes.body);
        allBooks.addAll(
          (data['works'] as List).map((i) => Book.fromOpenLibrary(i)),
        );
      }

      allBooks.shuffle(); // Mezclar como Netflix para que sea variado
      return allBooks;
    } catch (e) {
      debugPrint("Error mezclando APIs: $e");
      return allBooks; // Si algo falla, devuelve lo que haya alcanzado a cargar
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BOOKFLIX'), centerTitle: true),
      body: FutureBuilder<List<Book>>(
        future: fetchBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final books = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Dos columnas
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BookDetailScreen(book: books[index]),
                    ),
                  );
                },
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          books[index].thumbnailUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      books[index].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
