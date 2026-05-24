import 'package:flutter/foundation.dart';

import '../state/lm_branch_state.dart';
import '../state/lm_modal_node.dart';
import '../state/lm_navigation_state.dart';
import '../state/lm_route_node.dart';
import 'lm_navigation_transaction.dart';

enum LmBackResult { handled, allowSystem }

final class LmNavigationController extends ChangeNotifier {
  LmNavigationController({required LmNavigationState initialState})
    : _state = initialState;

  LmNavigationState _state;
  int _nextTransactionId = 1;
  DateTime? _suppressSystemBackUntil;

  LmNavigationState get state => _state;

  bool get canPop =>
      _state.modalStack.isNotEmpty || _activeBranch().semanticStack.length > 1;

  bool get isSystemBackSuppressed {
    final until = _suppressSystemBackUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void suppressNextSystemBack({
    Duration duration = const Duration(seconds: 2),
  }) {
    _suppressSystemBackUntil = DateTime.now().add(duration);
  }

  bool consumeSuppressedSystemBack() {
    if (!isSystemBackSuppressed) {
      return false;
    }
    _suppressSystemBackUntil = null;
    notifyListeners();
    return true;
  }

  LmNavigationTransaction go(LmRouteNode route) {
    _clearSuppressedSystemBack();
    final branch = _activeBranch();
    final transaction = _transaction(LmNavigationSource.programmaticGo, route);
    if (_state.modalStack.isEmpty &&
        branch.semanticStack.length == 1 &&
        _isSameRoute(branch.semanticStack.first, route)) {
      return transaction;
    }
    _commit(
      _copyWithBranch(
        branch.copyWith(semanticStack: [route]),
        locationRoute: route,
      ),
    );
    return transaction;
  }

  LmNavigationTransaction goStack(List<LmRouteNode> routes) {
    _clearSuppressedSystemBack();
    if (routes.isEmpty) {
      throw ArgumentError.value(routes, 'routes', 'Stack cannot be empty.');
    }
    final branch = _activeBranch();
    final locationRoute = routes.last;
    final transaction = _transaction(
      LmNavigationSource.programmaticGo,
      locationRoute,
    );
    if (_state.modalStack.isEmpty &&
        _isSameStack(branch.semanticStack, routes)) {
      return transaction;
    }
    _commit(
      _copyWithBranch(
        branch.copyWith(semanticStack: routes),
        locationRoute: locationRoute,
      ),
    );
    return transaction;
  }

  LmNavigationTransaction goStackInBranch(
    String branchId,
    List<LmRouteNode> routes,
  ) {
    _clearSuppressedSystemBack();
    if (routes.isEmpty) {
      throw ArgumentError.value(routes, 'routes', 'Stack cannot be empty.');
    }
    final branch = _state.branches[branchId];
    if (branch == null) {
      throw StateError('Branch $branchId does not exist.');
    }
    final locationRoute = routes.last;
    final transaction = _transaction(
      LmNavigationSource.programmaticGo,
      locationRoute,
    );
    if (_state.modalStack.isEmpty &&
        _state.activeBranchId == branchId &&
        _isSameStack(branch.semanticStack, routes)) {
      return transaction;
    }
    _commit(
      _state.copyWith(
        activeBranchId: branchId,
        branches: {
          ..._state.branches,
          branchId: branch.copyWith(semanticStack: routes),
        },
        location: locationRoute.location,
        modalStack: const [],
      ),
    );
    return transaction;
  }

  LmNavigationTransaction push(LmRouteNode route) {
    _clearSuppressedSystemBack();
    final branch = _activeBranch();
    final transaction = _transaction(
      LmNavigationSource.programmaticPush,
      route,
    );
    final current = branch.semanticStack.lastOrNull;
    if (current?.location.canonical == route.location.canonical) {
      if (_isSameRoute(current, route) && _state.modalStack.isEmpty) {
        return transaction;
      }
      final stack = List<LmRouteNode>.of(branch.semanticStack);
      if (stack.isEmpty) {
        stack.add(route);
      } else {
        stack[stack.length - 1] = route;
      }
      _commit(
        _copyWithBranch(
          branch.copyWith(semanticStack: stack),
          locationRoute: route,
        ),
      );
      return transaction;
    }
    _commit(
      _copyWithBranch(
        branch.copyWith(semanticStack: [...branch.semanticStack, route]),
        locationRoute: route,
      ),
    );
    return transaction;
  }

  LmNavigationTransaction replace(LmRouteNode route) {
    _clearSuppressedSystemBack();
    final branch = _activeBranch();
    final stack = List<LmRouteNode>.of(branch.semanticStack);
    if (stack.isEmpty) {
      stack.add(route);
    } else {
      stack[stack.length - 1] = route;
    }
    final transaction = _transaction(
      LmNavigationSource.programmaticReplace,
      route,
    );
    if (_state.modalStack.isEmpty &&
        _isSameStack(branch.semanticStack, stack)) {
      return transaction;
    }
    _commit(
      _copyWithBranch(
        branch.copyWith(semanticStack: stack),
        locationRoute: route,
      ),
    );
    return transaction;
  }

  LmNavigationTransaction present(LmModalNode modal) {
    _clearSuppressedSystemBack();
    final transaction = LmNavigationTransaction(
      id: _nextTransactionId++,
      source: LmNavigationSource.programmaticPush,
      from: _state.location,
      to: modal.location,
      startedAt: DateTime.now(),
    );
    if (_state.modalStack.lastOrNull?.location.canonical ==
        modal.location.canonical) {
      return transaction;
    }
    _commit(_state.copyWith(modalStack: [..._state.modalStack, modal]));
    return transaction;
  }

  void _clearSuppressedSystemBack() {
    _suppressSystemBackUntil = null;
  }

  bool pop() {
    if (_state.modalStack.isNotEmpty) {
      final nextModalStack = List<LmModalNode>.of(_state.modalStack)
        ..removeLast();
      _commit(
        _state.copyWith(
          modalStack: nextModalStack,
          location: _currentRoute()?.location ?? _state.location,
        ),
      );
      return true;
    }

    final branch = _activeBranch();
    if (branch.semanticStack.length <= 1) {
      return false;
    }

    final nextStack = List<LmRouteNode>.of(branch.semanticStack)..removeLast();
    final nextRoute = nextStack.last;
    _commit(
      _copyWithBranch(
        branch.copyWith(semanticStack: nextStack),
        locationRoute: nextRoute,
      ),
    );
    return true;
  }

  LmBackResult handleBack({
    LmNavigationSource source = LmNavigationSource.systemBack,
  }) {
    assert(
      source == LmNavigationSource.systemBack ||
          source == LmNavigationSource.gestureBack ||
          source == LmNavigationSource.programmaticPop,
      'Back handling should use a back-like navigation source.',
    );
    return pop() ? LmBackResult.handled : LmBackResult.allowSystem;
  }

  void switchBranch(String branchId) {
    final branch = _state.branches[branchId];
    if (branch == null || branchId == _state.activeBranchId) {
      return;
    }

    _commit(
      _state.copyWith(
        activeBranchId: branchId,
        location: branch.semanticStack.isEmpty
            ? _state.location
            : branch.semanticStack.last.location,
        modalStack: const [],
      ),
    );
  }

  LmBranchState _activeBranch() {
    final branch = _state.branches[_state.activeBranchId];
    if (branch == null) {
      throw StateError(
        'Active branch ${_state.activeBranchId} does not exist.',
      );
    }
    return branch;
  }

  LmRouteNode? _currentRoute() {
    final branch = _state.branches[_state.activeBranchId];
    if (branch == null || branch.semanticStack.isEmpty) {
      return null;
    }
    return branch.semanticStack.last;
  }

  bool _isSameRoute(LmRouteNode? left, LmRouteNode right) {
    return left?.location == right.location;
  }

  bool _isSameStack(List<LmRouteNode> left, List<LmRouteNode> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index += 1) {
      if (left[index].location != right[index].location) {
        return false;
      }
    }
    return true;
  }

  LmNavigationState _copyWithBranch(
    LmBranchState branch, {
    required LmRouteNode locationRoute,
  }) {
    return _state.copyWith(
      branches: {..._state.branches, branch.branchId: branch},
      location: locationRoute.location,
      modalStack: const [],
    );
  }

  LmNavigationTransaction _transaction(
    LmNavigationSource source,
    LmRouteNode route,
  ) {
    return LmNavigationTransaction(
      id: _nextTransactionId++,
      source: source,
      from: _state.location,
      to: route.location,
      startedAt: DateTime.now(),
    );
  }

  void _commit(LmNavigationState state) {
    _state = state;
    notifyListeners();
  }
}
