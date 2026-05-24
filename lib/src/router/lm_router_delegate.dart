import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../adaptive/lm_branch.dart';
import '../core/lm_location.dart';
import '../core/lm_route_definition.dart';
import '../core/lm_route_location.dart';
import '../delegate/lm_navigation_controller.dart';
import '../diagnostics/lm_navigation_event.dart';
import '../diagnostics/lm_router_diagnostics.dart';
import '../matcher/lm_route_matcher.dart';
import '../modal/lm_modal_route_definition.dart';
import '../modal/lm_modal_presentation.dart';
import '../guards/lm_guard.dart';
import '../guards/lm_guard_pipeline.dart';
import '../delegate/lm_navigation_transaction.dart';
import '../state/lm_branch_state.dart';
import '../state/lm_modal_node.dart';
import '../state/lm_navigation_state.dart';
import '../state/lm_route_node.dart';
import '../transitions/lm_page_factory.dart';
import '../transitions/lm_transition.dart';
import '../transitions/lm_transition_policy.dart';

const bool _lmTraceRouter = bool.fromEnvironment('LM_ROUTER_TRACE_TRANSITIONS');
const Duration _lmCupertinoDialogRouteDuration = Duration(milliseconds: 250);
const Duration _lmCupertinoModalSheetRouteDuration = Duration(
  milliseconds: 300,
);
const int _lmRouteCacheLimit = 256;

void _lmTraceRouterEvent(String message) {
  if (!_lmTraceRouter) {
    return;
  }
  debugPrint('LM_ROUTER_TRACE ${DateTime.now().toIso8601String()} $message');
}

final class LmRouterDelegate extends RouterDelegate<LmLocation>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<LmLocation> {
  LmRouterDelegate({
    required List<LmRouteDefinition<Object?>> routes,
    required LmLocation initialLocation,
    List<LmModalRouteDefinition<Object?>> modalRoutes = const [],
    List<LmBranch> branches = const [],
    List<LmGuard> guards = const [],
    LmRouteDefinition<Object?>? notFoundRoute,
    Listenable? refreshListenable,
    LmRouterDiagnostics? diagnostics,
    LmTransitionPolicy transitionPolicy = const LmTransitionPolicy.adaptive(),
    GlobalKey<NavigatorState>? navigatorKey,
  }) : _routes = routes,
       _modalRoutePatterns = _indexModalRoutePatterns(modalRoutes),
       _modalRoutesByName = _indexModalRoutesByName(modalRoutes),
       _branchPatterns = _indexBranchPatterns(branches),
       _routePatternsByFirstSegment = _indexRoutePatternsByFirstSegment(routes),
       _routesByPathPattern = _indexRoutesByPathPattern(routes),
       _matcher = LmRouteMatcher(routes),
       _guards = guards,
       _notFoundRoute = notFoundRoute,
       _refreshListenable = refreshListenable,
       _diagnostics = diagnostics,
       _transitionPolicy = transitionPolicy,
       navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    _validateRouteDefinitions(_routes);
    _validateModalRouteDefinitions(
      _modalRoutePatterns.map((item) => item.route),
    );
    _validateBranchPatterns(_branchPatterns);
    final initialState = _stateFor(initialLocation);
    _guardPipeline = LmGuardPipeline(
      guards: _guards,
      isNavigationCurrent: _isNavigationCurrent,
    );
    controller = LmNavigationController(initialState: initialState);
    controller.addListener(notifyListeners);
    _refreshListenable?.addListener(_handleRefresh);
  }

  final List<LmRouteDefinition<Object?>> _routes;
  final List<_ModalRoutePattern> _modalRoutePatterns;
  final Map<String, LmModalRouteDefinition<Object?>> _modalRoutesByName;
  final List<_BranchPattern> _branchPatterns;
  final Map<String, List<_RoutePattern>> _routePatternsByFirstSegment;
  final Map<String, LmRouteDefinition<Object?>> _routesByPathPattern;
  final LmRouteMatcher _matcher;
  final List<LmGuard> _guards;
  final LmRouteDefinition<Object?>? _notFoundRoute;
  final Listenable? _refreshListenable;
  final LmRouterDiagnostics? _diagnostics;
  final LmTransitionPolicy _transitionPolicy;
  late final LmGuardPipeline _guardPipeline;
  int _nextNavigationId = 1;
  int _currentNavigationId = 0;
  Future<void> _navigationQueue = Future<void>.value();
  bool _navigationQueueIdle = true;
  Future<bool>? _pendingPopNavigation;
  bool _needsTransitionDrain = false;
  bool _transitionMarkedBeforeFrame = false;
  DateTime? _transitionSettleDeadline;
  final Map<String, List<LmRouteNode>> _stackCache = {};
  final Map<String, _ModalRouteMatch?> _modalMatchCache = {};

  late final LmNavigationController controller;

  @override
  final GlobalKey<NavigatorState> navigatorKey;

  @visibleForTesting
  int get debugStackCacheSize => _stackCache.length;

  @visibleForTesting
  int get debugModalMatchCacheSize => _modalMatchCache.length;

  @override
  void dispose() {
    _refreshListenable?.removeListener(_handleRefresh);
    controller.removeListener(notifyListeners);
    controller.dispose();
    super.dispose();
  }

  @override
  LmLocation? get currentConfiguration {
    final modal = controller.state.modalStack.lastOrNull;
    return modal?.location ?? controller.state.location;
  }

  @override
  Widget build(BuildContext context) {
    final branch = controller.state.branches[controller.state.activeBranchId];
    final stack = branch?.semanticStack ?? const <LmRouteNode>[];
    return Navigator(
      key: navigatorKey,
      pages: [
        for (final node in stack) _buildPage(context, node),
        for (final node in controller.state.modalStack)
          _buildModalPage(context, node),
      ],
      onDidRemovePage: (page) {
        if (_stackContainsPage(page) || _modalStackContainsPage(page)) {
          unawaited(_popWithSource(LmNavigationSource.gestureBack));
        }
      },
    );
  }

  @override
  Future<void> setNewRoutePath(LmLocation configuration) async {
    await go(configuration, source: LmNavigationSource.deepLink);
  }

  Future<void> go(
    Object location, {
    LmNavigationSource source = LmNavigationSource.programmaticGo,
  }) async {
    final configuration = _locationFrom(location);
    final modalMatch = _matchModal(configuration);
    if (modalMatch != null) {
      if (controller.state.modalStack.lastOrNull?.location.canonical ==
          configuration.canonical) {
        return;
      }
      final transaction = _beginTransaction(source: source, to: configuration);
      final guardResult = await _guardPipeline.evaluate(transaction);
      switch (guardResult) {
        case LmGuardAllowed(:final transaction):
          _emitGuardNavigationAllow(guardResult);
          await _enqueueNavigation<void>(() async {
            return _presentAllowed(transaction.to);
          }, waitForIdle: false);
        case LmGuardBlocked():
        case LmGuardRedirectLoop():
        case LmGuardStale():
        case LmGuardErrored():
          _emitGuardNavigationStop(guardResult);
          return;
      }
      return;
    }

    final targetStack = _stackFor(configuration);
    final target = targetStack.last;
    if (_guards.isEmpty) {
      final settleDuration = _routeForwardDurationForNode(target);
      if (_navigationQueueIdle &&
          !_needsTransitionDrain &&
          !_hasQueuedTransition &&
          settleDuration <= Duration.zero) {
        final from = controller.state.location;
        final startedAt = DateTime.now();
        final before = controller.state;
        _goStackForLocation(target.location, targetStack);
        final changed = !identical(before, controller.state);
        if (changed) {
          _emitNavigationEvent(
            type: LmNavigationEventType.navigateCommit,
            source: source,
            from: from,
            to: controller.state.location,
            result: LmNavigationResult.committed,
            startedAt: startedAt,
          );
        }
        return;
      }
      await _enqueueNavigation<void>(() async {
        final from = controller.state.location;
        final startedAt = DateTime.now();
        final before = controller.state;
        _goStackForLocation(target.location, targetStack);
        final changed = !identical(before, controller.state);
        if (changed) {
          _emitNavigationEvent(
            type: LmNavigationEventType.navigateCommit,
            source: source,
            from: from,
            to: controller.state.location,
            result: LmNavigationResult.committed,
            startedAt: startedAt,
          );
        }
        return _NavigationOutcome<void>(
          null,
          changed ? settleDuration : Duration.zero,
        );
      }, waitForIdle: false);
      return;
    }
    final transaction = _beginTransaction(source: source, to: target.location);
    final guardResult = await _guardPipeline.evaluate(transaction);
    switch (guardResult) {
      case LmGuardAllowed(:final transaction):
        _emitGuardNavigationAllow(guardResult);
        await _enqueueNavigation<void>(() async {
          final from = controller.state.location;
          final startedAt = DateTime.now();
          final before = controller.state;
          final stack = transaction.to.canonical == target.location.canonical
              ? targetStack
              : _stackFor(transaction.to);
          _goStackForLocation(transaction.to, stack);
          final changed = !identical(before, controller.state);
          if (changed) {
            _emitNavigationEvent(
              type: LmNavigationEventType.navigateCommit,
              source: source,
              from: from,
              to: controller.state.location,
              result: LmNavigationResult.committed,
              startedAt: startedAt,
            );
          }
          return _NavigationOutcome<void>(
            null,
            changed
                ? _forwardDurationForLocation(transaction.to)
                : Duration.zero,
          );
        }, waitForIdle: false);
      case LmGuardBlocked():
      case LmGuardRedirectLoop():
      case LmGuardStale():
      case LmGuardErrored():
        _emitGuardNavigationStop(guardResult);
        return;
    }
  }

  Future<void> push(Object location) {
    return _enqueueNavigation<void>(() async {
      final from = controller.state.location;
      final startedAt = DateTime.now();
      final before = controller.state;
      final targetLocation = _locationFrom(location);
      await _pushNow(targetLocation);
      final changed = !identical(before, controller.state);
      if (changed) {
        _emitNavigationEvent(
          type: LmNavigationEventType.navigateCommit,
          source: LmNavigationSource.programmaticPush,
          from: from,
          to: controller.state.location,
          result: LmNavigationResult.committed,
          startedAt: startedAt,
        );
      }
      return _NavigationOutcome<void>(
        null,
        changed ? _forwardDurationForLocation(targetLocation) : Duration.zero,
      );
    });
  }

  Future<void> _pushNow(LmLocation targetLocation) async {
    final target = _nodeFor(targetLocation);
    final transaction = _beginTransaction(
      source: LmNavigationSource.programmaticPush,
      to: target.location,
    );
    final guardResult = await _guardPipeline.evaluate(transaction);
    switch (guardResult) {
      case LmGuardAllowed(:final transaction):
        _emitGuardNavigationAllow(guardResult);
        final node = transaction.to.canonical == target.location.canonical
            ? target
            : _nodeFor(transaction.to);
        final targetBranch = _branchForLocation(node.location);
        if (targetBranch != null &&
            targetBranch.id != controller.state.activeBranchId) {
          controller.goStackInBranch(targetBranch.id, _stackFor(node.location));
          return;
        }
        controller.push(node);
      case LmGuardBlocked():
      case LmGuardRedirectLoop():
      case LmGuardStale():
      case LmGuardErrored():
        _emitGuardNavigationStop(guardResult);
        return;
    }
  }

  Future<void> replace(Object location) {
    return _enqueueNavigation<void>(() async {
      final from = controller.state.location;
      final startedAt = DateTime.now();
      final before = controller.state;
      final targetLocation = _locationFrom(location);
      await _replaceNow(targetLocation);
      final changed = !identical(before, controller.state);
      if (changed) {
        _emitNavigationEvent(
          type: LmNavigationEventType.navigateCommit,
          source: LmNavigationSource.programmaticReplace,
          from: from,
          to: controller.state.location,
          result: LmNavigationResult.committed,
          startedAt: startedAt,
        );
      }
      return _NavigationOutcome<void>(
        null,
        changed ? _forwardDurationForLocation(targetLocation) : Duration.zero,
      );
    });
  }

  Future<void> _replaceNow(LmLocation targetLocation) async {
    final target = _nodeFor(targetLocation);
    final transaction = _beginTransaction(
      source: LmNavigationSource.programmaticReplace,
      to: target.location,
    );
    final guardResult = await _guardPipeline.evaluate(transaction);
    switch (guardResult) {
      case LmGuardAllowed(:final transaction):
        _emitGuardNavigationAllow(guardResult);
        final node = transaction.to.canonical == target.location.canonical
            ? target
            : _nodeFor(transaction.to);
        final targetBranch = _branchForLocation(node.location);
        if (targetBranch != null &&
            targetBranch.id != controller.state.activeBranchId) {
          controller.goStackInBranch(targetBranch.id, _stackFor(node.location));
          return;
        }
        controller.replace(node);
      case LmGuardBlocked():
      case LmGuardRedirectLoop():
      case LmGuardStale():
      case LmGuardErrored():
        _emitGuardNavigationStop(guardResult);
        return;
    }
  }

  Future<void> present(Object location) {
    return _enqueueNavigation<void>(() async {
      final targetLocation = _locationFrom(location);
      final transaction = _beginTransaction(
        source: LmNavigationSource.programmaticPush,
        to: targetLocation,
      );
      final guardResult = await _guardPipeline.evaluate(transaction);
      switch (guardResult) {
        case LmGuardAllowed(:final transaction):
          _emitGuardNavigationAllow(guardResult);
          return _presentAllowed(transaction.to);
        case LmGuardBlocked():
        case LmGuardRedirectLoop():
        case LmGuardStale():
        case LmGuardErrored():
          _emitGuardNavigationStop(guardResult);
          return const _NavigationOutcome<void>(null, Duration.zero);
      }
    });
  }

  _NavigationOutcome<void> _presentAllowed(LmLocation targetLocation) {
    final modalMatch = _matchModal(targetLocation);
    if (modalMatch == null) {
      final before = controller.state;
      _goStackForLocation(targetLocation, _stackFor(targetLocation));
      final changed = !identical(before, controller.state);
      return _NavigationOutcome<void>(
        null,
        changed ? _forwardDurationForLocation(targetLocation) : Duration.zero,
      );
    }

    final before = controller.state;
    final from = currentConfiguration ?? controller.state.location;
    final startedAt = DateTime.now();
    if (controller.state.modalStack.isEmpty) {
      final backgroundLocation = _backgroundLocationForModal(targetLocation);
      _goStackForLocation(backgroundLocation, _stackFor(backgroundLocation));
    }
    final modalNode = _tryModalNodeFor(targetLocation);
    if (modalNode == null) {
      _goStackForLocation(targetLocation, [_notFoundNode(targetLocation)]);
      final changed = !identical(before, controller.state);
      return _NavigationOutcome<void>(
        null,
        changed ? _forwardDurationForLocation(targetLocation) : Duration.zero,
      );
    }
    controller.present(modalNode);
    final changed = !identical(before, controller.state);
    if (changed) {
      _emitNavigationEvent(
        type: LmNavigationEventType.modalPush,
        source: LmNavigationSource.programmaticPush,
        from: from,
        to: modalNode.location,
        result: LmNavigationResult.committed,
        startedAt: startedAt,
      );
    }
    return _NavigationOutcome<void>(
      null,
      changed
          ? _modalForwardDurationForLocation(targetLocation) ?? Duration.zero
          : Duration.zero,
    );
  }

  Future<void> switchBranch(String branchId) {
    return _enqueueNavigation<void>(() async {
      _invalidatePendingNavigation();
      final branch = _branchPatternById(branchId);
      if (branch == null) {
        return const _NavigationOutcome<void>(null, Duration.zero);
      }
      final from = controller.state.location;
      final startedAt = DateTime.now();
      final before = controller.state;
      if (controller.state.activeBranchId == branchId &&
          branch.switchPolicy == LmBranchSwitchPolicy.popToRootOnReselect) {
        controller.goStackInBranch(branchId, _stackFor(branch.rootLocation));
      } else {
        controller.switchBranch(branchId);
      }
      final changed = !identical(before, controller.state);
      if (changed) {
        _emitNavigationEvent(
          type: LmNavigationEventType.branchSwitch,
          source: LmNavigationSource.programmaticGo,
          from: from,
          to: controller.state.location,
          result: LmNavigationResult.committed,
          startedAt: startedAt,
        );
      }
      return _NavigationOutcome<void>(
        null,
        changed
            ? _forwardDurationForLocation(controller.state.location)
            : Duration.zero,
      );
    });
  }

  Future<bool> pop() {
    return _popWithSource(LmNavigationSource.programmaticPop);
  }

  Future<bool> _popWithSource(LmNavigationSource source) {
    return _enqueuePopNavigation(() async {
      final duration = _currentReverseDuration();
      final target = _locationAfterPop();
      if (target == null) {
        return const _NavigationOutcome<bool>(false, Duration.zero);
      }
      final from = currentConfiguration ?? controller.state.location;
      final startedAt = DateTime.now();
      final poppedModal = controller.state.modalStack.lastOrNull;
      final transaction = _beginTransaction(
        source: source,
        from: currentConfiguration,
        to: target,
      );
      final guardResult = await _guardPipeline.evaluatePop(transaction);
      switch (guardResult) {
        case LmGuardAllowed(:final transaction):
          _emitGuardNavigationAllow(guardResult);
          if (transaction.to.canonical != target.canonical) {
            final outcome = _presentAllowed(transaction.to);
            return _NavigationOutcome<bool>(true, outcome.settleDuration);
          }
        case LmGuardBlocked():
        case LmGuardRedirectLoop():
        case LmGuardStale():
        case LmGuardErrored():
          _emitGuardNavigationStop(guardResult);
          return const _NavigationOutcome<bool>(false, Duration.zero);
      }

      final handled = controller.pop();
      if (handled) {
        if (poppedModal != null) {
          _emitNavigationEvent(
            type: LmNavigationEventType.modalPop,
            source: source,
            from: poppedModal.location,
            to: controller.state.location,
            result: LmNavigationResult.committed,
            startedAt: startedAt,
          );
        }
        _emitNavigationEvent(
          type: LmNavigationEventType.navigateCommit,
          source: source,
          from: from,
          to: controller.state.location,
          result: LmNavigationResult.committed,
          startedAt: startedAt,
        );
      }
      return _NavigationOutcome<bool>(handled, duration);
    });
  }

  LmNavigationTransaction _beginTransaction({
    required LmNavigationSource source,
    LmLocation? from,
    required LmLocation to,
  }) {
    final id = _nextNavigationId++;
    _currentNavigationId = id;
    final transaction = LmNavigationTransaction(
      id: id,
      source: source,
      from: from ?? controller.state.location,
      to: to,
      startedAt: DateTime.now(),
    );
    _emitNavigationEvent(
      type: LmNavigationEventType.navigateStart,
      source: source,
      from: transaction.from,
      to: transaction.to,
      result: LmNavigationResult.cancelled,
      startedAt: transaction.startedAt,
    );
    return transaction;
  }

  void _invalidatePendingNavigation() {
    _currentNavigationId = _nextNavigationId++;
  }

  bool _isNavigationCurrent(int navigationId) {
    return navigationId == _currentNavigationId;
  }

  void _handleRefresh() {
    final location = currentConfiguration;
    if (location == null) {
      return;
    }
    unawaited(go(location, source: LmNavigationSource.restore));
  }

  bool _stackContainsPage(Page<Object?> page) {
    final branch = controller.state.branches[controller.state.activeBranchId];
    if (branch == null) {
      return false;
    }
    return branch.semanticStack.any(
      (node) => node.location.canonical == page.name,
    );
  }

  bool _modalStackContainsPage(Page<Object?> page) {
    return controller.state.modalStack.any(
      (node) => node.location.canonical == page.name,
    );
  }

  @override
  Future<bool> popRoute() {
    if (controller.consumeSuppressedSystemBack()) {
      _traceBack('popRoute.suppressed', result: true);
      return Future<bool>.value(true);
    }
    if (controller.state.modalStack.isEmpty && _hasQueuedTransition) {
      _traceBack('popRoute.transition-pending', result: true);
      return Future<bool>.value(true);
    }
    return _enqueuePopNavigation(() async {
      final target = _locationAfterPop();
      if (target == null) {
        _traceBack('popRoute.controller', result: false);
        return const _NavigationOutcome<bool>(false, Duration.zero);
      }
      final duration = _currentReverseDuration();
      final from = currentConfiguration ?? controller.state.location;
      final startedAt = DateTime.now();
      final poppedModal = controller.state.modalStack.lastOrNull;
      final transaction = _beginTransaction(
        source: LmNavigationSource.systemBack,
        from: currentConfiguration,
        to: target,
      );
      final guardResult = await _guardPipeline.evaluatePop(transaction);
      switch (guardResult) {
        case LmGuardAllowed(:final transaction):
          _emitGuardNavigationAllow(guardResult);
          if (transaction.to.canonical != target.canonical) {
            final outcome = _presentAllowed(transaction.to);
            _traceBack('popRoute.redirect', result: true);
            return _NavigationOutcome<bool>(true, outcome.settleDuration);
          }
        case LmGuardBlocked():
        case LmGuardRedirectLoop():
        case LmGuardStale():
        case LmGuardErrored():
          _emitGuardNavigationStop(guardResult);
          _traceBack('popRoute.guard-blocked', result: true);
          return const _NavigationOutcome<bool>(true, Duration.zero);
      }
      final handled =
          controller.handleBack(source: LmNavigationSource.systemBack) ==
          LmBackResult.handled;
      if (handled && poppedModal != null) {
        _emitNavigationEvent(
          type: LmNavigationEventType.modalPop,
          source: LmNavigationSource.systemBack,
          from: from,
          to: controller.state.location,
          result: LmNavigationResult.committed,
          startedAt: startedAt,
        );
      }
      _traceBack('popRoute.controller', result: handled);
      return _NavigationOutcome<bool>(handled, duration);
    }, waitForIdle: false);
  }

  LmLocation? _locationAfterPop() {
    final modalStack = controller.state.modalStack;
    if (modalStack.length > 1) {
      return modalStack[modalStack.length - 2].location;
    }
    if (modalStack.isNotEmpty) {
      final branch = controller.state.branches[controller.state.activeBranchId];
      return branch?.semanticStack.lastOrNull?.location ??
          controller.state.location;
    }

    final branch = controller.state.branches[controller.state.activeBranchId];
    final stack = branch?.semanticStack;
    if (stack == null || stack.length <= 1) {
      return null;
    }
    return stack[stack.length - 2].location;
  }

  Future<bool> _enqueuePopNavigation(
    Future<_NavigationOutcome<bool>> Function() action, {
    bool waitForIdle = true,
  }) {
    final pending = _pendingPopNavigation;
    if (pending != null) {
      return pending;
    }
    final future = _enqueueNavigation<bool>(action, waitForIdle: waitForIdle);
    _pendingPopNavigation = future;
    future.whenComplete(() {
      if (identical(_pendingPopNavigation, future)) {
        _pendingPopNavigation = null;
      }
    });
    return future;
  }

  Future<T> _enqueueNavigation<T>(
    Future<_NavigationOutcome<T>> Function() action, {
    bool waitForIdle = true,
  }) {
    final previous = _navigationQueue;
    final operation = previous.catchError((_) {}).then((_) async {
      if (waitForIdle) {
        await _waitForTransitionIdle();
      }
      final outcome = await action();
      _markTransitionPending(outcome.settleDuration);
      return outcome.value;
    });
    _navigationQueueIdle = false;
    final queueCompletion = operation.then<void>((_) {}, onError: (_) {});
    _navigationQueue = queueCompletion;
    queueCompletion.whenComplete(() {
      if (identical(_navigationQueue, queueCompletion)) {
        _navigationQueueIdle = true;
      }
    });
    return operation;
  }

  Future<void> _waitForTransitionIdle() async {
    if (!_needsTransitionDrain) {
      return;
    }
    if (_transitionMarkedBeforeFrame) {
      await WidgetsBinding.instance.endOfFrame;
      _transitionMarkedBeforeFrame = false;
    }
    _needsTransitionDrain = false;
    final deadline = _transitionSettleDeadline;
    while (SchedulerBinding.instance.transientCallbackCount > 0) {
      if (deadline != null && !DateTime.now().isBefore(deadline)) {
        _transitionSettleDeadline = null;
        break;
      }
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  void _markTransitionPending(Duration duration) {
    if (duration <= Duration.zero) {
      return;
    }
    _transitionSettleDeadline = DateTime.now().add(duration);
    _needsTransitionDrain = true;
    _transitionMarkedBeforeFrame = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transitionMarkedBeforeFrame = false;
      if (SchedulerBinding.instance.transientCallbackCount == 0) {
        _needsTransitionDrain = false;
      }
    });
  }

  bool get _hasQueuedTransition {
    final deadline = _transitionSettleDeadline;
    if (deadline == null) {
      return false;
    }
    final isPending = DateTime.now().isBefore(deadline);
    if (!isPending) {
      _transitionSettleDeadline = null;
    }
    return isPending;
  }

  void _emitNavigationEvent({
    required LmNavigationEventType type,
    required LmNavigationSource source,
    required LmLocation? from,
    required LmLocation to,
    required LmNavigationResult result,
    required DateTime startedAt,
    Object? error,
  }) {
    _diagnostics?.emit(
      LmNavigationEvent(
        type: type,
        source: source,
        from: from,
        to: to,
        result: result,
        duration: DateTime.now().difference(startedAt),
        error: error,
      ),
    );
  }

  void _emitGuardNavigationStop(LmGuardEvaluationResult result) {
    final transaction = result.transaction;
    switch (result) {
      case LmGuardBlocked(:final reason):
        _emitNavigationEvent(
          type: LmNavigationEventType.guardBlock,
          source: transaction.source,
          from: transaction.from,
          to: transaction.to,
          result: LmNavigationResult.blocked,
          startedAt: transaction.startedAt,
          error: reason,
        );
        _emitNavigationEvent(
          type: LmNavigationEventType.navigateCancel,
          source: transaction.source,
          from: transaction.from,
          to: transaction.to,
          result: LmNavigationResult.blocked,
          startedAt: transaction.startedAt,
          error: reason,
        );
      case LmGuardRedirectLoop(:final locations):
        final locationTrace = locations
            .map((location) => location.canonical)
            .toList(growable: false);
        _emitNavigationEvent(
          type: LmNavigationEventType.redirectLoopDetected,
          source: transaction.source,
          from: transaction.from,
          to: transaction.to,
          result: LmNavigationResult.failed,
          startedAt: transaction.startedAt,
          error: locationTrace,
        );
        _emitNavigationEvent(
          type: LmNavigationEventType.navigateCancel,
          source: transaction.source,
          from: transaction.from,
          to: transaction.to,
          result: LmNavigationResult.failed,
          startedAt: transaction.startedAt,
          error: locationTrace,
        );
      case LmGuardStale():
        _emitNavigationEvent(
          type: LmNavigationEventType.navigateCancel,
          source: transaction.source,
          from: transaction.from,
          to: transaction.to,
          result: LmNavigationResult.cancelled,
          startedAt: transaction.startedAt,
        );
      case LmGuardErrored(:final error):
        _emitNavigationEvent(
          type: LmNavigationEventType.navigateError,
          source: transaction.source,
          from: transaction.from,
          to: transaction.to,
          result: LmNavigationResult.failed,
          startedAt: transaction.startedAt,
          error: error,
        );
        _emitNavigationEvent(
          type: LmNavigationEventType.navigateCancel,
          source: transaction.source,
          from: transaction.from,
          to: transaction.to,
          result: LmNavigationResult.failed,
          startedAt: transaction.startedAt,
          error: error,
        );
      case LmGuardAllowed():
        return;
    }
  }

  void _emitGuardNavigationAllow(LmGuardEvaluationResult result) {
    if (_guards.isEmpty) {
      return;
    }
    final transaction = result.transaction;
    _emitNavigationEvent(
      type: LmNavigationEventType.guardAllow,
      source: transaction.source,
      from: transaction.from,
      to: transaction.to,
      result: LmNavigationResult.committed,
      startedAt: transaction.startedAt,
    );
  }

  void _traceBack(String event, {required bool result}) {
    if (!_lmTraceRouter) {
      return;
    }
    final state = controller.state;
    final branch = state.branches[state.activeBranchId];
    final stack =
        branch?.semanticStack
            .map((node) => node.location.canonical)
            .join('|') ??
        '';
    final modals = state.modalStack
        .map((node) => node.location.canonical)
        .join('|');
    _lmTraceRouterEvent(
      'router event=$event result=$result active=${state.activeBranchId} '
      'stack=$stack modals=$modals location=${state.location.canonical}',
    );
  }

  Duration _currentReverseDuration() {
    final modal = controller.state.modalStack.lastOrNull;
    if (modal != null) {
      return _modalReverseDurationForLocation(modal.location);
    }
    final branch = controller.state.branches[controller.state.activeBranchId];
    final current = branch?.semanticStack.lastOrNull;
    if (current == null) {
      return Duration.zero;
    }
    return _reverseDurationForLocation(current.location);
  }

  Duration _forwardDurationForLocation(LmLocation location) {
    final modalDuration = _modalForwardDurationForLocation(location);
    if (modalDuration != null) {
      return modalDuration;
    }
    final route = _matcher.match(location.canonical).route;
    return (route?.transition ?? const LmTransition.cupertino()).duration;
  }

  Duration _routeForwardDurationForNode(LmRouteNode node) {
    return (_routeForNode(node)?.transition ?? const LmTransition.cupertino())
        .duration;
  }

  Duration _reverseDurationForLocation(LmLocation location) {
    final route = _matcher.match(location.canonical).route;
    return (route?.transition ?? const LmTransition.cupertino())
        .reverseDuration;
  }

  Duration? _modalForwardDurationForLocation(LmLocation location) {
    final presentation = _matchModal(location)?.route.presentation;
    if (presentation == null) {
      return null;
    }
    return _effectiveModalDuration(presentation, reverse: false);
  }

  Duration _modalReverseDurationForLocation(LmLocation location) {
    final presentation = _matchModal(location)?.route.presentation;
    if (presentation == null) {
      return Duration.zero;
    }
    return _effectiveModalDuration(presentation, reverse: true) ??
        Duration.zero;
  }

  Duration? _effectiveModalDuration(
    LmModalPresentation presentation, {
    required bool reverse,
  }) {
    if (presentation.transition is LmNoTransition) {
      return Duration.zero;
    }
    return switch (presentation.kind) {
      LmModalPresentationKind.dialog ||
      LmModalPresentationKind.cupertinoDialog =>
        _lmCupertinoDialogRouteDuration,
      LmModalPresentationKind.actionSheet =>
        _lmCupertinoModalSheetRouteDuration,
      LmModalPresentationKind.bottomSheet when !presentation.fullscreen =>
        _lmCupertinoModalSheetRouteDuration,
      _ =>
        reverse
            ? presentation.transition.reverseDuration
            : presentation.transition.duration,
    };
  }

  LmNavigationState _stateFor(LmLocation location) {
    if (_matchModal(location) != null) {
      final background = _backgroundLocationForModal(location);
      final modalNode = _tryModalNodeFor(location);
      if (modalNode == null) {
        final stack = [_notFoundNode(location)];
        return LmNavigationState(
          activeBranchId: 'root',
          branches: {
            'root': LmBranchState(branchId: 'root', semanticStack: stack),
          },
          location: location,
        );
      }
      final state = _stateFor(background);
      return state.copyWith(modalStack: [modalNode]);
    }
    if (_branchPatterns.isNotEmpty) {
      return _branchedStateFor(location);
    }
    final stack = _stackFor(location);
    final node = stack.last;
    return LmNavigationState(
      activeBranchId: 'root',
      branches: {'root': LmBranchState(branchId: 'root', semanticStack: stack)},
      location: node.location,
    );
  }

  LmNavigationState _branchedStateFor(LmLocation location) {
    final activeBranch = _branchForLocation(location) ?? _branchPatterns.first;
    final branchStates = <String, LmBranchState>{};
    for (final branch in _branchPatterns) {
      final isActive = branch.id == activeBranch.id;
      final rootLocation = branch.rootLocation;
      final stack = isActive ? _stackFor(location) : _stackFor(rootLocation);
      branchStates[branch.id] = LmBranchState(
        branchId: branch.id,
        semanticStack: stack,
      );
    }
    final activeStack = branchStates[activeBranch.id]!.semanticStack;
    final activeLocation = activeStack.last.location;
    return LmNavigationState(
      activeBranchId: activeBranch.id,
      branches: branchStates,
      location: activeLocation,
    );
  }

  bool _branchOwnsLocation(_BranchPattern branch, LmLocation location) {
    for (final ownedLocation in branch.ownedLocations) {
      if (_pathContains(ownedLocation.path, location.path)) {
        return true;
      }
    }
    return false;
  }

  _BranchPattern? _branchForLocation(LmLocation location) {
    for (final branch in _branchPatterns) {
      if (_branchOwnsLocation(branch, location)) {
        return branch;
      }
    }
    return null;
  }

  void _goStackForLocation(LmLocation location, List<LmRouteNode> stack) {
    final targetBranch = _branchForLocation(location);
    if (targetBranch == null) {
      controller.goStack(stack);
      return;
    }
    controller.goStackInBranch(targetBranch.id, stack);
  }

  List<LmRouteNode> _stackFor(LmLocation location) {
    final cacheKey = location.extra == null ? location.canonical : null;
    final cached = cacheKey == null ? null : _stackCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final match = _matcher.match(location.canonical);
    if (!match.isMatch) {
      return _cacheStack(cacheKey, [_nodeFor(location)]);
    }
    if (match.remaining.isNotEmpty) {
      return _cacheStack(cacheKey, [_notFoundNode(location)]);
    }
    if (match.routeChain.length > 1) {
      final stack = _stackFromRouteChain(location, match.routeChain);
      if (stack != null) {
        return _cacheStack(cacheKey, stack);
      }
      return _cacheStack(cacheKey, [_notFoundNode(location)]);
    }

    final targetSegments = _splitPath(location.path);
    final candidates = <_RouteStackCandidate>[];
    for (final pattern in _candidateRoutePatterns(targetSegments)) {
      final candidate = _matchRoutePrefix(pattern, targetSegments);
      if (candidate == null) {
        continue;
      }
      if (candidate.consumed == 0 && targetSegments.isNotEmpty) {
        continue;
      }
      candidates.add(candidate);
    }

    candidates.sort((left, right) => left.consumed.compareTo(right.consumed));
    final stack = <LmRouteNode>[];
    for (final candidate in candidates) {
      final node = _tryNodeForRoute(candidate, location, targetSegments);
      if (node == null) {
        return _cacheStack(cacheKey, [_notFoundNode(location)]);
      }
      stack.add(node);
    }
    if (stack.isEmpty || stack.last.pathPattern != match.route!.path) {
      stack.add(_nodeFor(location));
    }
    return _cacheStack(cacheKey, stack);
  }

  Iterable<_RoutePattern> _candidateRoutePatterns(List<String> targetSegments) {
    if (targetSegments.isEmpty) {
      return _routePatternsByFirstSegment[''] ?? const <_RoutePattern>[];
    }
    return [
      ...?_routePatternsByFirstSegment[''],
      ...?_routePatternsByFirstSegment[targetSegments.first],
      ...?_routePatternsByFirstSegment[':'],
      ...?_routePatternsByFirstSegment['*'],
    ];
  }

  List<LmRouteNode>? _stackFromRouteChain(
    LmLocation target,
    List<LmRouteDefinition<Object?>> routeChain,
  ) {
    final targetSegments = _splitPath(target.path);
    final stack = <LmRouteNode>[];
    var consumed = 0;
    final pathParameters = <String, String>{};

    for (final route in routeChain) {
      final routeSegments = _splitPath(route.path);
      for (var index = 0; index < routeSegments.length; index += 1) {
        final routeSegment = routeSegments[index];
        if (routeSegment == '*') {
          pathParameters['*'] = _decodedSegmentsFrom(targetSegments, consumed);
          consumed = targetSegments.length;
          break;
        }
        if (consumed >= targetSegments.length) {
          return null;
        }
        final targetSegment = targetSegments[consumed];
        if (routeSegment.startsWith(':')) {
          pathParameters[routeSegment.substring(1)] = Uri.decodeComponent(
            targetSegment,
          );
        } else if (routeSegment != targetSegment) {
          return null;
        }
        consumed += 1;
      }

      final isTarget = identical(route, routeChain.last);
      final Object? params;
      try {
        params = route.decodeParams(pathParameters);
      } on Object {
        return null;
      }
      stack.add(
        LmRouteNode(
          name: route.name,
          pathPattern: route.path,
          location: LmLocation(
            path: _locationFromSegments(targetSegments, end: consumed),
            query: isTarget ? target.query : const {},
            fragment: isTarget ? target.fragment : null,
            extra: isTarget ? target.extra : null,
          ),
          params: params,
          query: isTarget ? target.query : const {},
          chrome: route.chrome,
          detailPolicy: route.detailPolicy,
        ),
      );
    }

    return stack;
  }

  List<LmRouteNode> _cacheStack(String? cacheKey, List<LmRouteNode> stack) {
    if (cacheKey == null) {
      return stack;
    }
    final immutableStack = List<LmRouteNode>.unmodifiable(stack);
    _trimCache(_stackCache);
    _stackCache[cacheKey] = immutableStack;
    return immutableStack;
  }

  LmRouteNode _nodeFor(LmLocation location) {
    final match = _matcher.match(location.canonical);
    if (!match.isMatch || match.remaining.isNotEmpty) {
      return _notFoundNode(location);
    }

    final route = match.route!;
    final Object? params;
    try {
      params = route.decodeParams(match.pathParameters);
    } on Object {
      return _notFoundNode(location);
    }
    return LmRouteNode(
      name: route.name,
      pathPattern: route.path,
      location: location.copyWith(path: match.matchedLocation),
      params: params,
      query: location.query,
      chrome: route.chrome,
      detailPolicy: route.detailPolicy,
    );
  }

  LmRouteNode? _tryNodeForRoute(
    _RouteStackCandidate candidate,
    LmLocation target,
    List<String> targetSegments,
  ) {
    final route = candidate.route;
    final path = _locationFromSegments(targetSegments, end: candidate.consumed);
    final isTarget = candidate.consumed == targetSegments.length;
    final Object? params;
    try {
      params = route.decodeParams(candidate.pathParameters);
    } on Object {
      return null;
    }
    return LmRouteNode(
      name: route.name,
      pathPattern: route.path,
      location: LmLocation(
        path: path,
        query: isTarget ? target.query : const {},
        fragment: isTarget ? target.fragment : null,
        extra: isTarget ? target.extra : null,
      ),
      params: params,
      query: isTarget ? target.query : const {},
      chrome: route.chrome,
      detailPolicy: route.detailPolicy,
    );
  }

  LmRouteNode _notFoundNode(LmLocation location) {
    final route = _notFoundRoute;
    if (route == null) {
      final fallback = _routes.isEmpty
          ? null
          : _matcher.match('/').route ?? _routes.first;
      if (fallback == null) {
        throw StateError('No routes are registered.');
      }
      return LmRouteNode(
        name: fallback.name,
        pathPattern: fallback.path,
        location: location,
        params: null,
        query: location.query,
        chrome: fallback.chrome,
        detailPolicy: fallback.detailPolicy,
      );
    }
    return LmRouteNode(
      name: route.name,
      pathPattern: route.path,
      location: location,
      params: null,
      query: location.query,
      chrome: route.chrome,
      detailPolicy: route.detailPolicy,
    );
  }

  Page<void> buildProjectedPage(BuildContext context, LmRouteNode node) {
    final child = _buildRouteWidget(context, node);
    final route = _routeForNode(node);
    final transition = route?.transition;
    return LmPageFactory.page(
      key: ValueKey<String>('projected-${node.location.canonical}'),
      name: node.location.canonical,
      child: child,
      transition: _transitionPolicy.resolve(
        context: context,
        route: transition,
      ),
      onPopGestureStart: controller.suppressNextSystemBack,
    );
  }

  Page<void> buildProjectedModalPage(BuildContext context, LmModalNode node) {
    return _buildModalPage(context, node);
  }

  Page<void> _buildPage(BuildContext context, LmRouteNode node) {
    final child = _buildRouteWidget(context, node);
    final route = _routeForNode(node);
    final transition = route?.transition;
    return LmPageFactory.page(
      key: ValueKey<String>(node.location.canonical),
      name: node.location.canonical,
      child: child,
      transition: _transitionPolicy.resolve(
        context: context,
        route: transition,
      ),
      onPopGestureStart: controller.suppressNextSystemBack,
    );
  }

  Widget _buildRouteWidget(BuildContext context, LmRouteNode node) {
    final notFoundRoute = _notFoundRoute;
    if (notFoundRoute != null && node.name == notFoundRoute.name) {
      return notFoundRoute.buildWidget(context, node.params);
    }
    final route = _routeForNode(node);
    return route?.buildWidget(context, node.params) ?? const SizedBox.shrink();
  }

  LmRouteDefinition<Object?>? _routeForNode(LmRouteNode node) {
    return _routesByPathPattern[node.pathPattern];
  }

  Page<void> _buildModalPage(BuildContext context, LmModalNode node) {
    final route = _modalRoutesByName[node.name];
    final child =
        route?.buildWidget(context, node.params) ?? const SizedBox.shrink();
    final presentation = route?.presentation;
    if (presentation == null) {
      return LmNoTransitionPage<void>(
        key: ValueKey<String>(node.location.canonical),
        name: node.location.canonical,
        child: child,
      );
    }
    return LmPageFactory.modalPage(
      key: ValueKey<String>(node.location.canonical),
      name: node.location.canonical,
      child: child,
      presentation: _resolveModalPresentation(context, presentation),
      restorationId: route?.restorationId,
    );
  }

  LmModalPresentation _resolveModalPresentation(
    BuildContext context,
    LmModalPresentation presentation,
  ) {
    final transition = _transitionPolicy.resolve(
      context: context,
      route: presentation.transition,
    );
    return switch (presentation.kind) {
      LmModalPresentationKind.dialog => LmModalPresentation.dialog(
        barrierDismissible: presentation.barrierDismissible,
        usesSafeArea: presentation.usesSafeArea,
        transition: transition,
      ),
      LmModalPresentationKind.cupertinoDialog =>
        LmModalPresentation.cupertinoDialog(
          barrierDismissible: presentation.barrierDismissible,
          usesSafeArea: presentation.usesSafeArea,
          transition: transition,
        ),
      LmModalPresentationKind.bottomSheet => LmModalPresentation.bottomSheet(
        barrierDismissible: presentation.barrierDismissible,
        usesSafeArea: presentation.usesSafeArea,
        fullscreen: presentation.fullscreen,
        transition: transition,
      ),
      LmModalPresentationKind.actionSheet => LmModalPresentation.actionSheet(
        barrierDismissible: presentation.barrierDismissible,
        usesSafeArea: presentation.usesSafeArea,
        transition: transition,
      ),
      LmModalPresentationKind.fullscreenDialog =>
        LmModalPresentation.fullscreenDialog(
          barrierDismissible: presentation.barrierDismissible,
          usesSafeArea: presentation.usesSafeArea,
          transition: transition,
        ),
      LmModalPresentationKind.popover => LmModalPresentation.popover(
        barrierDismissible: presentation.barrierDismissible,
        usesSafeArea: presentation.usesSafeArea,
        transition: transition,
      ),
    };
  }

  LmModalNode? _tryModalNodeFor(LmLocation location) {
    final match = _matchModal(location);
    if (match == null) {
      throw StateError('No modal route matches ${location.canonical}.');
    }
    final Object? params;
    try {
      params = match.route.decodeParams(match.params);
    } on Object {
      return null;
    }
    return LmModalNode(
      name: match.route.name,
      location: location.copyWith(path: match.matchedLocation),
      params: params,
      query: location.query,
    );
  }

  _ModalRouteMatch? _matchModal(LmLocation location) {
    final cacheKey = location.path;
    if (_modalMatchCache.containsKey(cacheKey)) {
      return _modalMatchCache[cacheKey];
    }
    final targetSegments = _splitPath(location.path);
    for (final pattern in _modalRoutePatterns) {
      final route = pattern.route;
      final routeSegments = pattern.segments;
      if (routeSegments.length != targetSegments.length) {
        continue;
      }
      final params = <String, String>{};
      var matched = true;
      for (var i = 0; i < routeSegments.length; i += 1) {
        final routeSegment = routeSegments[i];
        final targetSegment = targetSegments[i];
        if (routeSegment.startsWith(':')) {
          params[routeSegment.substring(1)] = Uri.decodeComponent(
            targetSegment,
          );
          continue;
        }
        if (routeSegment != targetSegment) {
          matched = false;
          break;
        }
      }
      if (matched) {
        final match = _ModalRouteMatch(
          route: route,
          params: params,
          matchedLocation: _locationFromSegments(targetSegments),
        );
        _cacheModalMatch(cacheKey, match);
        return match;
      }
    }
    _cacheModalMatch(cacheKey, null);
    return null;
  }

  void _cacheModalMatch(String cacheKey, _ModalRouteMatch? match) {
    _trimCache(_modalMatchCache);
    _modalMatchCache[cacheKey] = match;
  }

  static void _trimCache<T>(Map<String, T> cache) {
    if (cache.length < _lmRouteCacheLimit) {
      return;
    }
    cache.remove(cache.keys.first);
  }

  LmLocation _backgroundLocationForModal(LmLocation location) {
    final targetSegments = _splitPath(location.path);
    for (var count = targetSegments.length - 1; count >= 0; count -= 1) {
      final candidate = location.copyWith(
        path: _locationFromSegments(targetSegments, end: count),
        query: const {},
        fragment: null,
        extra: null,
      );
      final match = _matcher.match(candidate.canonical);
      if (match.isMatch && match.remaining.isEmpty) {
        return candidate;
      }
    }
    return location.copyWith(path: '/', query: const {}, fragment: null);
  }

  static Map<String, LmRouteDefinition<Object?>> _indexRoutesByPathPattern(
    List<LmRouteDefinition<Object?>> routes,
  ) {
    final indexed = <String, LmRouteDefinition<Object?>>{};
    for (final route in routes) {
      indexed[route.path] = route;
      indexed.addAll(_indexRoutesByPathPattern(route.children));
    }
    return indexed;
  }

  static void _validateRouteDefinitions(
    List<LmRouteDefinition<Object?>> routes,
  ) {
    final paths = <String>{};
    final names = <String>{};
    for (final route in _flattenRoutes(routes)) {
      if (!paths.add(route.path)) {
        throw ArgumentError.value(
          route.path,
          'routes',
          'Duplicate route path.',
        );
      }
      if (!names.add(route.name)) {
        throw ArgumentError.value(
          route.name,
          'routes',
          'Duplicate route name.',
        );
      }
    }
  }

  static Iterable<LmRouteDefinition<Object?>> _flattenRoutes(
    List<LmRouteDefinition<Object?>> routes,
  ) sync* {
    for (final route in routes) {
      yield route;
      yield* _flattenRoutes(route.children);
    }
  }

  static void _validateModalRouteDefinitions(
    Iterable<LmModalRouteDefinition<Object?>> routes,
  ) {
    final paths = <String>{};
    final names = <String>{};
    for (final route in routes) {
      if (!paths.add(route.path)) {
        throw ArgumentError.value(
          route.path,
          'modalRoutes',
          'Duplicate modal route path.',
        );
      }
      if (!names.add(route.name)) {
        throw ArgumentError.value(
          route.name,
          'modalRoutes',
          'Duplicate modal route name.',
        );
      }
    }
  }

  static void _validateBranchPatterns(List<_BranchPattern> branches) {
    final ids = <String>{};
    final roots = <String>{};
    for (final branch in branches) {
      if (!ids.add(branch.id)) {
        throw ArgumentError.value(
          branch.id,
          'branches',
          'Duplicate branch id.',
        );
      }
      if (!roots.add(branch.rootLocation.path)) {
        throw ArgumentError.value(
          branch.rootLocation.path,
          'branches',
          'Duplicate branch root.',
        );
      }
    }
  }

  static List<_RoutePattern> _indexRoutePatterns(
    List<LmRouteDefinition<Object?>> routes,
  ) {
    return [
      for (final route in routes) ...[
        _RoutePattern(route: route, segments: _splitPath(route.path)),
        ..._indexRoutePatterns(route.children),
      ],
    ];
  }

  static Map<String, List<_RoutePattern>> _indexRoutePatternsByFirstSegment(
    List<LmRouteDefinition<Object?>> routes,
  ) {
    final indexed = <String, List<_RoutePattern>>{};
    for (final pattern in _indexRoutePatterns(routes)) {
      final firstSegment = pattern.segments.isEmpty
          ? ''
          : pattern.segments.first;
      final key = firstSegment.startsWith(':') ? ':' : firstSegment;
      (indexed[key] ??= <_RoutePattern>[]).add(pattern);
    }
    return {
      for (final entry in indexed.entries)
        entry.key: List<_RoutePattern>.unmodifiable(entry.value),
    };
  }

  static List<_ModalRoutePattern> _indexModalRoutePatterns(
    List<LmModalRouteDefinition<Object?>> routes,
  ) {
    return [
      for (final route in routes)
        _ModalRoutePattern(route: route, segments: _splitPath(route.path)),
    ];
  }

  static Map<String, LmModalRouteDefinition<Object?>> _indexModalRoutesByName(
    List<LmModalRouteDefinition<Object?>> routes,
  ) {
    return {for (final route in routes) route.name: route};
  }

  static List<_BranchPattern> _indexBranchPatterns(List<LmBranch> branches) {
    final patterns = <_BranchPattern>[];
    for (final branch in branches) {
      final rootLocation = _locationFrom(branch.root);
      patterns.add(
        _BranchPattern(
          id: branch.id,
          rootLocation: rootLocation,
          switchPolicy: branch.switchPolicy,
          ownedLocations: [
            rootLocation,
            for (final route in branch.routes) _locationFrom(route),
          ],
        ),
      );
    }
    return patterns;
  }

  static _RouteStackCandidate? _matchRoutePrefix(
    _RoutePattern pattern,
    List<String> targetSegments,
  ) {
    final route = pattern.route;
    final routeSegments = pattern.segments;
    if (routeSegments.length > targetSegments.length) {
      return null;
    }

    final params = <String, String>{};
    for (var i = 0; i < routeSegments.length; i += 1) {
      final routeSegment = routeSegments[i];
      final targetSegment = targetSegments[i];
      if (routeSegment == '*') {
        params['*'] = _decodedSegmentsFrom(targetSegments, i);
        return _RouteStackCandidate(
          route: route,
          consumed: targetSegments.length,
          pathParameters: params,
        );
      }
      if (routeSegment.startsWith(':')) {
        params[routeSegment.substring(1)] = Uri.decodeComponent(targetSegment);
        continue;
      }
      if (routeSegment != targetSegment) {
        return null;
      }
    }

    return _RouteStackCandidate(
      route: route,
      consumed: routeSegments.length,
      pathParameters: params,
    );
  }

  static List<String> _splitPath(String path) {
    if (path.isEmpty || path == '/') {
      return const [];
    }
    final segments = <String>[];
    var segmentStart = path.startsWith('/') ? 1 : 0;
    for (var index = segmentStart; index <= path.length; index += 1) {
      if (index != path.length && path.codeUnitAt(index) != 47) {
        continue;
      }
      if (index > segmentStart) {
        segments.add(path.substring(segmentStart, index));
      }
      segmentStart = index + 1;
    }
    return segments;
  }

  static String _locationFromSegments(List<String> segments, {int? end}) {
    final effectiveEnd = end ?? segments.length;
    if (effectiveEnd <= 0) {
      return '/';
    }
    final buffer = StringBuffer();
    for (var index = 0; index < effectiveEnd; index += 1) {
      buffer
        ..write('/')
        ..write(segments[index]);
    }
    return buffer.toString();
  }

  static String _decodedSegmentsFrom(List<String> segments, int start) {
    final buffer = StringBuffer();
    for (var index = start; index < segments.length; index += 1) {
      if (index > start) {
        buffer.write('/');
      }
      buffer.write(Uri.decodeComponent(segments[index]));
    }
    return buffer.toString();
  }

  static bool _pathContains(String rootPath, String targetPath) {
    if (rootPath == '/') {
      return targetPath == '/';
    }
    return targetPath == rootPath || targetPath.startsWith('$rootPath/');
  }

  _BranchPattern? _branchPatternById(String branchId) {
    for (final branch in _branchPatterns) {
      if (branch.id == branchId) {
        return branch;
      }
    }
    return null;
  }

  static LmLocation _locationFrom(Object location) {
    return switch (location) {
      LmRouteLocation() => location.location,
      LmLocation() => location,
      Uri() => LmLocation.fromUri(location),
      String() => LmLocation.fromUri(Uri.parse(location)),
      _ => throw ArgumentError.value(
        location,
        'location',
        'Expected LmRouteLocation, String, Uri, or LmLocation.',
      ),
    };
  }
}

final class _RouteStackCandidate {
  const _RouteStackCandidate({
    required this.route,
    required this.consumed,
    required this.pathParameters,
  });

  final LmRouteDefinition<Object?> route;
  final int consumed;
  final Map<String, String> pathParameters;
}

final class _RoutePattern {
  const _RoutePattern({required this.route, required this.segments});

  final LmRouteDefinition<Object?> route;
  final List<String> segments;
}

final class _ModalRoutePattern {
  const _ModalRoutePattern({required this.route, required this.segments});

  final LmModalRouteDefinition<Object?> route;
  final List<String> segments;
}

final class _BranchPattern {
  const _BranchPattern({
    required this.id,
    required this.rootLocation,
    required this.switchPolicy,
    required this.ownedLocations,
  });

  final String id;
  final LmLocation rootLocation;
  final LmBranchSwitchPolicy switchPolicy;
  final List<LmLocation> ownedLocations;
}

final class _ModalRouteMatch {
  const _ModalRouteMatch({
    required this.route,
    required this.params,
    required this.matchedLocation,
  });

  final LmModalRouteDefinition<Object?> route;
  final Map<String, String> params;
  final String matchedLocation;
}

final class _NavigationOutcome<T> {
  const _NavigationOutcome(this.value, this.settleDuration);

  final T value;
  final Duration settleDuration;
}
