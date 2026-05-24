import '../core/lm_location.dart';
import 'lm_branch_state.dart';
import 'lm_modal_node.dart';

final class LmNavigationState {
  LmNavigationState({
    required this.activeBranchId,
    required Map<String, LmBranchState> branches,
    required this.location,
    List<LmModalNode> modalStack = const [],
    this.version = 0,
  }) : branches = Map.unmodifiable(branches),
       modalStack = List.unmodifiable(modalStack);

  final String activeBranchId;
  final Map<String, LmBranchState> branches;
  final LmLocation location;
  final List<LmModalNode> modalStack;
  final int version;

  LmNavigationState copyWith({
    String? activeBranchId,
    Map<String, LmBranchState>? branches,
    LmLocation? location,
    List<LmModalNode>? modalStack,
    int? version,
  }) {
    return LmNavigationState(
      activeBranchId: activeBranchId ?? this.activeBranchId,
      branches: branches ?? this.branches,
      location: location ?? this.location,
      modalStack: modalStack ?? this.modalStack,
      version: version ?? this.version + 1,
    );
  }
}
