import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/auth_service.dart';

/// Profile edit page
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final AuthService _auth = AuthService();
  final TextEditingController _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  String? _avatarImagePath; // Local file path for avatar
  XFile? _avatarImageFile; // Keep reference to the XFile

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _auth.getCurrentProfile();
      if (profile != null) {
        if (profile.fullName != null) {
          _nicknameController.text = profile.fullName!;
        }
        if (profile.avatarUrl != null) {
          setState(() {
            _avatarImagePath = profile.avatarUrl;
          });
        }
      }
    } catch (e) {
      // Ignore error, use default values
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _avatarImagePath = image.path;
          _avatarImageFile = image; // Store the XFile for later upload
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<String?> _uploadAvatar(XFile imageFile) async {
    try {
      final userId = _auth.currentUserId;
      if (userId == null) return null;

      // Generate unique file name
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Read file bytes
      final bytes = await imageFile.readAsBytes();

      // Upload to Supabase Storage
      await _supabase.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // Get public URL
      final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final nickname = _nicknameController.text.trim();
      if (nickname.isEmpty) {
        setState(() {
          _errorMessage = 'Nickname cannot be empty';
          _isLoading = false;
        });
        return;
      }

      // Upload avatar if a new one was selected
      String? avatarUrl;
      if (_avatarImageFile != null) {
        avatarUrl = await _uploadAvatar(_avatarImageFile!);
        if (avatarUrl == null) {
          setState(() {
            _errorMessage = 'Failed to upload avatar';
            _isLoading = false;
          });
          return;
        }
      }

      // Update profile with nickname and avatar URL
      final updateData = <String, dynamic>{
        'full_name': nickname,
      };
      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      final success = await _auth.updateProfile(updateData);

      if (!success) {
        setState(() {
          _errorMessage = 'Failed to update profile';
        });
        return;
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.sunsetGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar with back button only
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),

                        // Avatar
                        Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _pickAvatar,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: AppColors.textOnDark.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: _avatarImagePath != null
                                          ? ClipOval(
                                              child: kIsWeb
                                                  ? Image.network(
                                                      _avatarImagePath!,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Image.file(
                                                      File(_avatarImagePath!),
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                    ),
                                            )
                                          : Text(
                                              _getInitials(),
                                              style: const TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textOnDark,
                                              ),
                                            ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 20,
                                          color: AppColors.textOnDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Email (read-only)
                        TextFormField(
                          initialValue: user?.email ?? '',
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textOnDark.withOpacity(0.7),
                            ),
                            filled: true,
                            fillColor: AppColors.textOnDark.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            disabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textOnDark.withOpacity(0.5),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Nickname
                        TextFormField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            labelText: 'Nickname',
                            labelStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textOnDark.withOpacity(0.7),
                            ),
                            hintText: 'Enter your nickname',
                            filled: true,
                            fillColor: AppColors.textOnDark.withOpacity(0.15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.textOnDark,
                                width: 2,
                              ),
                            ),
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textOnDark,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a nickname';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textOnDark,
                              foregroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.textOnDark.withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Text(
                                    'Save',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials() {
    final email = _auth.currentUserEmail ?? '';
    if (email.isEmpty) return '?';
    return email[0].toUpperCase();
  }
}
