enum LmBranchSwitchPolicy {
  preserveStack,
  popToRootOnReselect,
  restoreLastLocation,
}

final class LmBranch {
  const LmBranch({
    required this.id,
    required this.root,
    this.routes = const [],
    this.switchPolicy = LmBranchSwitchPolicy.preserveStack,
  });

  final String id;
  final Object root;
  final List<Object> routes;
  final LmBranchSwitchPolicy switchPolicy;
}
