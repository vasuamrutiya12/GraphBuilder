class Node {
  final String id;
  final String label;
  final List<Node> children;
  final Node? parent;
  final int depth;
  bool collapsed;

  Node({
    required this.id,
    required this.label,
    this.children = const [],
    this.parent,
    this.depth = 0,
    this.collapsed = false,
  });

  Node copyWith({
    String? id,
    String? label,
    List<Node>? children,
    Node? parent,
    int? depth,
    bool? collapsed,
  }) {
    return Node(
      id: id ?? this.id,
      label: label ?? this.label,
      children: children ?? this.children,
      parent: parent ?? this.parent,
      depth: depth ?? this.depth,
      collapsed: collapsed ?? this.collapsed,
    );
  }

  // Helper method to check if this node is a leaf (has no children)
  bool get isLeaf => children.isEmpty;

  // Helper method to check if this node is the root (has no parent)
  bool get isRoot => parent == null;

  // Helper method to get all descendants recursively
  List<Node> get allDescendants {
    List<Node> descendants = [];
    for (Node child in children) {
      descendants.add(child);
      descendants.addAll(child.allDescendants);
    }
    return descendants;
  }

  // Helper method to get the path from root to this node
  List<Node> get pathToRoot {
    List<Node> path = [this];
    Node? current = parent;
    while (current != null) {
      path.insert(0, current);
      current = current.parent;
    }
    return path;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Node && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Node(id: $id, label: $label, depth: $depth, children: ${children.length})';
  }
}
