import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'lm_router.dart';

/// Intent used by [LmRouterKeyboardShortcuts] to request router back.
final class LmRouterBackIntent extends Intent {
  const LmRouterBackIntent();
}

/// Adds desktop/web keyboard shortcuts for router back navigation.
///
/// The default shortcuts are:
///
/// - `Escape`
/// - `Alt + Arrow Left`
/// - `Meta + [` on Apple keyboards
///
/// Wrap the app body inside `MaterialApp.router.builder` so the shortcuts cover
/// every route and router-owned modal:
///
/// ```dart
/// MaterialApp.router(
///   routerConfig: router.config,
///   builder: (context, child) {
///     return LmRouterKeyboardShortcuts(
///       router: router,
///       child: LmRouterScope(router: router, child: child!),
///     );
///   },
/// );
/// ```
final class LmRouterKeyboardShortcuts extends StatelessWidget {
  const LmRouterKeyboardShortcuts({
    required this.router,
    required this.child,
    this.shortcuts = defaultShortcuts,
    this.enabled = true,
    super.key,
  });

  static const Map<ShortcutActivator, Intent> defaultShortcuts = {
    SingleActivator(LogicalKeyboardKey.escape): LmRouterBackIntent(),
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
        LmRouterBackIntent(),
    SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
        LmRouterBackIntent(),
  };

  final LmRouter router;
  final Widget child;
  final Map<ShortcutActivator, Intent> shortcuts;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: {
          LmRouterBackIntent: CallbackAction<LmRouterBackIntent>(
            onInvoke: (_) {
              unawaited(router.delegate.pop());
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}
