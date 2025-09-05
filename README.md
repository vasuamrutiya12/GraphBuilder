<img width="1919" height="926" alt="image" src="https://github.com/user-attachments/assets/ac383b35-d559-4bcc-a8da-b1be38464e76" />
# Graph Builder - Flutter App

A comprehensive Flutter application for creating, navigating, and managing tree-like graphs of nodes. Each node has a unique label and can have multiple children, with full support for all edge cases and advanced features.

## Features

### Core Functionality
- **Initial State**: App starts with a single root node labeled "1"
- **Node Management**: Add, select, and delete nodes with full hierarchy support
- **Visual Hierarchy**: Clear tree visualization with connecting lines
- **Active Node Highlighting**: Visual distinction for the currently selected node

### Advanced Features
- **Zoom & Pan**: Interactive navigation for large trees with pinch-to-zoom and drag gestures
- **Smooth Animations**: Beautiful transitions for node creation, deletion, and selection
- **Undo/Redo**: Complete history navigation with up to 50 actions
- **Depth Limiting**: Maximum depth of 100 levels with graceful handling
- **Graph Information**: Real-time display of node count, depth, and active node

### Edge Cases Handled
- **Maximum Depth**: Prevents adding children at depth 100 with user feedback
- **Root Deletion**: Gracefully resets the entire graph when root is deleted
- **Recursive Deletion**: Safely removes all descendants when deleting a parent node
- **Unique Labels**: Global incrementing node IDs that never reset
- **Empty Graph**: Handles complete graph deletion with proper reset
- **Touch Targets**: Optimized node sizes for reliable interaction

## Technical Implementation

### Architecture
- **State Management**: Provider pattern for reactive state updates
- **Graph Visualization**: GraphView package with Sugiyama algorithm
- **Animations**: Multiple animation controllers for smooth user experience
- **Responsive Design**: Material 3 design with light/dark theme support

### Key Components

#### Node Model (`lib/models/node.dart`)
- Comprehensive node structure with parent-child relationships
- Helper methods for tree traversal and analysis
- Immutable design with copyWith functionality

#### Graph Provider (`lib/providers/graph_provider.dart`)
- Centralized state management for the entire graph
- History tracking for undo/redo functionality
- Depth validation and constraint enforcement
- Tree manipulation methods with proper parent reference management

#### Graph Node Widget (`lib/widgets/graph_node.dart`)
- Animated node visualization with multiple animation layers
- Ripple effects for tap feedback
- Pulse animation for active state indication
- Gradient styling and shadow effects

#### Tree Visualizer (`lib/widgets/tree_visualizer.dart`)
- Interactive graph rendering with zoom/pan controls
- Real-time graph statistics overlay
- Responsive layout with gradient background
- Auto-hiding zoom controls for clean interface

#### Main App (`lib/main.dart`)
- Complete UI with floating action buttons
- Confirmation dialogs for destructive actions
- Status bar with active node information
- Snackbar notifications for user feedback

## User Interface

### Main Screen
- **App Bar**: Title with undo/redo/reset controls
- **Status Bar**: Shows active node and next ID information
- **Graph View**: Interactive tree visualization with zoom/pan
- **Floating Action Buttons**: Add child and delete node actions
- **Info Overlay**: Real-time graph statistics

### Interactions
- **Tap Node**: Select and activate a node
- **Add Button**: Create child node under active node
- **Delete Button**: Remove active node and all descendants
- **Zoom Controls**: Manual zoom in/out/reset (appear on interaction)
- **Undo/Redo**: Navigate through action history

## Getting Started

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Chrome browser (for web development)

### Installation
1. Clone the repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run -d chrome
   ```

### Dependencies
- `provider: ^6.1.2` - State management
- `graphview: ^1.2.0` - Graph visualization
- `cupertino_icons: ^1.0.8` - iOS-style icons

## Usage Examples

### Basic Operations
1. **Start**: App opens with root node "1" active
2. **Add Child**: Tap the + button to add node "2" under "1"
3. **Select Node**: Tap node "2" to make it active
4. **Add More**: Tap + again to add node "3" under "2"
5. **Delete**: Tap the delete button to remove active node and children

### Advanced Features
- **Zoom**: Pinch to zoom or use zoom controls
- **Pan**: Drag to move around large graphs
- **Undo**: Use undo button to reverse last action
- **Reset**: Use reset button to start fresh

## Performance Considerations

- **Large Trees**: Optimized for thousands of nodes
- **Memory Management**: Proper disposal of animation controllers
- **Efficient Rendering**: Only rebuilds necessary components
- **History Limiting**: Caps undo history at 50 actions

## Future Enhancements

Potential improvements for future versions:
- **Export/Import**: Save and load graphs in JSON format
- **Collapsible Branches**: Hide/show node subtrees
- **Custom Styling**: User-configurable node colors and sizes
- **Search Functionality**: Find nodes by label
- **Multiple Graphs**: Support for multiple graph instances

## License

This project is open source and available under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

---

**Graph Builder** - Build, explore, and manage tree structures with ease! 🌳
