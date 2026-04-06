class Book {
  final String title;
  final String authors;
  final String thumbnailUrl;
  final String description;
  final String source; // Para saber de dónde viene el libro
  final String infoUrl;

  Book({
    required this.title,
    required this.authors,
    required this.thumbnailUrl,
    required this.description,
    required this.source,
    required this.infoUrl,
  });

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

  // Adaptador para Gutendex (Clásicos)
  factory Book.fromGutendex(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? 'Sin título',
      authors: (json['authors'] as List).map((e) => e['name']).join(', '),
      thumbnailUrl:
          json['formats']['image/jpeg'] ?? 'https://via.placeholder.com/150',
      description: "Clásico literario. Disponible para Audiolibro e IA Tutor.",
      source: 'GUTENDEX',
      infoUrl: json['url'] ?? '',
    );
  }

  // Adaptador para Open Library
  factory Book.fromOpenLibrary(Map<String, dynamic> json) {
    return Book(
      title: json['title'] ?? 'Sin título',
      authors: "Varios autores",
      thumbnailUrl: json['cover_id'] != null
          ? 'https://covers.openlibrary.org/b/id/${json['cover_id']}-M.jpg'
          : 'https://via.placeholder.com/150',
      description: "Libro de la biblioteca abierta.",
      source: 'OPEN_LIBRARY',
      infoUrl: 'https://openlibrary.org${json['key']}',
    );
  }
}
