import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:hive/hive.dart';
import '../model/book.dart';

final logger = Logger();

class BookService {
  final http.Client _client = http.Client();
  final _cache = Hive.box('book_cache');

  Future<List<Book>> fetchAllSources({int page = 1}) async {
    try {
      if (page == 1 && _cache.containsKey('cached_books')) {
        logger.i("Sirviendo desde el caché local...");
        final List cachedRaw = _cache.get('cached_books');
        return cachedRaw
            .map((e) => Book.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }

      logger.i("Cargando página $page de la red...");

      final results = await Future.wait(
        [
          _fetchGutendex(page), // Nuestra fuente principal (Libros reales)
          _fetchGoogleBooks(page), // Solo ayuda a rellenar si es necesario
          _fetchOpenLibrary(page),
          _fetchITBookstore(page),
        ],
      ).timeout(const Duration(seconds: 15), onTimeout: () => [[], [], [], []]);

      final List<Book> gutendexBooks = results[0];

      final List<Book> otherBooks = [
        ...results[1], // Google
        ...results[2], // OpenLib
        ...results[3], // IT
      ].where((b) => b.description.length > 100).toList();

      // 3. Unión con prioridad absoluta a Gutendex
      // Si quieres que NADA falle al leer, usa solo gutendexBooks
      final List<Book> allBooks = [...gutendexBooks, ...otherBooks];

      // 4. ELIMINAR DUPLICADOS Y LIMPIAR
      final ids = <String>{};
      final List<Book> cleanBooks = allBooks.where((b) {
        if (ids.contains(b.title.toLowerCase())) return false;
        ids.add(b.title.toLowerCase());
        // Solo mostrar si es de Gutendex (Lectura asegurada)
        // o si tiene potencial de ser leído
        return b.source == 'GUTENDEX';
      }).toList();

      if (page == 1 && cleanBooks.isNotEmpty) {
        final dataToCache = cleanBooks.map((b) => b.toMap()).toList();
        await _cache.put('cached_books', dataToCache);
      }

      return cleanBooks;
    } catch (e) {
      logger.e("Error crítico: $e");
      return [];
    }
  }

  // --- MÉTODOS AJUSTADOS PARA IDIOMA ---

  Future<List<Book>> _fetchGoogleBooks(int page) async {
    return _safeFetch("Google Books", () async {
      final int maxResults = 20;
      // Ajustamos la query 'q' para que sea más genérica pero en español
      final url = Uri.parse(
        'https://www.googleapis.com/books/v1/volumes?q=literatura+ficcion&maxResults=$maxResults&startIndex=${(page - 1) * maxResults}&langRestrict=es',
      );
      final res = await _client.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = data['items'] as List? ?? [];
        return items.map((item) => Book.fromGoogleBooks(item)).toList();
      }
      return [];
    });
  }

  Future<List<Book>> _fetchGutendex(int page) async {
    return _safeFetch("Gutendex", () async {
      // Subimos el timeout individual a 12s porque esta es tu fuente clave
      final res = await _client
          .get(Uri.parse('https://gutendex.com/books/?languages=es&page=$page'))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = data['results'] as List? ?? [];
        return items.map((item) => Book.fromGutendex(item)).toList();
      }
      return [];
    });
  }

  Future<List<Book>> _fetchOpenLibrary(int page) async {
    return _safeFetch("Open Library", () async {
      final int limit = 15;
      // Cambiamos el subject a uno que devuelva más contenido hispano
      final url = Uri.parse(
        'https://openlibrary.org/subjects/spanish_literature.json?limit=$limit&offset=${(page - 1) * limit}',
      );
      final res = await _client.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = data['works'] as List? ?? [];
        return items.map((item) => Book.fromOpenLibrary(item)).toList();
      }
      return [];
    });
  }

  Future<List<Book>> _fetchITBookstore(int page) async {
    return _safeFetch("IT Bookstore", () async {
      final res = await _client
          .get(Uri.parse('https://api.itbook.store/1.0/search/flutter/$page'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final items = data['books'] as List? ?? [];
        return items.map((item) => Book.fromITBook(item)).toList();
      }
      return [];
    }, retry: true);
  }

  Future<List<Book>> _safeFetch(
    String source,
    Future<List<Book>> Function() action, {
    bool retry = false,
  }) async {
    try {
      return await action();
    } on HandshakeException catch (_) {
      if (retry) {
        logger.w("Reintentando $source por fallo de Handshake...");
        await Future.delayed(const Duration(milliseconds: 500));
        return await _safeFetch(source, action, retry: false);
      }
    } on SocketException catch (e) {
      logger.w("$source sin conexión: $e");
    } on TimeoutException catch (_) {
      logger.w("$source tardó demasiado (Timeout)");
    } catch (e) {
      logger.w("$source falló: $e");
    }
    return [];
  }

  void dispose() {
    _client.close();
    logger.i("BookService cerrado.");
  }
}
