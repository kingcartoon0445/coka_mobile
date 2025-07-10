Map? findBranchWithParentId(List<dynamic> tree, String? parentId) {
  for (var node in tree) {
    if (node['id'] == parentId) {
      return node;
    } else if (node.containsKey('childs')) {
      final List<dynamic> childBranch = node['childs'];
      final Map? result = findBranchWithParentId(childBranch, parentId);
      if (result != null) {
        return result;
      }
    }
  }
  return null;
}
