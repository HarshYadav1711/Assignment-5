import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/trip_list_bloc.dart';
import '../../bloc/trip_list_event.dart';
import '../../bloc/trip_list_state.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_event.dart';
import '../../../../data/models/trip.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/extensions.dart';
import '../widgets/create_trip_dialog.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  @override
  void initState() {
    super.initState();
    // Load trips when page opens
    context.read<TripListBloc>().add(const LoadTripListEvent());
  }

  void _handleLogout() {
    context.read<AuthBloc>().add(const LogoutEvent());
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.flight;
      case 'planned':
        return Icons.calendar_today;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.edit;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'planned':
        return AppColors.info;
      case 'completed':
        return AppColors.textSecondary;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TripListBloc>().add(const RefreshTripListEvent());
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: BlocConsumer<TripListBloc, TripListState>(
        listener: (context, state) {
          if (state is TripListError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TripListLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TripListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  if (state.retryable)
                    ElevatedButton(
                      onPressed: () {
                        context.read<TripListBloc>().add(const LoadTripListEvent());
                      },
                      child: const Text('Retry'),
                    ),
                ],
              ),
            );
          }

          if (state is TripListLoaded) {
            final trips = state.trips;

            if (trips.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No trips yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first trip to get started',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<TripListBloc>().add(const RefreshTripListEvent());
                // Wait a bit for the refresh to complete
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(trip.status).withOpacity(0.1),
                        child: Icon(
                          _getStatusIcon(trip.status),
                          color: _getStatusColor(trip.status),
                        ),
                      ),
                      title: Text(trip.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (trip.description != null && trip.description!.isNotEmpty)
                            Text(
                              trip.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          if (trip.startDate != null)
                            Text(
                              '${trip.startDate!.toFormattedString()}${trip.endDate != null ? ' - ${trip.endDate!.toFormattedString()}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      trailing: Chip(
                        label: Text(
                          trip.status,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: _getStatusColor(trip.status).withOpacity(0.1),
                      ),
                      onTap: () {
                        // Navigate to trip details (to be implemented)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Trip: ${trip.title}')),
                        );
                      },
                    ),
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateTripDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
      ),
    );
  }
}
