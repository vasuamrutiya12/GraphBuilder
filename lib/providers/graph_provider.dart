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

  Node _addChildToNode(Node parent, Node newChild) {
    final updatedChildren = List<Node>.from(parent.children)..add(newChild);
    return parent.copyWith(children: updatedChildren);
  }

  Node _updateNodeInTree(Node root, Node updatedNode) {
    if (root.id == updatedNode.id) {
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
      final success = deleteActiveNode();
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

  bool deleteActiveNode() {
    if (_activeNode == null || _root == null) return false;
    
    _saveState();

    if (_activeNode!.isRoot) {
      // Reset to initial state
      _root = null;
      _activeNode = null;
      _nextNodeId = 1;
      _initializeGraph();
      return true;
    }

    // Find parent and remove this node from its children
    final parent = _activeNode!.parent!;
    final updatedParentChildren = parent.children
        .where((child) => child.id != _activeNode!.id)
        .toList();
    
    final updatedParent = parent.copyWith(children: updatedParentChildren);
    
    // Update the tree
    _root = _updateNodeInTree(_root!, updatedParent);
    
    // Set parent as new active node
    _activeNode = _findNodeById(_root!, updatedParent.id);
    
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
