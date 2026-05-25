class CachedResult<T> {
  final T data;
  final bool isFromCache;
  final String? message;

  const CachedResult({
    required this.data,
    required this.isFromCache,
    this.message,
  });

  const CachedResult.network(this.data) : isFromCache = false, message = null;

  const CachedResult.cache(this.data, {this.message}) : isFromCache = true;
}
