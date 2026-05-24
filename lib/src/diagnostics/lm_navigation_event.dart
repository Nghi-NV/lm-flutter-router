import '../core/lm_location.dart';
import '../delegate/lm_navigation_transaction.dart';

enum LmNavigationEventType {
  navigateStart,
  navigateCommit,
  navigateCancel,
  navigateError,
  guardAllow,
  guardBlock,
  guardRedirect,
  redirectLoopDetected,
  modalPush,
  modalPop,
  branchSwitch,
  layoutProjectionChanged,
  restoreStart,
  restoreFailed,
}

enum LmNavigationResult { committed, cancelled, blocked, redirected, failed }

final class LmNavigationEvent {
  const LmNavigationEvent({
    required this.type,
    required this.source,
    required this.from,
    required this.to,
    required this.result,
    required this.duration,
    this.error,
  });

  final LmNavigationEventType type;
  final LmNavigationSource source;
  final LmLocation? from;
  final LmLocation to;
  final LmNavigationResult result;
  final Duration duration;
  final Object? error;
}
