class CursorPage<T> {
  final List<T> items;
  final DateTime? nextCursor;

  CursorPage({required this.items, required this.nextCursor});
}
