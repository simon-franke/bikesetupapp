/// Keeps ordered local edits visible until persistence confirms them.
/// A failed older edit never replaces a newer edit still waiting to save.
class OptimisticEdits<K, V> {
  final _fields = <K, _Field<V>>{};
  Iterable<K> get keys => _fields.keys;

  Object begin(K key, V? previous, V value) {
    final field = _fields.putIfAbsent(key, () => _Field(previous));
    final token = Object();
    field.pending.add((token, value));
    return token;
  }

  void complete(K key, Object token, {required bool success}) {
    final field = _fields[key];
    if (field == null) return;
    final edit =
        field.pending.where((entry) => identical(entry.$1, token)).firstOrNull;
    if (edit == null) return;
    if (success) field.confirmed = edit.$2;
    field.pending.remove(edit);
  }

  V? resolve(K key, V? remote) {
    final field = _fields[key];
    if (field == null) return remote;
    if (field.pending.isNotEmpty) return field.pending.last.$2;
    if (remote == field.confirmed) _fields.remove(key);
    return field.confirmed;
  }

  void clear() => _fields.clear();
}

class _Field<V> {
  _Field(this.confirmed);
  V? confirmed;
  final pending = <(Object, V)>[];
}
