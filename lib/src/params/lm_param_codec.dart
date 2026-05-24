import 'lm_param_errors.dart';

abstract interface class LmParamCodec<T> {
  String encode(T value);

  T decode(String raw, {String routeName, String paramName});

  T decodeRequired(String? raw, {String routeName, String paramName});
}

abstract base class LmBaseParamCodec<T> implements LmParamCodec<T> {
  const LmBaseParamCodec();

  @override
  T decodeRequired(
    String? raw, {
    String routeName = '<unknown route>',
    String paramName = '<unknown param>',
  }) {
    if (raw == null) {
      throw LmMissingParamException(routeName: routeName, paramName: paramName);
    }
    return decode(raw, routeName: routeName, paramName: paramName);
  }
}
