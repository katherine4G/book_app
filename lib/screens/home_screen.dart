import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../model/book.dart';
import '../services/book_service.dart';
import 'book_detail.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookService _bookService = BookService();
  final ScrollController _scrollController = ScrollController();
  final _cache = Hive.box('book_cache');

  final List<Book> _allBooks = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadMoreBooks();

    // Listener para detectar cuando llegamos al final
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.85) {
        if (!_isLoading) _loadMoreBooks();
      }
    });
  }

  Future<void> _loadMoreBooks() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final newBooks = await _bookService.fetchAllSources(page: _currentPage);
      setState(() {
        if (newBooks.isNotEmpty) {
          _allBooks.addAll(newBooks);
          _currentPage++;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = _allBooks
            .isEmpty; // Solo muestra error total si la lista está vacía
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'booKs',
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Limpiamos todo para forzar carga de red
          setState(() {
            _allBooks.clear();
            _currentPage = 1;
          });
          await _cache.delete('cached_books');
          await _loadMoreBooks();
        },
        child: _hasError
            ? _buildErrorWidget()
            : _allBooks.isEmpty && _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : _buildBookGrid(),
      ),
    );
  }

  Widget _buildBookGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _allBooks.length + (_isLoading ? 2 : 0),
      itemBuilder: (context, index) {
        if (index < _allBooks.length) {
          return _BookTile(book: _allBooks[index]);
        } else {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 70, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Error al conectar con las librerías'),
          ElevatedButton(
            onPressed: _loadMoreBooks,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: book.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        book.thumbnailUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _placeholder(book.title),
                      )
                    : _placeholder(book.title),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            book.authors,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(String title) {
    return Container(
      color: Colors.grey[850],
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0] : '?',
          style: const TextStyle(fontSize: 40, color: Colors.white24),
        ),
      ),
    );
  }
}
