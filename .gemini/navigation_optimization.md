# Navigation Optimization: SourceDetailScreen to VideoListScreen

## Problem
The original implementation used `Navigator.push()` to navigate from `SourceDetailScreen` to `VideoListScreen`, which created several issues:

1. **Created a new navigation stack** - Pushed a new screen on top instead of switching tabs
2. **Passed empty/dummy data** - The VideoListScreen received empty arrays (`onlineVideos: []`)
3. **No state synchronization** - Changes weren't reflected in the main app state
4. **Poor UX** - Users had to navigate back instead of switching tabs naturally

## Solution
Implemented a **callback-based tab switching** mechanism that:

1. **Pops with result** - Returns the desired tab index (2 for Online/VideoListScreen)
2. **Maintains state** - Uses the existing `onlineVideos` list from MainScreen
3. **Better UX** - Seamlessly switches to the Online tab
4. **Cleaner architecture** - Follows Flutter's navigation best practices

## Changes Made

### 1. SourceDetailScreen (`source_detail_screen.dart`)
- **Changed**: `Navigator.push()` → `Navigator.pop(2)`
- **Removed**: Unused import for `VideoListScreen`
- **Result**: Now returns tab index 2 when "Go to Online page" button is clicked

```dart
IconButton(
  icon: const Icon(Icons.cloud_download),
  tooltip: 'Go to Online page',
  onPressed: () {
    Navigator.of(context).pop(2); // Returns tab index
  },
),
```

### 2. SourceListScreen (`source_list_screen.dart`)
- **Added**: `onTabRequested` callback parameter
- **Activated**: Tab switching logic when receiving result from SourceDetailScreen
- **Passed**: Callback to child widgets (NewMovies, CategoriMovies)

```dart
class SourceListScreen extends StatefulWidget {
  final Function(int)? onTabRequested;
  const SourceListScreen({super.key, this.onTabRequested});
  // ...
}
```

### 3. MainScreen (`main_screen.dart`)
- **Added**: `onTabRequested` callback to SourceListScreen
- **Updates**: `_selectedIndex` state when tab switch is requested

```dart
SourceListScreen(
  onTabRequested: (index) {
    setState(() {
      _selectedIndex = index;
    });
  },
),
```

### 4. Widget Updates
Updated both `NewMovies` and `CategoriMovies` widgets:
- **Added**: `onTabRequested` callback parameter
- **Passed**: Callback through to `_MovieListItem` components
- **Activated**: Tab switching logic when navigation returns

## Benefits

✅ **Optimized Navigation**: No unnecessary screen pushes
✅ **State Preservation**: Uses existing data from MainScreen
✅ **Better UX**: Smooth tab switching instead of back navigation
✅ **Cleaner Code**: Removed dummy data and unused imports
✅ **Consistent Architecture**: Follows Flutter navigation patterns

## How It Works

1. User clicks "Go to Online page" in SourceDetailScreen
2. SourceDetailScreen pops with result value `2`
3. SourceListScreen receives the result
4. Calls `onTabRequested(2)` callback
5. MainScreen updates `_selectedIndex` to `2`
6. UI switches to the Online (VideoListScreen) tab
7. VideoListScreen displays with the actual `onlineVideos` data

## Testing
The changes maintain backward compatibility and don't break existing functionality. The app should now:
- Switch to the Online tab when clicking the cloud download icon in SourceDetailScreen
- Preserve all video data in the Online tab
- Allow users to continue their workflow seamlessly
