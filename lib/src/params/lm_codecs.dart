import 'dart:core';
import 'dart:core' as core;

import 'lm_param_codec.dart';
import 'lm_param_errors.dart';

abstract final class LmCodecs {
  static const LmParamCodec<String> string = _StringCodec();
  static const LmParamCodec<core.int> int = _IntCodec();
  static const LmParamCodec<core.double> double = _DoubleCodec();
  static const LmParamCodec<core.bool> bool = _BoolCodec();
  static const LmParamCodec<DateTime> dateTimeIso8601 = _DateTimeIso8601Codec();

  static LmParamCodec<T> enumByName<T extends Enum>(List<T> values) {
    return _EnumByNameCodec<T>(values);
  }
}

final class _StringCodec extends LmBaseParamCodec<String> {
  const _StringCodec();

  @override
  String encode(String value) => value;

  @override
  String decode(
    String raw, {
    String routeName = '<unknown route>',
    String paramName = '<unknown param>',
  }) {
    return raw;
  }
}

final class _IntCodec extends LmBaseParamCodec<int> {
  const _IntCodec();

  @override
  String encode(int value) => value.toString();

  @override
  int decode(
    String raw, {
    String routeName = '<unknown route>',
    String paramName = '<unknown param>',
  }) {
    final value = int.tryParse(raw);
    if (value == null) {
      throw LmInvalidParamException(
        routeName: routeName,
        paramName: paramName,
        rawValue: raw,
        expectedType: 'int',
      );
    }
    return value;
  }
}

final class _DoubleCodec extends LmBaseParamCodec<double> {
  const _DoubleCodec();

  @override
  String encode(double value) => value.toString();

  @override
  double decode(
    String raw, {
    String routeName = '<unknown route>',
    String paramName = '<unknown param>',
  }) {
    final value = double.tryParse(raw);
    if (value == null || value.isNaN || value.isInfinite) {
      throw LmInvalidParamException(
        routeName: routeName,
        paramName: paramName,
        rawValue: raw,
        expectedType: 'double',
      );
    }
    return value;
  }
}

final class _BoolCodec extends LmBaseParamCodec<bool> {
  const _BoolCodec();

  @override
  String encode(bool value) => value ? 'true' : 'false';

  @override
  bool decode(
    String raw, {
    String routeName = '<unknown route>',
    String paramName = '<unknown param>',
  }) {
    return switch (raw) {
      'true' => true,
      'false' => false,
      _ => throw LmInvalidParamException(
        routeName: routeName,
        paramName: paramName,
        rawValue: raw,
        expectedType: 'bool',
      ),
    };
  }
}

final class _DateTimeIso8601Codec extends LmBaseParamCodec<DateTime> {
  const _DateTimeIso8601Codec();

  @override
  String encode(DateTime value) => value.toIso8601String();

  @override
  DateTime decode(
    String raw, {
    String routeName = '<unknown route>',
    String paramName = '<unknown param>',
  }) {
    try {
      return DateTime.parse(raw);
    } on FormatException {
      throw LmInvalidParamException(
        routeName: routeName,
        paramName: paramName,
        rawValue: raw,
        expectedType: 'DateTime ISO-8601',
      );
    }
  }
}

final class _EnumByNameCodec<T extends Enum> extends LmBaseParamCodec<T> {
  _EnumByNameCodec(List<T> values)
    : _valuesByName = Map<String, T>.unmodifiable({
        for (final value in values) value.name: value,
      }),
      _allowedValues = List<String>.unmodifiable(
        values.map((value) => value.name),
      );

  final Map<String, T> _valuesByName;
  final List<String> _allowedValues;

  @override
  String encode(T value) => value.name;

  @override
  T decode(
    String raw, {
    String routeName = '<unknown route>',
    String paramName = '<unknown param>',
  }) {
    final value = _valuesByName[raw];
    if (value == null) {
      throw LmUnknownEnumValueException(
        routeName: routeName,
        paramName: paramName,
        rawValue: raw,
        allowedValues: _allowedValues,
      );
    }
    return value;
  }
}
