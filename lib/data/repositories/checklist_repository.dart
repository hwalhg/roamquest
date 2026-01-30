import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/checklist.dart';
import '../models/checklist_item.dart';
import '../models/city.dart';
import '../services/storage_service.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../../core/utils/app_logger.dart';

/// Repository for checklist data operations
class ChecklistRepository {
  final StorageService _remoteStorage = StorageService();
  final LocalStorageService _localStorage = LocalStorageService();
  final AuthService _authService = AuthService();

  /// Save checklist (local + remote)
  Future<void> saveChecklist(Checklist checklist) async {
    try {
      // Save locally first
      await _localStorage.saveChecklist(checklist);

      // Get current user ID
      final userId = _authService.currentUserId;
      if (userId != null) {
        // Save to remote (fire and forget)
        _remoteStorage.saveChecklist(checklist, userId: userId).catchError((e) {
          AppLogger.warning('Failed to save checklist to remote: $e');
        });
      }

      // Set as current
      await _localStorage.setCurrentChecklistId(checklist.id);
    } catch (e) {
      AppLogger.error('Failed to save checklist', error: e);
      rethrow;
    }
  }

  /// Load checklist (local first, fallback to remote)
  Future<Checklist?> loadChecklist(String id) async {
    try {
      // Try local first
      var checklist = await _localStorage.loadChecklist(id);
      if (checklist != null) {
        return checklist;
      }

      // Try remote
      checklist = await _remoteStorage.loadChecklist(id);
      if (checklist != null) {
        // Cache locally
        await _localStorage.saveChecklist(checklist);
        return checklist;
      }

      return null;
    } catch (e) {
      AppLogger.error('Failed to load checklist', error: e);
      return null;
    }
  }

  /// Get current checklist
  Future<Checklist?> getCurrentChecklist() async {
    try {
      final currentId = await _localStorage.getCurrentChecklistId();
      if (currentId == null) return null;

      return await loadChecklist(currentId);
    } catch (e) {
      AppLogger.error('Failed to get current checklist', error: e);
      return null;
    }
  }

  /// Get all checklists (from database first, fallback to local)
  Future<List<Checklist>> getAllChecklists() async {
    try {
      // Get current user ID
      final userId = _authService.currentUserId;
      List<Checklist> remoteChecklists = [];

      if (userId != null) {
        // Try to get from database first (only current user's data)
        remoteChecklists = await _remoteStorage.getRecentChecklists(userId: userId, limit: 100);
      }

      if (remoteChecklists.isNotEmpty) {
        // Cache locally
        for (final checklist in remoteChecklists) {
          await _localStorage.saveChecklist(checklist);
        }
        return remoteChecklists;
      }

      // Fallback to local storage
      return await _localStorage.getAllChecklists();
    } catch (e) {
      AppLogger.error('Failed to get all checklists from remote, trying local', error: e);
      try {
        return await _localStorage.getAllChecklists();
      } catch (e2) {
        AppLogger.error('Failed to get all checklists', error: e2);
        return [];
      }
    }
  }

  /// Get checklist for a specific city (returns the most recent one)
  Future<Checklist?> getChecklistForCity(City city) async {
    try {
      final allChecklists = await getAllChecklists();

      // Find checklists for this city
      final cityChecklists = allChecklists.where((checklist) {
        return checklist.city.name == city.name &&
            checklist.city.country == city.country;
      }).toList();

      if (cityChecklists.isEmpty) return null;

      // Return the most recent one
      cityChecklists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cityChecklists.first;
    } catch (e) {
      AppLogger.error('Failed to get checklist for city', error: e);
      return null;
    }
  }

  /// Get incomplete checklist for a city
  Future<Checklist?> getIncompleteChecklistForCity(City city) async {
    try {
      final allChecklists = await getAllChecklists();

      // Find incomplete checklists for this city
      final incompleteChecklists = allChecklists.where((checklist) {
        return checklist.city.name == city.name &&
            checklist.city.country == city.country &&
            checklist.completedCount < checklist.items.length;
      }).toList();

      if (incompleteChecklists.isEmpty) return null;

      // Return the most recent one
      incompleteChecklists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return incompleteChecklists.first;
    } catch (e) {
      AppLogger.error('Failed to get incomplete checklist for city', error: e);
      return null;
    }
  }

  /// Clear current checklist ID (call when checklist is completed)
  Future<void> clearCurrentChecklist() async {
    try {
      await _localStorage.clearCurrentChecklistId();
      AppLogger.info('Cleared current checklist');
    } catch (e) {
      AppLogger.error('Failed to clear current checklist', error: e);
    }
  }

  /// Update checklist item (mark as completed)
  Future<void> updateItem(Checklist checklist, ChecklistItem updatedItem) async {
    try {
      final updatedChecklist = checklist.updateItem(updatedItem);
      await saveChecklist(updatedChecklist);
    } catch (e) {
      AppLogger.error('Failed to update item', error: e);
      rethrow;
    }
  }

  /// Upload photo and save check-in
  Future<String> uploadPhoto({
    required String checklistId,
    required String itemId,
    required dynamic photoFile, // Can be XFile (web) or File (mobile)
    double? latitude,
    double? longitude,
    int? rating, // Stored as int 1-20, display as /2.0 for 0.5-10.0 scale
  }) async {
    try {
      // Read file bytes (works for both XFile and web)
      List<int>? fileBytes;
      String filePath;

      if (photoFile is XFile) {
        // XFile works on both web and mobile
        filePath = photoFile.path;
        fileBytes = await photoFile.readAsBytes();
        AppLogger.info('Read XFile bytes: ${fileBytes.length} bytes');
      } else if (photoFile is File) {
        // File from dart:io (mobile only)
        filePath = photoFile.path;
        if (kIsWeb) {
          fileBytes = await photoFile.readAsBytes();
        }
      } else {
        throw ArgumentError('photoFile must be XFile or File');
      }

      // Upload to remote storage
      final photoUrl = await _remoteStorage.uploadPhoto(
        filePath: filePath,
        checkinId: itemId,
        fileBytes: fileBytes,
      );

      AppLogger.info('Photo uploaded successfully: $photoUrl');

      // Get current user ID
      final userId = _authService.currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Save check-in data
      await _remoteStorage.saveCheckin(
        checklistId: checklistId,
        itemId: itemId,
        photoUrl: photoUrl,
        latitude: latitude,
        longitude: longitude,
        rating: rating,
        userId: userId,
      );

      return photoUrl;
    } catch (e) {
      AppLogger.error('Failed to upload photo', error: e);
      rethrow;
    }
  }

  /// Get photo for check-in item
  Future<String?> getPhotoPath(String checkinId) async {
    try {
      return await _localStorage.getPhotoPath(checkinId);
    } catch (e) {
      AppLogger.error('Failed to get photo path', error: e);
      return null;
    }
  }

  /// Delete checklist
  Future<void> deleteChecklist(String id) async {
    try {
      await _localStorage.deleteChecklist(id);
      // Note: We keep remote data for backup
    } catch (e) {
      AppLogger.error('Failed to delete checklist', error: e);
      rethrow;
    }
  }

  /// Clear all local data
  Future<void> clearLocalData() async {
    try {
      await _localStorage.clearAll();
      AppLogger.info('Cleared all local data');
    } catch (e) {
      AppLogger.error('Failed to clear local data', error: e);
      rethrow;
    }
  }

  /// Sync local data to remote
  Future<void> syncToRemote() async {
    try {
      final userId = _authService.currentUserId;
      if (userId == null) {
        AppLogger.warning('User not authenticated, skipping sync');
        return;
      }

      final checklists = await _localStorage.getAllChecklists();

      for (final checklist in checklists) {
        await _remoteStorage.saveChecklist(checklist, userId: userId);
      }

      AppLogger.info('Synced ${checklists.length} checklists to remote');
    } catch (e) {
      AppLogger.error('Failed to sync to remote', error: e);
    }
  }

  /// Get checklist template for a city
  Future<List<ChecklistItem>?> getChecklistTemplate({
    required String cityName,
    required String country,
    required String language,
  }) async {
    try {
      return await _remoteStorage.getChecklistTemplate(
        cityName: cityName,
        country: country,
        language: language,
      );
    } catch (e) {
      AppLogger.error('Failed to get checklist template', error: e);
      return null;
    }
  }

  /// Save checklist template (after AI generation)
  Future<void> saveChecklistTemplate({
    required City city,
    required List<ChecklistItem> items,
    required String language,
  }) async {
    try {
      await _remoteStorage.saveChecklistTemplate(
        city: city,
        items: items,
        language: language,
      );
    } catch (e) {
      AppLogger.error('Failed to save checklist template', error: e);
      rethrow;
    }
  }
}
