# UI Components Reference

## Reusable Components

### 1. Skeleton Loaders

**Purpose:** Show content structure while loading

**Components:**
- `SkeletonLoader`: Base skeleton with shimmer
- `TripCardSkeleton`: Trip card skeleton
- `MessageListSkeleton`: Chat message skeleton

**Usage:**
```dart
if (state is Loading) {
  return ListView.builder(
    itemCount: 3,
    itemBuilder: (_, __) => TripCardSkeleton(),
  );
}
```

---

### 2. Animation Widgets

**Components:**
- `FadeInWidget`: Fade in animation
- `SlideInListItem`: Slide in for list items
- `ScaleTapWidget`: Scale animation on tap
- `SmoothStateTransition`: Smooth state changes

**Usage:**
```dart
FadeInWidget(
  child: TripCard(trip: trip),
)
```

---

### 3. State Widgets

**Components:**
- `LoadingIndicator`: Standard loading spinner
- `EmptyStateWidget`: Empty state with icon and message
- `ErrorStateWidget`: Error state with retry
- `PendingIndicator`: Sync pending indicator

**Usage:**
```dart
if (state is Error) {
  return ErrorStateWidget(
    message: state.message,
    onRetry: () => bloc.add(RetryEvent()),
  );
}
```

---

### 4. Cards

**Components:**
- `AppCard`: Standard card with optional tap

**Usage:**
```dart
AppCard(
  onTap: () => navigateToDetail(),
  child: Column(...),
)
```

---

## Component Patterns

### BLoC Consumer Pattern

```dart
BlocConsumer<TripListBloc, TripListState>(
  listener: (context, state) {
    // Handle side effects
    if (state is TripListError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  builder: (context, state) {
    // Build UI
    if (state is TripListLoading) {
      return LoadingIndicator();
    } else if (state is TripListLoaded) {
      return TripList(trips: state.trips);
    }
    return SizedBox.shrink();
  },
)
```

### Optimistic Update Pattern

```dart
// In BLoC
Future<void> _onDelete(DeleteEvent event) async {
  // 1. Optimistic update
  if (state is Loaded) {
    emit(Loaded(updatedItems));
  }
  
  // 2. Sync
  try {
    await repository.delete(event.id);
  } catch (e) {
    // 3. Revert on error
    add(LoadEvent());
  }
}
```

---

## Accessibility Checklist

- [x] Semantic labels on all interactive elements
- [x] Text scales with system settings
- [x] Color contrast meets WCAG AA (4.5:1)
- [x] Touch targets minimum 48x48dp
- [x] Reduced motion support
- [x] Screen reader announcements
- [x] Focus indicators visible
- [x] Keyboard navigation support

---

## Summary

All UI components follow these principles:
- ✅ **Clean**: Minimal, uncluttered design
- ✅ **Professional**: Healthcare-grade reliability feel
- ✅ **Accessible**: WCAG compliant
- ✅ **Performant**: Optimized animations
- ✅ **Consistent**: Reusable patterns

The design system provides a solid foundation for a professional, accessible Flutter application.

