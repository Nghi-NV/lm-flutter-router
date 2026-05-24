import 'lm_route_node.dart';

final class LmBranchState {
  LmBranchState({
    required this.branchId,
    required List<LmRouteNode> semanticStack,
    List<LmRouteNode> secondaryStack = const [],
  }) : semanticStack = List.unmodifiable(semanticStack),
       secondaryStack = List.unmodifiable(secondaryStack);

  final String branchId;
  final List<LmRouteNode> semanticStack;
  final List<LmRouteNode> secondaryStack;

  LmBranchState copyWith({
    List<LmRouteNode>? semanticStack,
    List<LmRouteNode>? secondaryStack,
  }) {
    return LmBranchState(
      branchId: branchId,
      semanticStack: semanticStack ?? this.semanticStack,
      secondaryStack: secondaryStack ?? this.secondaryStack,
    );
  }
}
