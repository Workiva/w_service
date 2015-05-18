library w_service.src.generic.context;

/// Context for service messages including a unique identifier,
/// a timestamp, and a catch-all meta object.
abstract class Context {
  /// Construct a new [Context] instance with an empty [meta] map and
  /// a [timestamp] of now.
  Context(this.id)
      : meta = {},
        timestamp = new DateTime.now();

  /// Unique message identifier. Should be globally unique.
  final String id;

  /// Meta object that allows for relating additional information to
  /// a particular message. If possible, it is preferable to keep state
  /// internally in an interceptor or pass such information through a
  /// more clearly defined API. If necessary, however, this can useful
  /// for passing flags or configuration information from a provider
  /// to an interceptor.
  Map<String, dynamic> meta;

  /// Timestamp marking the creation of this [Context] instance.
  final DateTime timestamp;
}
