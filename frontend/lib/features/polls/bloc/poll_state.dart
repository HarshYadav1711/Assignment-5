import 'package:equatable/equatable.dart';
import '../../../data/models/poll.dart';

/// Poll states
abstract class PollState extends Equatable {
  const PollState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PollInitial extends PollState {
  const PollInitial();
}

/// Loading state
class PollLoading extends PollState {
  const PollLoading();
}

/// Loaded state
class PollsLoaded extends PollState {
  final List<PollModel> polls;

  const PollsLoaded(this.polls);

  @override
  List<Object?> get props => [polls];
}

/// Vote success
class VoteSuccess extends PollState {
  final PollModel poll;

  const VoteSuccess(this.poll);

  @override
  List<Object?> get props => [poll];
}

/// Error state
class PollError extends PollState {
  final String message;

  const PollError(this.message);

  @override
  List<Object?> get props => [message];
}

