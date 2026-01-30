import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/checklist.dart';
import '../../core/utils/app_logger.dart';

/// Local storage service for caching data (isolated by user)
class LocalStorageService {
  static const String _keyChecklists = 'checklists';
  static const String _keyCurrentChecklistId = 'current_checklist_id';
  static const String _keyCheckinPhotos = 'checkin_photos';
  static const String _keyCurrentUserId = 'current_user_id';

  /// Get current user ID for data isolation
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentUserId);
  }

  /// Set current user ID (called on login)
  Future<void> _setCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUserId, userId);
    AppLogger.info('Set current user ID: $userId');
  }

  /// Clear current user ID (called on logout)
  Future<void> _clearCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUserId);
    AppLogger.info('Cleared current user ID');
  }

  /// Get user-specific key
  Future<String> _getUserKey(String baseKey) async {
    final userId = await _getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      // Fallback to anonymous key if no user logged in
      return 'anonymous_$baseKey';
    }
    return '${userId}_$baseKey';
  }

  /// Save checklist to local storage
  Future<void> saveChecklist(Checklist checklist) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyChecklists);
      final checklistsJson = prefs.getString(key) ?? '{}';
      final checklists = json.decode(checklistsJson) as Map<String, dynamic>;

      checklists[checklist.id] = checklist.toJson();

      await prefs.setString(key, json.encode(checklists));
      AppLogger.info('Saved checklist: ${checklist.id}');
    } catch (e) {
      AppLogger.error('Failed to save checklist', error: e);
    }
  }

  /// Load checklist from local storage
  Future<Checklist?> loadChecklist(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyChecklists);
      final checklistsJson = prefs.getString(key);

      if (checklistsJson == null) return null;

      final checklists = json.decode(checklistsJson) as Map<String, dynamic>;
      final checklistJson = checklists[id];

      if (checklistJson == null) return null;

      return Checklist.fromJson(checklistJson);
    } catch (e) {
      AppLogger.error('Failed to load checklist', error: e);
      return null;
    }
  }

  /// Get all checklists
  Future<List<Checklist>> getAllChecklists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyChecklists);
      final checklistsJson = prefs.getString(key);

      if (checklistsJson == null) return [];

      final checklists = json.decode(checklistsJson) as Map<String, dynamic>;

      return checklists.values
          .map((json) => Checklist.fromJson(json as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger.error('Failed to load checklists', error: e);
      return [];
    }
  }

  /// Delete checklist from local storage
  Future<void> deleteChecklist(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyChecklists);
      final checklistsJson = prefs.getString(key);

      if (checklistsJson == null) return;

      final checklists = json.decode(checklistsJson) as Map<String, dynamic>;
      checklists.remove(id);

      await prefs.setString(key, json.encode(checklists));
      AppLogger.info('Deleted checklist: $id');
    } catch (e) {
      AppLogger.error('Failed to delete checklist', error: e);
    }
  }

  /// Set current checklist ID
  Future<void> setCurrentChecklistId(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyCurrentChecklistId);
      await prefs.setString(key, id);
      AppLogger.info('Set current checklist: $id');
    } catch (e) {
      AppLogger.error('Failed to set current checklist', error: e);
    }
  }

  /// Get current checklist ID
  Future<String?> getCurrentChecklistId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyCurrentChecklistId);
      return prefs.getString(key);
    } catch (e) {
      AppLogger.error('Failed to get current checklist', error: e);
      return null;
    }
  }

  /// Clear current checklist ID
  Future<void> clearCurrentChecklistId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyCurrentChecklistId);
      await prefs.remove(key);
      AppLogger.info('Cleared current checklist');
    } catch (e) {
      AppLogger.error('Failed to clear current checklist', error: e);
    }
  }

  /// Save photo path for a check-in
  Future<void> savePhotoPath(String checkinId, String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyCheckinPhotos);
      final photosJson = prefs.getString(key) ?? '{}';
      final photos = json.decode(photosJson) as Map<String, dynamic>;

      photos[checkinId] = path;

      await prefs.setString(key, json.encode(photos));
      AppLogger.info('Saved photo path: $checkinId');
    } catch (e) {
      AppLogger.error('Failed to save photo path', error: e);
    }
  }

  /// Get photo path for a check-in
  Future<String?> getPhotoPath(String checkinId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getUserKey(_keyCheckinPhotos);
      final photosJson = prefs.getString(key);

      if (photosJson == null) return null;

      final photos = json.decode(photosJson) as Map<String, dynamic>;
      return photos[checkinId] as String?;
    } catch (e) {
      AppLogger.error('Failed to get photo path', error: e);
      return null;
    }
  }

  /// Clear all data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final checklistsKey = await _getUserKey(_keyChecklists);
      final currentChecklistKey = await _getUserKey(_keyCurrentChecklistId);
      final photosKey = await _getUserKey(_keyCheckinPhotos);
      await prefs.remove(checklistsKey);
      await prefs.remove(currentChecklistKey);
      await prefs.remove(photosKey);
      AppLogger.info('Cleared all local storage');
    } catch (e) {
      AppLogger.error('Failed to clear storage', error: e);
    }
  }

  /// Get storage size in bytes
  Future<int> getStorageSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int size = 0;
      for (final key in keys) {
        final value = prefs.get(key);
        if (value is String) {
          size += value.length;
        }
      }

      return size;
    } catch (e) {
      AppLogger.error('Failed to calculate storage size', error: e);
      return 0;
    }
  }

  /// Set current user ID (call this when user logs in)
  Future<void> setUserId(String userId) async {
    await _setCurrentUserId(userId);
  }

  /// Clear current user ID (call this when user logs out)
  Future<void> clearUserId() async {
    await _clearCurrentUserId();
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    return await _getCurrentUserId();
  }
}
