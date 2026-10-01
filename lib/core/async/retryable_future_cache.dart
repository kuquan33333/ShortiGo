class RetryableFutureCache<K, V> {
  final Map<K, Future<V>> _values = {};

  Future<V> getOrCreate(K key, Future<V> Function() loader) {
    final cached = _values[key];
    if (cached != null) return cached;

    final future = loader();
    _values[key] = future;
    future.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {
        if (identical(_values[key], future)) {
          _values.remove(key);
        }
      },
    );
    return future;
  }

  void retainOnly(Iterable<K> keys) {
    final keep = keys.toSet();
    _values.removeWhere((key, _) => !keep.contains(key));
  }

  void remove(K key) => _values.remove(key);

  void clear() => _values.clear();
}
