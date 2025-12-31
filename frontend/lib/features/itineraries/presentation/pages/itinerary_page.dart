import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/itinerary_bloc.dart';
import '../../bloc/itinerary_event.dart';
import '../../bloc/itinerary_state.dart';
import '../../../../core/utils/extensions.dart';

class ItineraryPage extends StatelessWidget {
  final String tripId;
  final DateTime date;

  const ItineraryPage({
    super.key,
    required this.tripId,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ItineraryBloc(
        // Would be injected via DI
        context.read(),
      )..add(LoadItineraryEvent(tripId, date)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Itinerary - ${date.toFormattedString()}'),
        ),
        body: BlocBuilder<ItineraryBloc, ItineraryState>(
          builder: (context, state) {
            if (state is ItineraryLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ItineraryError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ItineraryBloc>().add(LoadItineraryEvent(tripId, date));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is ItineraryLoaded || state is ItineraryReordering) {
              final items = state is ItineraryLoaded
                  ? state.items
                  : (state as ItineraryReordering).items;

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No items yet'),
                      const SizedBox(height: 8),
                      const Text('Add your first activity'),
                    ],
                  ),
                );
              }

              return ReorderableListView(
                padding: const EdgeInsets.all(16),
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  final item = items.removeAt(oldIndex);
                  items.insert(newIndex, item);
                  
                  final itemIds = items.map((i) => i.id).toList();
                  context.read<ItineraryBloc>().add(
                        ReorderItemsEvent(
                          state is ItineraryLoaded
                              ? state.itinerary.id
                              : '',
                          itemIds,
                        ),
                      );
                },
                children: items.map((item) {
                  return Card(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: item.startTime != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.startTime!.toTimeString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          : const Icon(Icons.schedule),
                      title: Text(item.title),
                      subtitle: item.description != null && item.description!.isNotEmpty
                          ? Text(item.description!)
                          : null,
                      trailing: const Icon(Icons.drag_handle),
                    ),
                  );
                }).toList(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Add item dialog (simplified)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add item feature coming soon')),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

