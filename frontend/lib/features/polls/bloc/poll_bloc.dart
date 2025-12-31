import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/poll_repository.dart';
import '../../../data/models/poll.dart';
import 'poll_event.dart';
import 'poll_state.dart';

/// Poll BLoC
class PollBloc extends Bloc<PollEvent, PollState> {
  final PollRepository _repository;

  PollBloc(this._repository) : super(PollInitial()) {
    on<LoadPollsEvent>(_onLoadPolls);
    on<VoteEvent>(_onVote);
    on<CreatePollEvent>(_onCreatePoll);
  }

  Future<void> _onLoadPolls(
    LoadPollsEvent event,
    Emitter<PollState> emit,
  ) async {
    emit(PollLoading());
    try {
      final polls = await _repository.getPolls(event.tripId);
      emit(PollsLoaded(polls));
    } catch (e) {
      emit(PollError(e.toString()));
    }
  }

  Future<void> _onVote(
    VoteEvent event,
    Emitter<PollState> emit,
  ) async {
    // Optimistic update
    if (state is PollsLoaded) {
      final polls = (state as PollsLoaded).polls;
      final pollIndex = polls.indexWhere((p) => p.id == event.pollId);
      if (pollIndex != -1) {
        final poll = polls[pollIndex];
        final updatedOptions = poll.options.map((opt) {
          if (opt.id == event.optionId) {
            return opt.copyWith(voteCount: opt.voteCount + 1);
          }
          return opt;
        }).toList();
        final updatedPoll = PollModel(
          id: poll.id,
          tripId: poll.tripId,
          question: poll.question,
          description: poll.description,
          createdById: poll.createdById,
          isActive: poll.isActive,
          closesAt: poll.closesAt,
          createdAt: poll.createdAt,
          options: updatedOptions,
          userVoteId: event.optionId,
        );
        final updatedPolls = List<PollModel>.from(polls);
        updatedPolls[pollIndex] = updatedPoll;
        emit(PollsLoaded(updatedPolls));
      }
    }

    try {
      final updatedPoll = await _repository.vote(event.pollId, event.optionId);
      emit(VoteSuccess(updatedPoll));
      // Reload polls to get latest state
      if (state is PollsLoaded) {
        final polls = (state as PollsLoaded).polls;
        final pollIndex = polls.indexWhere((p) => p.id == event.pollId);
        if (pollIndex != -1) {
          final updatedPolls = List<PollModel>.from(polls);
          updatedPolls[pollIndex] = updatedPoll;
          emit(PollsLoaded(updatedPolls));
        }
      }
    } catch (e) {
      emit(PollError('Failed to vote: ${e.toString()}'));
      // Revert optimistic update
      if (state is PollsLoaded) {
        add(LoadPollsEvent((state as PollsLoaded).polls.first.tripId));
      }
    }
  }

  Future<void> _onCreatePoll(
    CreatePollEvent event,
    Emitter<PollState> emit,
  ) async {
    try {
      final poll = await _repository.createPoll(event.pollData);
      if (state is PollsLoaded) {
        final polls = (state as PollsLoaded).polls;
        emit(PollsLoaded([poll, ...polls]));
      } else {
        add(LoadPollsEvent(poll.tripId));
      }
    } catch (e) {
      emit(PollError('Failed to create poll: ${e.toString()}'));
    }
  }
}

