import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coka/models/reminder.dart';
import 'package:coka/api/repositories/reminder_repository.dart';
import 'package:coka/api/providers.dart';

// Repository provider
final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReminderRepository(apiClient);
});

// Reminder list notifier
class ReminderListNotifier extends StateNotifier<AsyncValue<List<Reminder>>> {
  ReminderListNotifier(this._repository) : super(const AsyncValue.loading());

  final ReminderRepository _repository;

  Future<void> loadReminders({
    required String organizationId,
    String? workspaceId,
    String? contactId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final reminders = await _repository.getScheduleList(
        organizationId: organizationId,
        workspaceId: workspaceId,
        contactId: contactId,
      );
      
      // Sắp xếp reminder: chưa hoàn thành lên trước, theo thời gian
      reminders.sort((a, b) {
        if (a.isDone != b.isDone) {
          return a.isDone ? 1 : -1; // Chưa hoàn thành lên trước
        }
        
        try {
          final timeA = DateTime.parse(a.startTime);
          final timeB = DateTime.parse(b.startTime);
          return timeA.compareTo(timeB);
        } catch (e) {
          return 0;
        }
      });
      
      state = AsyncValue.data(reminders);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> createReminder(Map<String, dynamic> data) async {
    try {
      await _repository.createSchedule(data);
      // Reload after create
      final currentData = state.value;
      if (currentData != null) {
        String? contactId;
        // Extract contactId from Contact array
        if (data['Contact'] is List && (data['Contact'] as List).isNotEmpty) {
          final contact = (data['Contact'] as List).first;
          contactId = contact['id'];
        }
        
        await loadReminders(
          organizationId: data['OrganizationId'],
          workspaceId: data['WorkspaceId'],
          contactId: contactId,
        );
      }
    } catch (e) {
      throw Exception('Error creating reminder: $e');
    }
  }

  Future<void> updateReminder(Map<String, dynamic> data) async {
    try {
      await _repository.updateSchedule(data);
      // Reload after update
      String? contactId;
      // Extract contactId from Contact array
      if (data['Contact'] is List && (data['Contact'] as List).isNotEmpty) {
        final contact = (data['Contact'] as List).first;
        contactId = contact['id'];
      }
      
      await loadReminders(
        organizationId: data['OrganizationId'],
        workspaceId: data['WorkspaceId'],
        contactId: contactId,
      );
    } catch (e) {
      throw Exception('Error updating reminder: $e');
    }
  }

  Future<void> toggleReminderDone(String id, bool isDone) async {
    try {
      await _repository.markScheduleAsDone(id: id, isDone: isDone);
      
      // Update local state immediately
      state = state.whenData((reminders) {
        final updatedReminders = reminders.map((reminder) {
          if (reminder.id == id) {
            return reminder.copyWith(isDone: isDone);
          }
          return reminder;
        }).toList();
        
        // Re-sort after update
        updatedReminders.sort((a, b) {
          if (a.isDone != b.isDone) {
            return a.isDone ? 1 : -1;
          }
          
          try {
            final timeA = DateTime.parse(a.startTime);
            final timeB = DateTime.parse(b.startTime);
            return timeA.compareTo(timeB);
          } catch (e) {
            return 0;
          }
        });
        
        return updatedReminders;
      });
    } catch (e) {
      throw Exception('Error toggling reminder status: $e');
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _repository.deleteSchedule(id);
      
      // Remove from local state
      state = state.whenData((reminders) {
        return reminders.where((reminder) => reminder.id != id).toList();
      });
    } catch (e) {
      throw Exception('Error deleting reminder: $e');
    }
  }

  // Refresh reminders
  Future<void> refresh({
    required String organizationId,
    String? workspaceId,
    String? contactId,
  }) async {
    await loadReminders(
      organizationId: organizationId,
      workspaceId: workspaceId,
      contactId: contactId,
    );
  }
}

// Provider for reminder list
final reminderListProvider = StateNotifierProvider<ReminderListNotifier, AsyncValue<List<Reminder>>>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  return ReminderListNotifier(repository);
});

// Filtered reminders provider
final filteredRemindersProvider = Provider.family<List<Reminder>, String>((ref, searchTerm) {
  final remindersAsync = ref.watch(reminderListProvider);
  
  return remindersAsync.when(
    data: (reminders) {
      if (searchTerm.isEmpty) return reminders;
      
      final query = searchTerm.toLowerCase();
      return reminders.where((reminder) {
        return reminder.title.toLowerCase().contains(query) ||
               reminder.content.toLowerCase().contains(query) ||
               (reminder.contact?.fullName.toLowerCase().contains(query) ?? false);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for pending reminders (chưa hoàn thành)
final pendingRemindersProvider = Provider<List<Reminder>>((ref) {
  final remindersAsync = ref.watch(reminderListProvider);
  
  return remindersAsync.when(
    data: (reminders) => reminders.where((reminder) => !reminder.isDone).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for completed reminders (đã hoàn thành)
final completedRemindersProvider = Provider<List<Reminder>>((ref) {
  final remindersAsync = ref.watch(reminderListProvider);
  
  return remindersAsync.when(
    data: (reminders) => reminders.where((reminder) => reminder.isDone).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for overdue reminders (quá hạn)
final overdueRemindersProvider = Provider<List<Reminder>>((ref) {
  final remindersAsync = ref.watch(reminderListProvider);
  final now = DateTime.now();
  
  return remindersAsync.when(
    data: (reminders) {
      return reminders.where((reminder) {
        if (reminder.isDone || reminder.endTime == null) return false;
        
        try {
          final endTime = DateTime.parse(reminder.endTime!);
          return now.isAfter(endTime);
        } catch (e) {
          return false;
        }
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for today's reminders
final todayRemindersProvider = Provider<List<Reminder>>((ref) {
  final remindersAsync = ref.watch(reminderListProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  
  return remindersAsync.when(
    data: (reminders) {
      return reminders.where((reminder) {
        try {
          final startTime = DateTime.parse(reminder.startTime);
          final reminderDate = DateTime(startTime.year, startTime.month, startTime.day);
          return reminderDate.isAtSameMomentAs(today) ||
                 (reminderDate.isBefore(tomorrow) && reminderDate.isAfter(today.subtract(const Duration(days: 1))));
        } catch (e) {
          return false;
        }
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
}); 