class PaginatedResult<T> {
  final List<T> items;
  final dynamic lastDocument;
  final bool hasMore;

  const PaginatedResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });
}
