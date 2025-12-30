"""
Unit tests for TripListBloc.

Tests critical trip loading scenarios: load, refresh, optimistic updates, and errors.
"""
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:features/trips/bloc/trip_list_bloc.dart';
import 'package:data/repositories/trip_repository.dart';
import 'package:data/models/trip.dart';

class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockTripRepository mockRepository;
  late TripListBloc tripListBloc;
  
  final trip1 = Trip(
    id: 'trip-1',
    title: 'Trip 1',
    description: 'Description 1',
    status: 'planned',
  );
  
  final trip2 = Trip(
    id: 'trip-2',
    title: 'Trip 2',
    description: 'Description 2',
    status: 'active',
  );
  
  final trips = [trip1, trip2];
  
  setUp(() {
    mockRepository = MockTripRepository();
    tripListBloc = TripListBloc(mockRepository);
  });
  
  tearDown(() {
    tripListBloc.close();
  });
  
  group('TripListBloc', () {
    test('initial state is TripListInitial', () {
      expect(tripListBloc.state, equals(TripListInitial()));
    });
    
    group('LoadTripListEvent', () {
      blocTest<TripListBloc, TripListState>(
        'emits [Loading, Loaded] when trips load successfully',
        build: () {
          when(mockRepository.getTrips())
              .thenAnswer((_) async => trips);
          return tripListBloc;
        },
        act: (bloc) => bloc.add(LoadTripListEvent()),
        expect: () => [
          TripListLoading(),
          TripListLoaded(trips),
        ],
        verify: (_) {
          verify(mockRepository.getTrips()).called(1);
        },
      );
      
      blocTest<TripListBloc, TripListState>(
        'emits [Loading, Error] when load fails',
        build: () {
          when(mockRepository.getTrips())
              .thenThrow(Exception('Network error'));
          return tripListBloc;
        },
        act: (bloc) => bloc.add(LoadTripListEvent()),
        expect: () => [
          TripListLoading(),
          TripListError('Network error'),
        ],
      );
      
      blocTest<TripListBloc, TripListState>(
        'does not emit Loading if already loaded',
        build: () {
          when(mockRepository.getTrips())
              .thenAnswer((_) async => trips);
          return tripListBloc;
        },
        seed: () => TripListLoaded([trip1]),
        act: (bloc) => bloc.add(LoadTripListEvent()),
        expect: () => [
          TripListLoaded(trips),
        ],
      );
    });
    
    group('RefreshTripListEvent', () {
      blocTest<TripListBloc, TripListState>(
        'emits [Loaded] with refreshed trips',
        build: () {
          when(mockRepository.getTrips(refresh: true))
              .thenAnswer((_) async => trips);
          return tripListBloc;
        },
        seed: () => TripListLoaded([trip1]),
        act: (bloc) => bloc.add(RefreshTripListEvent()),
        expect: () => [
          TripListLoaded(trips),
        ],
        verify: (_) {
          verify(mockRepository.getTrips(refresh: true)).called(1);
        },
      );
    });
    
    group('DeleteTripEvent', () {
      blocTest<TripListBloc, TripListState>(
        'optimistically removes trip from list',
        build: () {
          when(mockRepository.deleteTrip('trip-1'))
              .thenAnswer((_) async => {});
          return tripListBloc;
        },
        seed: () => TripListLoaded(trips),
        act: (bloc) => bloc.add(DeleteTripEvent('trip-1')),
        expect: () => [
          TripListLoaded([trip2]),  // Optimistic update
        ],
        verify: (_) {
          verify(mockRepository.deleteTrip('trip-1')).called(1);
        },
      );
      
      blocTest<TripListBloc, TripListState>(
        'reverts optimistic update on delete failure',
        build: () {
          when(mockRepository.deleteTrip('trip-1'))
              .thenThrow(Exception('Delete failed'));
          when(mockRepository.getTrips())
              .thenAnswer((_) async => trips);
          return tripListBloc;
        },
        seed: () => TripListLoaded(trips),
        act: (bloc) => bloc.add(DeleteTripEvent('trip-1')),
        expect: () => [
          TripListLoaded([trip2]),  // Optimistic update
          TripListError('Delete failed'),
          TripListLoading(),  // Reload triggered
          TripListLoaded(trips),  // Reverted to original
        ],
      );
    });
    
    group('CreateTripEvent', () {
      final newTrip = Trip(
        id: 'trip-3',
        title: 'New Trip',
        status: 'draft',
      );
      
      blocTest<TripListBloc, TripListState>(
        'optimistically adds trip to list',
        build: () {
          when(mockRepository.createTrip(
            title: 'New Trip',
            description: null,
            startDate: null,
            endDate: null,
          )).thenAnswer((_) async => newTrip);
          return tripListBloc;
        },
        seed: () => TripListLoaded(trips),
        act: (bloc) => bloc.add(CreateTripEvent(
          title: 'New Trip',
        )),
        expect: () => [
          TripListLoaded([newTrip, ...trips]),  // Optimistic update
          TripListLoaded([newTrip, ...trips]),  // Confirmed update
        ],
      );
    });
  });
}

