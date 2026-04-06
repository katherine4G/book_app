class Book {
  final String title;
  final String authors;
  final String thumbnailUrl;
  final String description;
  final String source;
  final String infoUrl;

  Book({
    required this.title,
    required this.authors,
    required this.thumbnailUrl,
    required this.description,
    required this.source,
    required this.infoUrl,
  });

  // METODOS PARA HIVE (SERIALIZACIÓN)

  /// Convierte el objeto Book a un Map para guardarlo en Hive
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'authors': authors,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'source': source,
      'infoUrl': infoUrl,
    };
  }

  /// Crea un objeto Book desde un Map recuperado de Hive
  factory Book.fromMap(Map<dynamic, dynamic> map) {
    return Book(
      title: map['title'] ?? '',
      authors: map['authors'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      description: map['description'] ?? '',
      source: map['source'] ?? '',
      infoUrl: map['infoUrl'] ?? '',
    );
  }

  // ADAPTADORES DE LAS APIs (FACTORIES)

  // Adaptador para Google Books (Agregado para completar el set)
  factory Book.fromGoogleBooks(Map<String, dynamic> json) {
    final info = json['volumeInfo'] ?? {};
    final imageLinks = info['imageLinks'] ?? {};
    return Book(
      title: info['title'] ?? 'Sin título',
      authors: (info['authors'] as List?)?.join(', ') ?? 'Autor desconocido',
      thumbnailUrl: (imageLinks['thumbnail'] ?? '').replaceAll(
        'http://',
        'https://',
      ),
      description: info['description'] ?? 'Sin descripción.',
      source: 'GOOGLE_BOOKS',
      infoUrl: info['infoLink'] ?? '',
    );
  }

  // Adaptador para IT Bookstore
  factory Book.fromITBook(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? 'Sin título',
      authors: json['subtitle'] ?? 'Libro técnico',
      thumbnailUrl: json['image'] ?? '',
      description:
          "Libro técnico especializado. Usa la IA para explicar sus conceptos.",
      source: 'IT_BOOKSTORE',
      infoUrl: json['url'] ?? '',
    );
  }

  // Adaptador para Gutendex
  factory Book.fromGutendex(Map<String, dynamic> json) {
    final authorsList = json['authors'] as List? ?? [];
    return Book(
      title: json['title'] ?? 'Sin título',
      authors: authorsList.map((e) => e['name']).join(', '),
      thumbnailUrl: json['formats']?['image/jpeg'] ?? '',
      description: "Clásico literario. Disponible para Audiolibro e IA Tutor.",
      source: 'GUTENDEX',
      infoUrl: '', // Gutendex no siempre da una infoUrl directa
    );
  }

  // Adaptador para Open Library
  factory Book.fromOpenLibrary(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? 'Sin título',
      authors: "Varios autores",
      thumbnailUrl: json['cover_id'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover_id']}-M.jpg'
          : '',
      description: "Libro de la biblioteca abierta.",
      source: 'OPEN_LIBRARY',
      infoUrl: 'https://openlibrary.org${json['key']}',
    );
  }
}
