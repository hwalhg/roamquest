import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/checklist.dart';
import '../../data/models/checklist_item.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../data/services/location_service.dart';
import '../../l10n/app_localizations.dart';

/// Page for adding a custom checklist item
class AddChecklistItemPage extends StatefulWidget {
  final Checklist checklist;

  const AddChecklistItemPage({
    super.key,
    required this.checklist,
  });

  @override
  State<AddChecklistItemPage> createState() => _AddChecklistItemPageState();
}

class _AddChecklistItemPageState extends State<AddChecklistItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final LocationService _locationService = LocationService();
  final ChecklistRepository _repository = ChecklistRepository();

  String _selectedCategory = 'landmark';
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加打卡点'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveItem,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '添加',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title input (required)
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题 *',
                hintText: '例如：参观故宫',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入标题';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Location input (optional)
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '位置',
                hintText: '例如：天安门广场',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 8),

            // Auto location button
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('获取当前位置'),
              subtitle: Text(
                _latitude != null && _longitude != null
                    ? '已定位: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                    : '点击获取GPS定位',
              ),
              trailing: _isGettingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _latitude != null ? Icons.check_circle : Icons.my_location,
                      color: _latitude != null ? Colors.green : null,
                    ),
              onTap: _getCurrentLocation,
            ),

            const SizedBox(height: 24),

            // Category selection
            const Text(
              '选择分类',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCategoryChip('landmark', '🏛️', '地标'),
                _buildCategoryChip('food', '🍜', '美食'),
                _buildCategoryChip('experience', '🎭', '体验'),
                _buildCategoryChip('hidden', '💎', '隐藏'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String value, String emoji, String label) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      elevation: 0,
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取定位失败: $e')),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Auto-assign order (current max + 1)
      final maxOrder = widget.checklist.items
          .map((item) => item.order)
          .fold(0, (max, order) => order > max ? order : max);

      final newItem = ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? '自定义位置'
            : _locationController.text.trim(),
        category: _selectedCategory,
        order: maxOrder + 1,
        isCompleted: false,
        // Use location if available, otherwise use city center
        latitude: _latitude ?? widget.checklist.city.latitude,
        longitude: _longitude ?? widget.checklist.city.longitude,
      );

      // Save to checklist
      final updatedItems = [...widget.checklist.items, newItem];
      final updatedChecklist = widget.checklist.copyWith(items: updatedItems);

      await _repository.saveChecklist(updatedChecklist);

      if (mounted) {
        Navigator.pop(context, newItem);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
