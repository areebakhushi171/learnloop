import 'package:flutter/material.dart';
import '../data/models/reminder_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/course_repository.dart';

class RemindersViewModel extends ChangeNotifier {
  final CourseRepository _courseRepository;
  final AuthRepository _authRepository;

  final bool _isLoading = false;
  String? _errorMessage;

  RemindersViewModel(this._courseRepository, this._authRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Stream<List<ReminderModel>> get remindersStream {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return Stream.value([]);
    return _courseRepository.streamReminders(userId);
  }

  Future<void> addReminder(String title, TimeOfDay timeOfDay) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    final hour = timeOfDay.hour.toString().padLeft(2, '0');
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute';

    final reminder = ReminderModel(
      id: '',
      title: title.isEmpty ? 'Study Reminder' : title,
      time: timeStr,
      days: [1, 2, 3, 4, 5, 6, 7],
      isEnabled: true,
    );

    try {
      await _courseRepository.saveReminder(userId, reminder);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleReminder(ReminderModel reminder) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    final updated = ReminderModel(
      id: reminder.id,
      title: reminder.title,
      time: reminder.time,
      days: reminder.days,
      isEnabled: !reminder.isEnabled,
    );

    try {
      await _courseRepository.saveReminder(userId, updated);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    final userId = _authRepository.currentUser?.uid;
    if (userId == null) return;

    try {
      await _courseRepository.deleteReminder(userId, reminderId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
