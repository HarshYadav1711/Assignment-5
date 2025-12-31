import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/trip_list_bloc.dart';
import '../../bloc/trip_list_event.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/theme/colors.dart';

class CreateTripDialog extends StatefulWidget {
  const CreateTripDialog({super.key});

  @override
  State<CreateTripDialog> createState() => _CreateTripDialogState();
}

class _CreateTripDialogState extends State<CreateTripDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'planned';
  String _visibility = 'private';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, clear it
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final tripData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty 
            ? '' 
            : _descriptionController.text.trim(),
        'status': _status,
        'visibility': _visibility,
      };
      
      // Only add dates if they are selected
      if (_startDate != null) {
        tripData['start_date'] = _startDate!.toIso8601String().split('T')[0];
      }
      if (_endDate != null) {
        tripData['end_date'] = _endDate!.toIso8601String().split('T')[0];
      }

      context.read<TripListBloc>().add(CreateTripEvent(tripData));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Trip'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Trip Title *',
                  hintText: 'e.g., Summer Vacation 2024',
                ),
                validator: Validators.tripTitle,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Tell us about your trip...',
                ),
                maxLines: 3,
                validator: (value) => Validators.maxLength(value, 1000, fieldName: 'Description'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                              : 'Select date',
                          style: TextStyle(
                            color: _startDate != null
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                              : 'Select date',
                          style: TextStyle(
                            color: _endDate != null
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                ),
                items: const [
                  DropdownMenuItem(value: 'planned', child: Text('Planned')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _status = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: const InputDecoration(
                  labelText: 'Visibility',
                ),
                items: const [
                  DropdownMenuItem(value: 'private', child: Text('Private')),
                  DropdownMenuItem(value: 'public', child: Text('Public')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _visibility = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }
}

