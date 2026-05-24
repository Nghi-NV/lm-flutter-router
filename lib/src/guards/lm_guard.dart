import 'dart:async';

import '../delegate/lm_navigation_transaction.dart';
import '../core/lm_location.dart';

/// Intercepts navigation before the router commits a location.
///
/// Guards can allow, block, or redirect. A common auth redirect keeps the
/// original intent so the app can resume it after login:
///
/// ```dart
/// final router = Lm.router(
///   guards: [
///     Lm.guard((context) {
///       if (session.isSignedIn || context.current.location.path == '/login') {
///         return const LmGuardAllow();
///       }
///       return LmGuardRedirect.toLogin('/login', context);
///     }),
///   ],
///   routes: routes,
/// );
/// ```
abstract interface class LmGuard {
  FutureOr<LmGuardResult> canActivate(LmGuardContext context);
}

/// Optional guard hook for leaving the current route.
///
/// Implement this in addition to [LmGuard] when a route needs to block or
/// redirect back gestures, system back, modal dismissals, or programmatic pops.
abstract interface class LmPopGuard {
  FutureOr<LmGuardResult> canPop(LmGuardContext context);
}

final class LmCallbackGuard implements LmGuard {
  const LmCallbackGuard(this._canActivate);

  final FutureOr<LmGuardResult> Function(LmGuardContext context) _canActivate;

  @override
  FutureOr<LmGuardResult> canActivate(LmGuardContext context) {
    return _canActivate(context);
  }
}

final class LmCallbackPopGuard implements LmGuard, LmPopGuard {
  const LmCallbackPopGuard({
    FutureOr<LmGuardResult> Function(LmGuardContext context)? canActivate,
    required FutureOr<LmGuardResult> Function(LmGuardContext context) canPop,
  }) : _canActivate = canActivate,
       _canPop = canPop;

  final FutureOr<LmGuardResult> Function(LmGuardContext context)? _canActivate;
  final FutureOr<LmGuardResult> Function(LmGuardContext context) _canPop;

  @override
  FutureOr<LmGuardResult> canActivate(LmGuardContext context) {
    return _canActivate?.call(context) ?? const LmGuardAllow();
  }

  @override
  FutureOr<LmGuardResult> canPop(LmGuardContext context) {
    return _canPop(context);
  }
}

final class LmGuardContext {
  const LmGuardContext({
    required this.transaction,
    required this.current,
    required this.originalIntent,
    required this.redirectCount,
  });

  final LmNavigationTransaction transaction;
  final LmGuardNavigationAttempt current;
  final LmLocation originalIntent;
  final int redirectCount;
}

final class LmGuardNavigationAttempt {
  const LmGuardNavigationAttempt({
    required this.location,
    required this.source,
  });

  final LmLocation location;
  final LmNavigationSource source;
}

sealed class LmGuardResult {
  const LmGuardResult();
}

final class LmGuardAllow extends LmGuardResult {
  const LmGuardAllow();
}

final class LmGuardBlock extends LmGuardResult {
  const LmGuardBlock(this.reason);

  final Object reason;
}

final class LmGuardRedirect extends LmGuardResult {
  const LmGuardRedirect(this.location, {this.preserveIntent = true});

  factory LmGuardRedirect.toLogin(
    String loginPath,
    LmGuardContext context, {
    String returnToQuery = 'returnTo',
  }) {
    return LmGuardRedirect(
      LmLocation(
        path: loginPath,
        query: {returnToQuery: context.originalIntent.canonical},
      ),
    );
  }

  final LmLocation location;
  final bool preserveIntent;
}
