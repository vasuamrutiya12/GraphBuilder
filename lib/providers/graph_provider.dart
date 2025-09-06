import 'package:flutter/foundation.dart';
import '../models/node.dart';

class GraphProvider extends ChangeNotifier {
  Node? _root;
  Node? _activeNode;
  int _nextNodeId = 1;
  final int _maxDepth = 100;
  
  // History for undo/redo functionality
  final List<GraphState> _history = [];
  int _historyIndex = -1;
  static const int _maxHistorySize = 50;

  Node? get root => _root;
  Node? get activeNode => _activeNode;
  int get nextNodeId => _nextNodeId;
  int get maxDepth => _maxDepth;

  GraphProvider() {
    _initializeGraph();
  }

  void _initializeGraph() {
    _root = Node(
      id: _nextNodeId.toString(),
      label: _nextNodeId.toString(),
      depth: 0,
    );
    _activeNode = _root;
    _nextNodeId++;
    _saveState();
    notifyListeners();
  }

  void _saveState() {
    // Remove any states after current index (when branching from history)
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    
    // Add new state
    _history.add(GraphState(
      root: _root != null ? _deepCopyNode(_root!) : null,
      activeNodeId: _activeNode?.id,
      nextNodeId: _nextNodeId,
    ));
    
    // Limit history size
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    } else {
      _historyIndex++;
    }
  }

  Node _deepCopyNode(Node node) {
    List<Node> copiedChildren = node.children.map((child) => _deepCopyNode(child)).toList();
    return Node(
      id: node.id,
      label: node.label,
      children: copiedChildren,
      parent: null, // Will be set when building the tree
      depth: node.depth,
    );
  }

  void _rebuildParentReferences(Node? node) {
    if (node == null) return;
    
    for (Node child in node.children) {
      // Create a new child with proper parent reference
      final childIndex = node.children.indexOf(child);
      node.children[childIndex] = child.copyWith(parent: node);
      _rebuildParentReferences(node.children[childIndex]);
    }
  }

  bool addChildToActiveNode() {
    if (_activeNode == null) return false;
    
    // Check depth limit
    if (_activeNode!.depth >= _maxDepth) {
      return false;
    }

    _saveState();

    final newNode = Node(
      id: _nextNodeId.toString(),
      label: _nextNodeId.toString(),
      parent: _activeNode,
      depth: _activeNode!.depth + 1,
    );

    // Create new active node with the child added
    _activeNode = _addChildToNode(_activeNode!, newNode);
    
    // Update root if necessary
    if (_activeNode!.isRoot) {
      _root = _activeNode;
    } else {
      _root = _updateNodeInTree(_root!, _activeNode!);
    }

    _nextNodeId++;
    notifyListeners();
    return true;
  }

  // Toggle node collapse/expand
  void toggleNodeCollapse(String nodeId) {
    final node = _findNodeById(_root!, nodeId);
    if (node == null) return;
    
    _saveState();
    
    // Toggle collapsed state
    if (node.collapsed) {
      node.collapsed = false;
    } else {
      node.collapsed = true;
    }
    
    notifyListeners();
  }

  Node _addChildToNode(Node parent, Node newChild) {
    final updatedChildren = List<Node>.from(parent.children)..add(newChild);
    return parent.copyWith(children: updatedChildren);
  }

  Node _updateNodeInTree(Node root, Node updatedNode) {
    if (root.id == updatedNode.id) {
      print('🔄 Updating node ${root.id} with ${updatedNode.children.length} children');
      return updatedNode;
    }

    final updatedChildren = root.children.map((child) => 
      _updateNodeInTree(child, updatedNode)
    ).toList();

    return root.copyWith(children: updatedChildren);
  }

  void selectNode(String nodeId) {
    if (_root == null) return;
    
    final node = _findNodeById(_root!, nodeId);
    if (node != null) {
      _activeNode = node;
      notifyListeners();
    }
  }

  void deleteNodeWithAnimation(String nodeId, VoidCallback onComplete) {
    // Add a small delay for animation
    Future.delayed(const Duration(milliseconds: 300), () {
      deleteActiveNode();
      onComplete();
    });
  }

  Node? _findNodeById(Node node, String id) {
    if (node.id == id) return node;
    
    for (Node child in node.children) {
      final found = _findNodeById(child, id);
      if (found != null) return found;
    }
    
    return null;
  }

  /// Smart deletion that removes the active node and ALL its descendants (entire subtree)
  bool deleteActiveNode() {
    if (_activeNode == null || _root == null) return false;
    
    _saveState();

    if (_activeNode!.isRoot) {
      // Reset to initial state when deleting root
      _root = null;
      _activeNode = null;
      _nextNodeId = 1;
      _initializeGraph();
      return true;
    }

    // Smart deletion: Remove the entire subtree (node + all descendants)
    final nodeToDelete = _activeNode!;
    final parent = nodeToDelete.parent!;
    final subtreeSize = nodeToDelete.allDescendants.length + 1; // +1 for the node itself
    
    print('🗑️ Deleting subtree: Node ${nodeToDelete.id} with $subtreeSize total nodes');
    print('📊 Before deletion - Total nodes: ${getAllNodes().length}');
    print('👨‍👩‍👧‍👦 Parent ${parent.id} has ${parent.children.length} children: ${parent.children.map((c) => c.id).join(', ')}');
    
    // Remove only this node from parent's children (this removes entire subtree)
    final updatedParentChildren = parent.children
        .where((child) => child.id != nodeToDelete.id)
        .toList();
    
    print('👨‍👩‍👧‍👦 After filtering - Parent will have ${updatedParentChildren.length} children: ${updatedParentChildren.map((c) => c.id).join(', ')}');
    
    // Create a completely new tree structure to avoid any reference issues
    _root = _rebuildTreeWithoutNode(_root!, nodeToDelete.id);
    
    // Set parent as new active node (rebalance)
    _activeNode = _findNodeById(_root!, parent.id);
    
    print('📊 After deletion - Total nodes: ${getAllNodes().length}');
    print('✅ Subtree deletion complete. Active node: ${_activeNode?.id}');
    
    // Verify tree structure is correct
    _verifyTreeStructure();
    
    notifyListeners();
    return true;
  }

  /// Rebuilds the tree structure without the specified node and its subtree
  Node _rebuildTreeWithoutNode(Node root, String nodeIdToDelete) {
    // If this is the node to delete, return null (this shouldn't happen for non-root nodes)
    if (root.id == nodeIdToDelete) {
      return root; // This case is handled separately for root deletion
    }
    
    // Filter out the node to delete from children and rebuild each child
    final filteredChildren = root.children
        .where((child) => child.id != nodeIdToDelete)
        .map((child) => _rebuildTreeWithoutNode(child, nodeIdToDelete))
        .toList();
    
    // Return a new node with filtered children
    return root.copyWith(children: filteredChildren);
  }

  /// Verifies the tree structure is correct after deletion
  void _verifyTreeStructure() {
    if (_root == null) return;
    
    final allNodes = getAllNodes();
    print('🔍 Tree verification:');
    print('   Root: ${_root!.id}');
    print('   Total nodes: ${allNodes.length}');
    print('   All node IDs: ${allNodes.map((n) => n.id).join(', ')}');
    
    // Check that no orphaned nodes exist
    for (final node in allNodes) {
      if (!node.isRoot && node.parent == null) {
        print('❌ ERROR: Found orphaned node ${node.id} without parent!');
      }
    }
    
    print('✅ Tree structure verification complete');
  }

  /// Delete a specific node by ID (useful for programmatic deletion)
  bool deleteNodeById(String nodeId) {
    if (_root == null) return false;
    
    // If deleting root, reset everything
    if (_root!.id == nodeId) {
      _saveState();
      _root = null;
      _activeNode = null;
      _nextNodeId = 1;
      _initializeGraph();
      return true;
    }
    
    // Find the node to delete
    final nodeToDelete = _findNodeById(_root!, nodeId);
    if (nodeToDelete == null) return false;
    
    // Find its parent
    final parent = nodeToDelete.parent;
    if (parent == null) return false;
    
    _saveState();
    
    // Create a completely new tree structure without the node and its subtree
    _root = _rebuildTreeWithoutNode(_root!, nodeId);
    
    // If we deleted the active node, set parent as active
    if (_activeNode?.id == nodeId) {
      _activeNode = _findNodeById(_root!, parent.id);
    }
    
    notifyListeners();
    return true;
  }

  bool canUndo() => _historyIndex > 0;

  bool canRedo() => _historyIndex < _history.length - 1;

  void undo() {
    if (!canUndo()) return;
    
    _historyIndex--;
    _restoreState(_history[_historyIndex]);
    notifyListeners();
  }

  void redo() {
    if (!canRedo()) return;
    
    _historyIndex++;
    _restoreState(_history[_historyIndex]);
    notifyListeners();
  }

  void _restoreState(GraphState state) {
    _root = state.root;
    _nextNodeId = state.nextNodeId;
    
    if (state.activeNodeId != null && _root != null) {
      _activeNode = _findNodeById(_root!, state.activeNodeId!);
    } else {
      _activeNode = null;
    }
    
    // Rebuild parent references
    if (_root != null) {
      _rebuildParentReferences(_root);
    }
  }

  void resetGraph() {
    _saveState();
    _root = null;
    _activeNode = null;
    _nextNodeId = 1;
    _initializeGraph();
  }

  // Get all nodes in the tree (for debugging/export)
  List<Node> getAllNodes() {
    if (_root == null) return [];
    
    List<Node> allNodes = [];
    _collectAllNodes(_root!, allNodes);
    return allNodes;
  }

  void _collectAllNodes(Node node, List<Node> allNodes) {
    allNodes.add(node);
    for (Node child in node.children) {
      _collectAllNodes(child, allNodes);
    }
  }
}

class GraphState {
  final Node? root;
  final String? activeNodeId;
  final int nextNodeId;

  GraphState({
    required this.root,
    required this.activeNodeId,
    required this.nextNodeId,
  });
}
