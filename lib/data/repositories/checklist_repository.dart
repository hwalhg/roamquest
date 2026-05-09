import 'dart:io';
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

  Future<void> _ensureLocalUserContext() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      await _localStorage.setUserId(userId);
    }
  }

  /// Save checklist (local + remote)
  Future<void> saveChecklist(Checklist checklist) async {
    try {
      await _ensureLocalUserContext();

      // Save locally first
      await _localStorage.saveChecklist(checklist);

      // Get current user ID
      final userId = _authService.currentUserId;
      if (userId != null) {
        // Keep checklist creation usable even if remote sync is temporarily broken.
        try {
          await _remoteStorage.saveChecklist(checklist, userId: userId);
          AppLogger.info('Checklist saved to remote: ${checklist.id}');
        } catch (e) {
          AppLogger.warning(
            'Failed to save checklist to remote, keeping local copy only: ${checklist.id}',
          );
          AppLogger.error('Checklist remote save error', error: e);
        }
      }

      // Set as current
      await _localStorage.setCurrentChecklistId(checklist.id);
    } catch (e) {
      AppLogger.error('Failed to save checklist', error: e);
      rethrow;
    }
  }

  Future<void> updateChecklist(Checklist checklist) async {
    await saveChecklist(checklist);
  }

  /// Load checklist (local first, fallback to remote)
  Future<Checklist?> loadChecklist(String id) async {
    try {
      await _ensureLocalUserContext();

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
      await _ensureLocalUserContext();

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
      await _ensureLocalUserContext();

      final localChecklists = await _localStorage.getAllChecklists();

      // Get current user ID
      final userId = _authService.currentUserId;
      List<Checklist> remoteChecklists = [];

      if (userId != null) {
        // Try to get from database first (only current user's data)
        remoteChecklists = await _remoteStorage.getRecentChecklists(
            userId: userId, limit: 100);
      }

      if (remoteChecklists.isNotEmpty) {
        // Cache remote copies locally and merge with local-only checklists.
        for (final checklist in remoteChecklists) {
          await _localStorage.saveChecklist(checklist);
        }

        final mergedById = <String, Checklist>{
          for (final checklist in localChecklists) checklist.id: checklist,
        };

        for (final checklist in remoteChecklists) {
          mergedById.putIfAbsent(checklist.id, () => checklist);
        }

        final merged = mergedById.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        return merged;
      }

      // Fallback to local storage
      return localChecklists;
    } catch (e) {
      AppLogger.error('Failed to get all checklists from remote, trying local',
          error: e);
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
        return !checklist.isCustom &&
            checklist.city?.name == city.name &&
            checklist.city?.country == city.country;
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

  /// Get checklist for a city (returns most recent, regardless of completion status)
  /// 复用已有清单：即使所有项目完成，仍然返回已存在的 checklist
  Future<Checklist?> getIncompleteChecklistForCity(City city) async {
    try {
      final allChecklists = await getAllChecklists();

      // Find all checklists for this city
      final cityChecklists = allChecklists.where((checklist) {
        return !checklist.isCustom &&
            checklist.city?.name == city.name &&
            checklist.city?.country == city.country;
      }).toList();

      // Return most recent checklist if exists
      if (cityChecklists.isNotEmpty) {
        cityChecklists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        AppLogger.info(
            'Found existing checklist for city: ${city.name} (${cityChecklists.first.id})');
        return cityChecklists.first;
      }

      // No checklist exists, return null
      return null;
    } catch (e) {
      AppLogger.error('Failed to get checklist for city', error: e);
      return null;
    }
  }

  /// Clear current checklist ID (call when checklist is completed)
  Future<void> clearCurrentChecklist() async {
    try {
      await _ensureLocalUserContext();
      await _localStorage.clearCurrentChecklistId();
      AppLogger.info('Cleared current checklist');
    } catch (e) {
      AppLogger.error('Failed to clear current checklist', error: e);
    }
  }

  /// Load checklist items for a checklist
  Future<List<ChecklistItem>> loadChecklistItems(String checklistId) async {
    try {
      await _ensureLocalUserContext();

      // Try local first
      var items = await _localStorage.loadChecklistItems(checklistId);
      if (items.isNotEmpty) {
        return items;
      }

      // Try remote
      items = await _remoteStorage.loadChecklistItems(checklistId);
      if (items.isNotEmpty) {
        // Cache locally
        await _localStorage.saveChecklistItems(checklistId, items);
        return items;
      }

      return [];
    } catch (e) {
      AppLogger.error('Failed to load checklist items', error: e);
      return [];
    }
  }

  /// Save checklist items (local + remote)
  Future<void> saveChecklistItems(
      String checklistId, List<ChecklistItem> items) async {
    try {
      await _ensureLocalUserContext();

      // Save locally
      await _localStorage.saveChecklistItems(checklistId, items);

      // Get current user ID
      final userId = _authService.currentUserId;
      if (userId != null) {
        // Keep local progress even if remote sync fails.
        try {
          // 重要：在保存前设置正确的 checklistId，防止 RLS 策略检查失败
          for (final item in items) {
            final itemWithChecklistId = item.copyWith(checklistId: checklistId);
            await _remoteStorage
                .saveChecklistItems(checklistId, [itemWithChecklistId]);
          }

          AppLogger.info(
              'Checklist items saved to remote: $checklistId (${items.length} items)');
        } catch (e) {
          AppLogger.warning(
            'Failed to save checklist items to remote, keeping local copy only: $checklistId',
          );
          AppLogger.error('Checklist items remote save error', error: e);
        }
      } else {
        // 用户未登录，只保存本地
        await _localStorage.saveChecklistItems(checklistId, items);
      }
    } catch (e) {
      AppLogger.error('Failed to save checklist items', error: e);
      rethrow;
    }
  }

  /// Update checklist item (mark as completed)
  Future<void> updateItem(
      Checklist checklist, ChecklistItem updatedItem) async {
    try {
      // Load current items
      final currentItems = await loadChecklistItems(checklist.id);
      // Update item in list
      final updatedItems =
          Checklist.updateItemInList(currentItems, updatedItem);
      // Save updated items
      await saveChecklistItems(checklist.id, updatedItems);
    } catch (e) {
      AppLogger.error('Failed to update item', error: e);
      rethrow;
    }
  }

  /// Upload photo and save check-in
  Future<String> uploadPhoto({
    required String checklistId,
    required String itemId,
    required int itemIndex,
    required dynamic photoFile, // Can be XFile (web) or File (mobile)
    double? latitude,
    double? longitude,
    int? rating, // Stored as int 1-20, display as /2.0 for 0.5-10.0 scale
  }) async {
    try {
      // Ensure checklist is saved to remote database first
      final checklist = await loadChecklist(checklistId);
      if (checklist != null) {
        final userId = _authService.currentUserId;
        if (userId != null) {
          try {
            // Ensure checklist is saved to remote database before uploading photo.
            await _remoteStorage.saveChecklist(checklist, userId: userId);
            AppLogger.info(
                'Checklist ensured to be saved to remote: $checklistId');
          } catch (e) {
            AppLogger.warning(
              'Failed to ensure checklist remote state before photo upload: $checklistId',
            );
            AppLogger.error('Checklist ensure remote save error', error: e);
          }
        }
      }

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
        checklistItemId: itemId,
        fileBytes: fileBytes,
      );

      AppLogger.info('Photo uploaded successfully: $photoUrl');

      // Load current items and update the specific item with photo and metadata
      final currentItems = await loadChecklistItems(checklistId);
      final updatedItems = currentItems.map((item) {
        if (item.id == itemId) {
          return item.copyWith(
            photoUrl: photoUrl,
            checkinLatitude: latitude,
            checkinLongitude: longitude,
            rating: rating,
            isCompleted: true,
            completedAt: DateTime.now(),
          );
        }
        return item;
      }).toList();

      // Save updated items
      await saveChecklistItems(checklistId, updatedItems);

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
      await _ensureLocalUserContext();
      await _localStorage.deleteChecklistItems(id);
      await _localStorage.deleteChecklist(id);

      final currentChecklistId = await _localStorage.getCurrentChecklistId();
      if (currentChecklistId == id) {
        await _localStorage.clearCurrentChecklistId();
      }

      final userId = _authService.currentUserId;
      if (userId != null) {
        try {
          await _remoteStorage.deleteChecklist(id);
          AppLogger.info('Checklist deleted from remote: $id');
        } catch (e) {
          AppLogger.warning(
            'Failed to delete checklist from remote, local copy removed: $id',
          );
          AppLogger.error('Checklist remote delete error', error: e);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to delete checklist', error: e);
      rethrow;
    }
  }

  Future<void> deleteChecklistItem({
    required String checklistId,
    required String itemId,
  }) async {
    try {
      await _ensureLocalUserContext();

      final currentItems = await _localStorage.loadChecklistItems(checklistId);
      final updatedItems =
          currentItems.where((item) => item.id != itemId).toList();
      await _localStorage.saveChecklistItems(checklistId, updatedItems);

      final userId = _authService.currentUserId;
      if (userId != null) {
        try {
          await _remoteStorage.deleteChecklistItem(itemId);
          AppLogger.info('Checklist item deleted from remote: $itemId');
        } catch (e) {
          AppLogger.warning(
            'Failed to delete checklist item from remote, local copy removed: $itemId',
          );
          AppLogger.error('Checklist item remote delete error', error: e);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to delete checklist item', error: e);
      rethrow;
    }
  }

  /// Clear all local data
  Future<void> clearLocalData() async {
    try {
      await _ensureLocalUserContext();
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
      await _ensureLocalUserContext();

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
    required int cityId,
    required String language,
  }) async {
    try {
      return await _remoteStorage.getAttractionsByCity(
        cityId: cityId,
        language: language,
      );
    } catch (e) {
      AppLogger.error('Failed to get checklist template', error: e);
      return null;
    }
  }
}
