import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import '../models/checklist.dart';
import '../models/checklist_item.dart';
import '../models/city.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_logger.dart';

/// Service for data storage operations
class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;

  /// Save a checklist header (items are saved separately)
  Future<void> saveChecklist(Checklist checklist, {required String userId}) async {
    try {
      AppLogger.info('Saving checklist header: ${checklist.id} for user: $userId');

      await _client
          .from(ApiConstants.tableChecklists)
          .upsert({
            'id': checklist.id,
            'user_id': userId,
            'city_id': checklist.cityId,
            'language': checklist.language,
            'created_at': checklist.createdAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      AppLogger.info('Checklist header saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save checklist', error: e);
      throw StorageException('Failed to save checklist: $e');
    }
  }

  /// Load a checklist header by ID
  Future<Checklist?> loadChecklist(String id) async {
    try {
      AppLogger.info('Loading checklist header: $id');

      final response = await _client
          .from(ApiConstants.tableChecklists)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return _parseChecklist(response);
    } catch (e) {
      AppLogger.error('Failed to load checklist', error: e);
      return null;
    }
  }

  /// Get recent checklists for a specific user
  Future<List<Checklist>> getRecentChecklists({required String userId, int limit = 10}) async {
    try {
      final response = await _client
          .from(ApiConstants.tableChecklists)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map<Checklist>((data) => _parseChecklist(data)).toList();
    } catch (e) {
      AppLogger.error('Failed to load recent checklists', error: e);
      return [];
    }
  }

  /// Save checklist items (separate from header)
  Future<void> saveChecklistItems(String checklistId, List<ChecklistItem> items) async {
    try {
      AppLogger.info('Saving ${items.length} items for checklist: $checklistId');

      for (final item in items) {
        await _client
            .from(ApiConstants.tableChecklistItems)
            .upsert({
              'id': item.id,
              'checklist_id': checklistId,
              'attraction_id': item.attractionId,
              'title': item.title,
              'location': item.location,
              'category': item.category,
              'sort_order': item.sortOrder,
              'is_completed': item.isCompleted,
              'checkin_photo_url': item.photoUrl,
              'checked_at': item.completedAt?.toIso8601String(),
              'latitude': item.latitude,
              'longitude': item.longitude,
              'rating': item.rating,
              'notes': item.notes,
              'updated_at': DateTime.now().toIso8601String(),
            });
      }

      AppLogger.info('Checklist items saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save checklist items', error: e);
      throw StorageException('Failed to save checklist items: $e');
    }
  }

  /// Delete a checklist
  Future<void> deleteChecklist(String id) async {
    try {
      // Delete checklist items first (due to foreign key)
      await _client
          .from(ApiConstants.tableChecklistItems)
          .delete()
          .eq('checklist_id', id);

      // Then delete checklist header
      await _client
          .from(ApiConstants.tableChecklists)
          .delete()
          .eq('id', id);

      AppLogger.info('Checklist deleted: $id');
    } catch (e) {
      AppLogger.error('Failed to delete checklist', error: e);
      throw StorageException('Failed to delete checklist: $e');
    }
  }

  /// Load checklist items for a specific checklist
  Future<List<ChecklistItem>> loadChecklistItems(String checklistId) async {
    try {
      AppLogger.info('Loading items for checklist: $checklistId');

      final response = await _client
          .from(ApiConstants.tableChecklistItems)
          .select()
          .eq('checklist_id', checklistId)
          .order('sort_order', ascending: true);

      return response
          .map<ChecklistItem>((itemData) => ChecklistItem.fromJson(itemData))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to load checklist items', error: e);
      return [];
    }
  }

  /// Upload a photo (works on both web and mobile)
  Future<String> uploadPhoto({
    required String filePath,
    required String checklistItemId,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      AppLogger.info('Uploading photo for checklist item: $checklistItemId');

      // Generate file name if not provided
      if (fileName == null) {
        final fileExtension = path.extension(filePath);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = '$checklistItemId/$timestamp$fileExtension';
      }

      AppLogger.info('Uploading file: $fileName');

      // Upload to Supabase Storage
      if (fileBytes != null) {
        // Web: Use bytes directly
        await _client.storage
            .from(ApiConstants.storagePhotos)
            .uploadBinary(fileName, Uint8List.fromList(fileBytes));
      } else {
        // Mobile: Use File (dart:io)
        final file = File(filePath);
        await _client.storage
            .from(ApiConstants.storagePhotos)
            .upload(fileName, file);
      }

      // Get public URL
      final publicUrl = _client.storage
          .from(ApiConstants.storagePhotos)
          .getPublicUrl(fileName);

      AppLogger.info('Photo uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Failed to upload photo', error: e);
      throw StorageException('Failed to upload photo: $e');
    }
  }


  /// Get attractions for a city by city_id
  Future<List<ChecklistItem>?> getAttractionsByCity({
    required int cityId,
    required String language,
  }) async {
    try {
      AppLogger.info('Looking for attractions for city_id: $cityId, language: $language');

      final response = await _client
          .from(ApiConstants.tableAttractions)
          .select()
          .eq('city_id', cityId)
          .eq('language', language)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (response == null || response.isEmpty) {
        AppLogger.info('No attractions found for city_id: $cityId');
        return null;
      }

      final items = response
          .map<ChecklistItem>((itemData) => ChecklistItem.fromJson(itemData))
          .toList();

      AppLogger.info('Found ${items.length} attractions for city_id: $cityId');
      return items;
    } catch (e) {
      AppLogger.error('Failed to get attractions', error: e);
      return null;
    }
  }

  /// Save attractions (after AI generation) - inserts each attraction as a separate row
  Future<void> saveAttractions({
    required int cityId,
    required List<ChecklistItem> items,
    required String language,
  }) async {
    try {
      AppLogger.info('Saving ${items.length} attractions for city_id: $cityId');

      // Insert each attraction as a separate row
      for (int i = 0; i < items.length; i++) {
        final item = items[i];

        await _client
            .from(ApiConstants.tableAttractions)
            .insert({
              'city_id': cityId,
              'title': item.title,
              'location': item.location,
              'category': item.category,
              'language': language,
              'is_active': true,
              'sort_order': i,
            });
      }

      AppLogger.info('Attractions saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save attractions', error: e);
      throw StorageException('Failed to save attractions: $e');
    }
  }

  /// Parse checklist from database response
  Checklist _parseChecklist(Map<String, dynamic> data) {
    return Checklist(
      id: data['id'] as String,
      cityId: data['city_id'] as int,
      city: City(
        id: data['city_id'] as int,
        name: data['city_name'] as String,
        country: data['country'] as String,
        countryCode: data['country_code'] as String? ?? 'XX',
        latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      userId: data['user_id'] as String,
      createdAt: DateTime.parse(data['created_at'] as String),
      language: data['language'] as String,
    );
  }
}

/// Storage exceptions
class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => message;
}
