import 'package:equatable/equatable.dart';

/// Poll events
abstract class PollEvent extends Equatable {
  const PollEvent();

  @override
  List<Object?> get props => [];
}

/// Load polls
class LoadPollsEvent extends PollEvent {
  final String tripId;

  const LoadPollsEvent(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

/// Vote on poll
class VoteEvent extends PollEvent {
  final String pollId;
  final String optionId;

  const VoteEvent(this.pollId, this.optionId);

  @override
  List<Object?> get props => [pollId, optionId];
}

/// Create poll
class CreatePollEvent extends PollEvent {
  final Map<String, dynamic> pollData;

  const CreatePollEvent(this.pollData);

  @override
  List<Object?> get props => [pollData];
}

