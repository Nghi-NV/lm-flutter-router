import 'lm_adaptive_policy.dart';
import 'lm_detail_policy.dart';
import '../state/lm_navigation_state.dart';
import '../state/lm_route_node.dart';

abstract interface class LmLayoutProjector {
  LmRenderedTree project(LmNavigationState state, LmLayoutMode layoutMode);
}

final class LmDefaultLayoutProjector implements LmLayoutProjector {
  const LmDefaultLayoutProjector();

  @override
  LmRenderedTree project(LmNavigationState state, LmLayoutMode layoutMode) {
    final activeBranch = state.branches[state.activeBranchId];
    if (activeBranch == null || activeBranch.semanticStack.isEmpty) {
      return LmRenderedTree(
        kind: layoutMode == LmLayoutMode.compact
            ? LmRenderedTreeKind.compactStack
            : LmRenderedTreeKind.expandedSplit,
        activeBranchId: state.activeBranchId,
      );
    }

    if (layoutMode == LmLayoutMode.compact) {
      return LmRenderedTree(
        kind: LmRenderedTreeKind.compactStack,
        activeBranchId: state.activeBranchId,
        compactStack: activeBranch.semanticStack,
      );
    }

    final semanticStack = activeBranch.semanticStack;
    final primaryStack = [semanticStack.first];
    final secondaryStack = <LmRouteNode>[];
    final overlayStack = <LmRouteNode>[];
    final modalStack = <LmRouteNode>[];
    for (var index = 1; index < semanticStack.length; index += 1) {
      final node = semanticStack[index];
      if (node.detailPolicy == LmDetailPolicy.replaceSecondary) {
        secondaryStack
          ..clear()
          ..add(node);
      } else if (node.detailPolicy == LmDetailPolicy.modalOnExpanded) {
        modalStack.add(node);
      } else if (_usesSecondaryPane(node)) {
        secondaryStack.add(node);
      } else {
        overlayStack.add(node);
      }
    }

    return LmRenderedTree(
      kind: LmRenderedTreeKind.expandedSplit,
      activeBranchId: state.activeBranchId,
      primaryStack: primaryStack,
      secondaryStack: secondaryStack,
      overlayStack: overlayStack,
      modalStack: modalStack,
    );
  }

  bool _usesSecondaryPane(LmRouteNode node) {
    return node.detailPolicy == LmDetailPolicy.secondaryPaneOnExpanded ||
        node.detailPolicy == LmDetailPolicy.replaceSecondary;
  }
}

enum LmRenderedTreeKind { compactStack, expandedSplit }

final class LmRenderedTree {
  const LmRenderedTree({
    required this.kind,
    required this.activeBranchId,
    this.compactStack = const [],
    this.primaryStack = const [],
    this.secondaryStack = const [],
    this.overlayStack = const [],
    this.modalStack = const [],
  });

  final LmRenderedTreeKind kind;
  final String activeBranchId;
  final List<LmRouteNode> compactStack;
  final List<LmRouteNode> primaryStack;
  final List<LmRouteNode> secondaryStack;
  final List<LmRouteNode> overlayStack;
  final List<LmRouteNode> modalStack;
}
