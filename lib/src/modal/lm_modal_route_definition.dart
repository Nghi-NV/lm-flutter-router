import 'package:flutter/widgets.dart';

import '../core/lm_location.dart';
import '../core/lm_route_definition.dart';
import '../transitions/lm_transition.dart';
import 'lm_modal_presentation.dart';

typedef LmModalRouteParamDecoder<TParams> =
    TParams Function(Map<String, String> pathParameters);
typedef LmModalRouteWidgetBuilder<TParams> =
    Widget Function(BuildContext context, TParams? params);

/// Describes a router-owned modal route such as an action sheet, bottom sheet,
/// dialog, or popover.
///
/// Modal routes participate in deep links and browser history in the same
/// router state as page routes:
///
/// ```dart
/// final actionsRoute = LmModalRouteDefinition<OrderParams>.actionSheet(
///   path: '/orders/:orderId/actions',
///   decode: (path) => OrderParams(int.parse(path['orderId']!)),
///   build: (context, params) => OrderActionsSheet(orderId: params!.orderId),
/// );
/// ```
///
/// Present modal locations with `context.lm.present(...)`; dismiss them with
/// `context.lm.pop()` or the platform back affordance.
final class LmModalRouteDefinition<TParams> {
  const LmModalRouteDefinition({
    required this.name,
    required this.path,
    required this.presentation,
    this.decode,
    this.buildPath,
    this.build,
    this.transition,
    this.restorationId,
  });

  factory LmModalRouteDefinition.dialog({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) {
    return _LmDialogRouteDefinition<TParams>(
      name: name ?? _modalRouteNameFromPath(path),
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  factory LmModalRouteDefinition.cupertinoDialog({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = false,
    bool usesSafeArea = true,
  }) {
    return _LmCupertinoDialogRouteDefinition<TParams>(
      name: name ?? _modalRouteNameFromPath(path),
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  factory LmModalRouteDefinition.sheet({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
    bool fullscreen = false,
  }) {
    return _LmSheetRouteDefinition<TParams>(
      name: name ?? _modalRouteNameFromPath(path),
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
      fullscreen: fullscreen,
    );
  }

  factory LmModalRouteDefinition.actionSheet({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) {
    return _LmActionSheetRouteDefinition<TParams>(
      name: name ?? _modalRouteNameFromPath(path),
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  factory LmModalRouteDefinition.fullscreenDialog({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = false,
    bool usesSafeArea = true,
  }) {
    return _LmFullscreenDialogRouteDefinition<TParams>(
      name: name ?? _modalRouteNameFromPath(path),
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  factory LmModalRouteDefinition.popover({
    String? name,
    required String path,
    LmModalRouteParamDecoder<TParams>? decode,
    LmRoutePathBuilder<TParams>? buildPath,
    required LmModalRouteWidgetBuilder<TParams> build,
    LmTransition? transition,
    String? restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) {
    return _LmPopoverRouteDefinition<TParams>(
      name: name ?? _modalRouteNameFromPath(path),
      path: path,
      decode: decode,
      buildPath: buildPath,
      build: build,
      transition: transition,
      restorationId: restorationId,
      barrierDismissible: barrierDismissible,
      usesSafeArea: usesSafeArea,
    );
  }

  final String name;
  final String path;
  final LmModalPresentation presentation;
  final LmModalRouteParamDecoder<TParams>? decode;
  final LmRoutePathBuilder<TParams>? buildPath;
  final LmModalRouteWidgetBuilder<TParams>? build;
  final LmTransition? transition;
  final String? restorationId;

  LmLocation location(
    TParams? params, {
    Map<String, String> query = const {},
    String? fragment,
    Object? extra,
  }) {
    final path = params == null
        ? _staticPathForLocation()
        : _buildPathFor(params);
    return LmLocation(
      path: path,
      query: query,
      fragment: fragment,
      extra: extra,
    );
  }

  LmLocation rootLocation({
    Map<String, String> query = const {},
    String? fragment,
    Object? extra,
  }) {
    return LmLocation(
      path: path,
      query: query,
      fragment: fragment,
      extra: extra,
    );
  }

  Object? decodeParams(Map<String, String> pathParameters) {
    return decode?.call(pathParameters);
  }

  Widget buildWidget(BuildContext context, Object? params) {
    final builder = build;
    if (builder == null) {
      throw StateError(
        'Modal route "$name" cannot build a page because build is missing.',
      );
    }
    return builder(context, params as TParams?);
  }

  String _buildPathFor(TParams params) {
    final builder = buildPath;
    if (builder == null) {
      throw StateError(
        'Modal route "$name" cannot build a location because buildPath is missing.',
      );
    }
    return builder(params);
  }

  String _staticPathForLocation() {
    if (_pathRequiresParams(path)) {
      throw StateError(
        'Modal route "$name" requires params to build a location for path "$path".',
      );
    }
    return path;
  }
}

bool _pathRequiresParams(String path) {
  return path
      .split('/')
      .any((segment) => segment.startsWith(':') || segment == '*');
}

String _modalRouteNameFromPath(String path) {
  final normalized = path.trim();
  if (normalized.isEmpty || normalized == '/') {
    return 'root';
  }
  final segments = normalized
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .map((segment) {
        if (segment.startsWith(':')) {
          return segment.substring(1);
        }
        if (segment == '*') {
          return 'wildcard';
        }
        return segment;
      })
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return 'root';
  }
  return segments.join('.');
}

final class _LmDialogRouteDefinition<TParams>
    extends LmModalRouteDefinition<TParams> {
  _LmDialogRouteDefinition({
    required super.name,
    required super.path,
    super.decode,
    super.buildPath,
    super.build,
    super.transition,
    super.restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) : super(
         presentation: LmModalPresentation.dialog(
           barrierDismissible: barrierDismissible,
           usesSafeArea: usesSafeArea,
           transition: transition ?? const LmTransition.fade(),
         ),
       );
}

final class _LmSheetRouteDefinition<TParams>
    extends LmModalRouteDefinition<TParams> {
  _LmSheetRouteDefinition({
    required super.name,
    required super.path,
    super.decode,
    super.buildPath,
    super.build,
    super.transition,
    super.restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
    bool fullscreen = false,
  }) : super(
         presentation: LmModalPresentation.bottomSheet(
           barrierDismissible: barrierDismissible,
           usesSafeArea: usesSafeArea,
           fullscreen: fullscreen,
           transition:
               transition ??
               const LmTransition.slide(
                 from: LmSlideFrom.bottom,
                 duration: Duration(milliseconds: 300),
                 curve: Curves.fastEaseInToSlowEaseOut,
               ),
         ),
       );
}

final class _LmCupertinoDialogRouteDefinition<TParams>
    extends LmModalRouteDefinition<TParams> {
  _LmCupertinoDialogRouteDefinition({
    required super.name,
    required super.path,
    super.decode,
    super.buildPath,
    super.build,
    super.transition,
    super.restorationId,
    bool barrierDismissible = false,
    bool usesSafeArea = true,
  }) : super(
         presentation: LmModalPresentation.cupertinoDialog(
           barrierDismissible: barrierDismissible,
           usesSafeArea: usesSafeArea,
           transition: transition ?? const LmTransition.fade(),
         ),
       );
}

final class _LmActionSheetRouteDefinition<TParams>
    extends LmModalRouteDefinition<TParams> {
  _LmActionSheetRouteDefinition({
    required super.name,
    required super.path,
    super.decode,
    super.buildPath,
    super.build,
    super.transition,
    super.restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) : super(
         presentation: LmModalPresentation.actionSheet(
           barrierDismissible: barrierDismissible,
           usesSafeArea: usesSafeArea,
           transition:
               transition ??
               const LmTransition.slide(
                 from: LmSlideFrom.bottom,
                 duration: Duration(milliseconds: 300),
                 curve: Curves.fastEaseInToSlowEaseOut,
               ),
         ),
       );
}

final class _LmFullscreenDialogRouteDefinition<TParams>
    extends LmModalRouteDefinition<TParams> {
  _LmFullscreenDialogRouteDefinition({
    required super.name,
    required super.path,
    super.decode,
    super.buildPath,
    super.build,
    super.transition,
    super.restorationId,
    bool barrierDismissible = false,
    bool usesSafeArea = true,
  }) : super(
         presentation: LmModalPresentation.fullscreenDialog(
           barrierDismissible: barrierDismissible,
           usesSafeArea: usesSafeArea,
           transition:
               transition ??
               const LmTransition.fullscreenModal(
                 duration: Duration(milliseconds: 300),
                 curve: Curves.fastEaseInToSlowEaseOut,
               ),
         ),
       );
}

final class _LmPopoverRouteDefinition<TParams>
    extends LmModalRouteDefinition<TParams> {
  _LmPopoverRouteDefinition({
    required super.name,
    required super.path,
    super.decode,
    super.buildPath,
    super.build,
    super.transition,
    super.restorationId,
    bool barrierDismissible = true,
    bool usesSafeArea = true,
  }) : super(
         presentation: LmModalPresentation.popover(
           barrierDismissible: barrierDismissible,
           usesSafeArea: usesSafeArea,
           transition: transition ?? const LmTransition.fade(),
         ),
       );
}
