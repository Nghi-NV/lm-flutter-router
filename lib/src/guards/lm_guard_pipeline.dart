// ignore_for_file: use_super_parameters

import 'dart:async';

import '../core/lm_location.dart';
import '../delegate/lm_navigation_transaction.dart';
import 'lm_guard.dart';

typedef LmNavigationCurrent = bool Function(int navigationId);

final class LmGuardPipeline {
  const LmGuardPipeline({
    required this.guards,
    this.maxRedirects = 8,
    LmNavigationCurrent? isNavigationCurrent,
  }) : isNavigationCurrent = isNavigationCurrent ?? _alwaysCurrent;

  final List<LmGuard> guards;
  final int maxRedirects;
  final LmNavigationCurrent isNavigationCurrent;

  Future<LmGuardEvaluationResult> evaluate(
    LmNavigationTransaction transaction,
  ) async {
    return _evaluate(
      transaction,
      guardsForAttempt: () => guards,
      invokeGuard: (guard, context) => guard.canActivate(context),
    );
  }

  Future<LmGuardEvaluationResult> evaluatePop(
    LmNavigationTransaction transaction,
  ) async {
    return _evaluate(
      transaction,
      guardsForAttempt: () => guards.whereType<LmPopGuard>(),
      invokeGuard: (guard, context) => guard.canPop(context),
    );
  }

  Future<LmGuardEvaluationResult> _evaluate<TGuard>(
    LmNavigationTransaction transaction, {
    required Iterable<TGuard> Function() guardsForAttempt,
    required FutureOr<LmGuardResult> Function(
      TGuard guard,
      LmGuardContext context,
    )
    invokeGuard,
  }) async {
    var current = transaction;
    var originalIntent = transaction.to;
    final visited = <LmLocation>[transaction.to];

    for (var redirectCount = 0; ; redirectCount += 1) {
      if (!isNavigationCurrent(current.id)) {
        return LmGuardStale(transaction: current);
      }

      final context = LmGuardContext(
        transaction: current,
        current: LmGuardNavigationAttempt(
          location: current.to,
          source: current.source,
        ),
        originalIntent: originalIntent,
        redirectCount: redirectCount,
      );

      LmGuardRedirect? redirect;
      for (final guard in guardsForAttempt()) {
        final LmGuardResult result;
        try {
          result = await invokeGuard(guard, context);
        } on Object catch (error, stackTrace) {
          return LmGuardErrored(
            transaction: current,
            originalIntent: originalIntent,
            error: error,
            stackTrace: stackTrace,
          );
        }
        if (!isNavigationCurrent(current.id)) {
          return LmGuardStale(transaction: current);
        }

        switch (result) {
          case LmGuardAllow():
            continue;
          case LmGuardBlock(:final reason):
            return LmGuardBlocked(
              transaction: current,
              originalIntent: originalIntent,
              reason: reason,
            );
          case LmGuardRedirect():
            redirect = result;
            break;
        }

        break;
      }

      if (redirect == null) {
        return LmGuardAllowed(
          transaction: current,
          originalIntent: originalIntent,
        );
      }

      final nextLocation = redirect.location;
      if (visited.contains(nextLocation)) {
        return LmGuardRedirectLoop(
          transaction: current.redirectTo(nextLocation),
          originalIntent: originalIntent,
          locations: [...visited, nextLocation],
        );
      }

      if (redirectCount + 1 > maxRedirects) {
        return LmGuardRedirectLoop(
          transaction: current.redirectTo(nextLocation),
          originalIntent: originalIntent,
          locations: [...visited, nextLocation],
        );
      }

      if (!redirect.preserveIntent) {
        originalIntent = nextLocation;
      }

      visited.add(nextLocation);
      current = current.redirectTo(nextLocation);
    }
  }

  static bool _alwaysCurrent(int _) => true;
}

sealed class LmGuardEvaluationResult {
  const LmGuardEvaluationResult({
    required this.transaction,
    required this.originalIntent,
  });

  final LmNavigationTransaction transaction;
  final LmLocation originalIntent;
}

final class LmGuardAllowed extends LmGuardEvaluationResult {
  const LmGuardAllowed({
    required super.transaction,
    required super.originalIntent,
  });
}

final class LmGuardBlocked extends LmGuardEvaluationResult {
  const LmGuardBlocked({
    required super.transaction,
    required super.originalIntent,
    required this.reason,
  });

  final Object reason;
}

final class LmGuardRedirectLoop extends LmGuardEvaluationResult {
  LmGuardRedirectLoop({
    required super.transaction,
    required super.originalIntent,
    required List<LmLocation> locations,
  }) : locations = List.unmodifiable(locations);

  final List<LmLocation> locations;
}

final class LmGuardStale extends LmGuardEvaluationResult {
  LmGuardStale({required LmNavigationTransaction transaction})
    : super(transaction: transaction, originalIntent: transaction.to);
}

final class LmGuardErrored extends LmGuardEvaluationResult {
  const LmGuardErrored({
    required super.transaction,
    required super.originalIntent,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;
}
