"""
Unit tests for SyncManager.

Tests offline-to-online sync scenarios: pending changes, conflicts, and error handling.
"""
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:core/storage/sync_manager.dart';
import 'package:core/storage/sync_queue.dart';
import 'package:data/repositories/trip_repository.dart';
import 'package:data/models/trip.dart';

class MockSyncQueue extends Mock implements SyncQueue {}
class MockTripRepository extends Mock implements TripRepository {}

void main() {
  late MockSyncQueue mockSyncQueue;
  late MockTripRepository mockTripRepository;
  late SyncManager syncManager;
  
  final testTrip = Trip(
    id: 'trip-1',
    title: 'Test Trip',
    status: 'planned',
  );
  
  final pendingChange = SyncQueueEntry(
    id: 'sync-1',
    entityType: 'trip',
    entityId: 'trip-1',
    action: 'update',
    data: {'title': 'Updated Trip'},
    clientTimestamp: DateTime.now(),
    status: SyncStatus.pending,
  );
  
  setUp(() {
    mockSyncQueue = MockSyncQueue();
    mockTripRepository = MockTripRepository();
    syncManager = SyncManager(
      syncQueue: mockSyncQueue,
      tripRepository: mockTripRepository,
    );
  });
  
  group('SyncManager', () {
    group('syncPendingChanges', () {
      test('syncs all pending changes successfully', () async {
        // Arrange
        when(mockSyncQueue.getPendingEntries())
            .thenAnswer((_) async => [pendingChange]);
        when(mockTripRepository.updateTrip('trip-1', any))
            .thenAnswer((_) async => testTrip);
        when(mockSyncQueue.markAsSynced('sync-1'))
            .thenAnswer((_) async => {});
        
        // Act
        await syncManager.syncPendingChanges();
        
        // Assert
        verify(mockSyncQueue.getPendingEntries()).called(1);
        verify(mockTripRepository.updateTrip('trip-1', any)).called(1);
        verify(mockSyncQueue.markAsSynced('sync-1')).called(1);
      });
      
      test('handles sync failure and marks for retry', () async {
        // Arrange
        when(mockSyncQueue.getPendingEntries())
            .thenAnswer((_) async => [pendingChange]);
        when(mockTripRepository.updateTrip('trip-1', any))
            .thenThrow(Exception('Network error'));
        when(mockSyncQueue.incrementRetryCount('sync-1'))
            .thenAnswer((_) async => {});
        
        // Act
        await syncManager.syncPendingChanges();
        
        // Assert
        verify(mockSyncQueue.incrementRetryCount('sync-1')).called(1);
        verifyNever(mockSyncQueue.markAsSynced('sync-1'));
      });
      
      test('marks entry as failed after max retries', () async {
        // Arrange
        final maxRetriesEntry = pendingChange.copyWith(retryCount: 5);
        when(mockSyncQueue.getPendingEntries())
            .thenAnswer((_) async => [maxRetriesEntry]);
        when(mockTripRepository.updateTrip('trip-1', any))
            .thenThrow(Exception('Network error'));
        when(mockSyncQueue.markAsFailed('sync-1'))
            .thenAnswer((_) async => {});
        
        // Act
        await syncManager.syncPendingChanges();
        
        // Assert
        verify(mockSyncQueue.markAsFailed('sync-1')).called(1);
      });
    });
    
    group('handleConflict', () {
      test('resolves conflict with last-write-wins strategy', () async {
        // Arrange
        final serverTrip = testTrip.copyWith(
          title: 'Server Title',
          updatedAt: DateTime.now().add(Duration(hours: 1)),
        );
        final clientTrip = testTrip.copyWith(
          title: 'Client Title',
          updatedAt: DateTime.now(),
        );
        
        when(mockTripRepository.getTrip('trip-1'))
            .thenAnswer((_) async => serverTrip);
        when(mockSyncQueue.resolveConflict('sync-1', serverTrip))
            .thenAnswer((_) async => {});
        
        // Act
        await syncManager.handleConflict('sync-1', clientTrip);
        
        // Assert
        verify(mockSyncQueue.resolveConflict('sync-1', serverTrip)).called(1);
      });
    });
  });
}

