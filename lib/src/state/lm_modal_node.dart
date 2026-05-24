import '../core/lm_location.dart';

final class LmModalNode {
  LmModalNode({
    required this.name,
    required this.location,
    this.params,
    Map<String, String> query = const {},
  }) : query = Map.unmodifiable(query);

  final String name;
  final LmLocation location;
  final Object? params;
  final Map<String, String> query;
}
