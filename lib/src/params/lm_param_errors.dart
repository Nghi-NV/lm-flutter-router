sealed class LmRouteDecodeException implements Exception {
  const LmRouteDecodeException({
    required this.routeName,
    required this.paramName,
    required this.message,
  });

  final String routeName;
  final String paramName;
  final String message;

  @override
  String toString() =>
      '$runtimeType(route: $routeName, param: $paramName, message: $message)';
}

final class LmMissingParamException extends LmRouteDecodeException {
  const LmMissingParamException({
    required super.routeName,
    required super.paramName,
  }) : super(message: 'Missing required route parameter.');
}

final class LmInvalidParamException extends LmRouteDecodeException {
  const LmInvalidParamException({
    required super.routeName,
    required super.paramName,
    required this.rawValue,
    required this.expectedType,
  }) : super(message: 'Invalid route parameter value.');

  final String rawValue;
  final String expectedType;

  @override
  String toString() {
    return '${super.toString()} rawValue: $rawValue, expectedType: $expectedType';
  }
}

final class LmUnknownEnumValueException extends LmRouteDecodeException {
  const LmUnknownEnumValueException({
    required super.routeName,
    required super.paramName,
    required this.rawValue,
    required this.allowedValues,
  }) : super(message: 'Unknown enum route parameter value.');

  final String rawValue;
  final List<String> allowedValues;

  @override
  String toString() {
    return '${super.toString()} rawValue: $rawValue, allowedValues: $allowedValues';
  }
}
