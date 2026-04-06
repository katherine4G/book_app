//lib/services/book_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../model/book.dart';

final logger = Logger();

class BookService {
  Future<List<Book>> fetchAllSources() async {
    List<Book> allBooks = [];

    try {
      // 1. Llamada a IT Bookstore (Libros de Flutter)
      final resIT = await http.get(
        Uri.parse('https://api.itbook.store/1.0/search/flutter'),
      );
      if (resIT.statusCode == 200) {
        final data = json.decode(resIT.body);
        allBooks.addAll(
          (data['books'] as List).map((item) => Book.fromITBook(item)),
        );
      }

      // 2. Llamada a Gutendex (Libros populares clásicos)
      final resGuten = await http.get(Uri.parse('https://gutendex.com/books/'));
      if (resGuten.statusCode == 200) {
        final data = json.decode(resGuten.body);
        allBooks.addAll(
          (data['results'] as List)
              .take(10)
              .map((item) => Book.fromGutendex(item)),
        );
      }

      // Nota: Open Library se puede usar igual con:
      // https://openlibrary.org/subjects/love.json?limit=10
    } catch (e) {
      logger.e("Error cargando fuentes: $e");
    }

    allBooks.shuffle(); // Mezclamos para que se vea variado tipo Netflix
    return allBooks;
  }
}
