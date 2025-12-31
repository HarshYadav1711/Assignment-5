import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/poll_bloc.dart';
import '../../bloc/poll_event.dart';
import '../../bloc/poll_state.dart';
import '../../../../data/models/poll.dart';
import '../../../../core/theme/colors.dart';

class PollsPage extends StatelessWidget {
  final String tripId;

  const PollsPage({
    super.key,
    required this.tripId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PollBloc(
        // Would be injected via DI
        context.read(),
      )..add(LoadPollsEvent(tripId)),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Polls'),
        ),
        body: BlocBuilder<PollBloc, PollState>(
          builder: (context, state) {
            if (state is PollLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is PollError) {
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
                        context.read<PollBloc>().add(LoadPollsEvent(tripId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is PollsLoaded) {
              final polls = state.polls;

              if (polls.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.poll, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('No polls yet'),
                      const SizedBox(height: 8),
                      const Text('Create a poll to get group input'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: polls.length,
                itemBuilder: (context, index) {
                  final poll = polls[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            poll.question,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (poll.description != null && poll.description!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                poll.description!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          const SizedBox(height: 16),
                          ...poll.options.map((option) {
                            final isVoted = poll.userVoteId == option.id;
                            final totalVotes = poll.options.fold<int>(
                              0,
                              (sum, opt) => sum + opt.voteCount,
                            );
                            final percentage = totalVotes > 0
                                ? (option.voteCount / totalVotes * 100).round()
                                : 0;

                            return InkWell(
                              onTap: isVoted
                                  ? null
                                  : () {
                                      context.read<PollBloc>().add(
                                            VoteEvent(poll.id, option.id),
                                          );
                                    },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isVoted ? AppColors.primary : AppColors.border,
                                    width: isVoted ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isVoted
                                      ? AppColors.primary.withOpacity(0.1)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(option.text),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                            value: totalVotes > 0
                                                ? option.voteCount / totalVotes
                                                : 0,
                                            backgroundColor: AppColors.border,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$percentage% (${option.voteCount} votes)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isVoted)
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Create poll feature coming soon')),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('New Poll'),
        ),
      ),
    );
  }
}

