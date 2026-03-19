import 'package:flutter/foundation.dart';

/// Handles local persistence of network images to reduce bandwidth.
/// Preliminary implementation for phase 1 development.
class ImageCacheService {
  static final Map<String, Uint8List> _memoryCache = {};

  /// Check if image is in local memory cache
  static bool has(String url) => _memoryCache.containsKey(url);

  /// Get image from cache
  static Uint8List? get(String url) => _memoryCache[url];

  /// Cache image data
  static void cache(String url, Uint8List data) {
    if (_memoryCache.length > 50) {
      _memoryCache.remove(_memoryCache.keys.first); // Simple LRU
    }
    _memoryCache[url] = data;
    debugPrint('[ImageCache] Cached: $url');
  }

  /// Wipe entire cache
  static void clear() => _memoryCache.clear();
}
