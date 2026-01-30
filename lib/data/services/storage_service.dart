import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
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

  /// Save a checklist
  Future<void> saveChecklist(Checklist checklist, {required String userId}) async {
    try {
      AppLogger.info('Saving checklist: ${checklist.id} for user: $userId');

      await _client
          .from(ApiConstants.tableChecklists)
          .upsert({
            'id': checklist.id,
            'user_id': userId,
            'city_name': checklist.city.name,
            'country': checklist.city.country,
            'country_code': checklist.city.countryCode,
            'latitude': checklist.city.latitude,
            'longitude': checklist.city.longitude,
            'language': checklist.language,
            'items': checklist.items.map((item) => item.toJson()).toList(),
            'created_at': checklist.createdAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      AppLogger.info('Checklist saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save checklist', error: e);
      throw StorageException('Failed to save checklist: $e');
    }
  }

  /// Load a checklist by ID
  Future<Checklist?> loadChecklist(String id) async {
    try {
      AppLogger.info('Loading checklist: $id');

      final response = await _client
          .from(ApiConstants.tableChecklists)
          .select()
          .eq('id', id)
          .single();

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

  /// Upload a photo (works on both web and mobile)
  Future<String> uploadPhoto({
    required String filePath,
    required String checkinId,
    List<int>? fileBytes,
    String? fileName,
  }) async {
    try {
      AppLogger.info('Uploading photo for checkin: $checkinId');

      // Generate file name if not provided
      if (fileName == null) {
        final fileExtension = path.extension(filePath);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        fileName = '$checkinId/$timestamp$fileExtension';
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

  /// Save checkin data
  Future<void> saveCheckin({
    required String checklistId,
    required String itemId,
    required String photoUrl,
    double? latitude,
    double? longitude,
    int? rating, // Stored as int 1-20, display as /2.0 for 0.5-10.0 scale
    required String userId,
  }) async {
    try {
      AppLogger.info('Saving checkin for item: $itemId, user: $userId');

      final data = {
        'checklist_id': checklistId,
        'item_id': itemId,
        'photo_url': photoUrl,
        'latitude': latitude,
        'longitude': longitude,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (rating != null) {
        data['rating'] = rating;
      }

      await _client.from('checkins').insert(data);

      AppLogger.info('Checkin saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save checkin', error: e);
      throw StorageException('Failed to save checkin: $e');
    }
  }

  /// Delete a checklist
  Future<void> deleteChecklist(String id) async {
    try {
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

  /// Get checklist template for a city
  Future<List<ChecklistItem>?> getChecklistTemplate({
    required String cityName,
    required String country,
    required String language,
  }) async {
    try {
      AppLogger.info('Looking for checklist template: $cityName, $country, $language');

      final response = await _client
          .from('checklist_templates')
          .select('items')
          .eq('city_name', cityName)
          .eq('country', country)
          .eq('language', language)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null || response['items'] == null) {
        AppLogger.info('No template found for $cityName, $country');
        return null;
      }

      final itemsData = response['items'] as List;
      final items = itemsData
          .map((itemData) => ChecklistItem.fromJson(itemData as Map<String, dynamic>))
          .toList();

      AppLogger.info('Found template with ${items.length} items');
      return items;
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
      final id = '${city.name}_${city.country}_$language';

      AppLogger.info('Saving checklist template: $id');

      await _client
          .from('checklist_templates')
          .upsert({
            'id': id,
            'city_name': city.name,
            'country': city.country,
            'country_code': city.countryCode,
            'language': language,
            'items': items.map((item) => item.toJson()).toList(),
            'is_active': true,
            'updated_at': DateTime.now().toIso8601String(),
          }, onConflict: 'city_name, country, language');

      AppLogger.info('Checklist template saved successfully');
    } catch (e) {
      AppLogger.error('Failed to save checklist template', error: e);
      throw StorageException('Failed to save checklist template: $e');
    }
  }

  /// Parse checklist from database response
  Checklist _parseChecklist(Map<String, dynamic> data) {
    // Reconstruct City
    final city = City(
      name: data['city_name'] as String,
      country: data['country'] as String,
      countryCode: data['country_code'] as String,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
    );

    // Reconstruct items
    final itemsData = data['items'] as List;
    final items = itemsData
        .map((itemData) => ChecklistItem.fromJson(itemData as Map<String, dynamic>))
        .toList();

    return Checklist(
      id: data['id'] as String,
      city: city,
      items: items,
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
