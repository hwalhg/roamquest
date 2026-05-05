import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/checklist.dart';
import '../../l10n/app_localizations.dart';

class CreateCustomChecklistPage extends StatefulWidget {
  final String userId;
  final String language;
  final Checklist? initialChecklist;

  const CreateCustomChecklistPage({
    super.key,
    required this.userId,
    required this.language,
    this.initialChecklist,
  });

  @override
  State<CreateCustomChecklistPage> createState() =>
      _CreateCustomChecklistPageState();
}

class _CreateCustomChecklistPageState extends State<CreateCustomChecklistPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.initialChecklist != null;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialChecklist?.title ?? '';
    _descriptionController.text = widget.initialChecklist?.description ?? '';
  }

  void _saveChecklist() {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    final checklist = _isEditing
        ? widget.initialChecklist!.copyWith(
            title: _titleController.text.trim(),
            description: description,
            clearDescription: description == null,
          )
        : Checklist.custom(
            title: _titleController.text.trim(),
            description: description,
            userId: widget.userId,
            language: widget.language,
          );

    Navigator.pop(context, checklist);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? l10n.get('editChecklist')
              : l10n.get('createCustomChecklist'),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                _isEditing
                    ? l10n.get('customChecklistDescriptionHint')
                    : l10n.get('createCustomChecklistDesc'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.get('customChecklistTitle'),
                  hintText: l10n.get('customChecklistTitleHint'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.get('pleaseEnterChecklistTitle');
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: l10n.get('customChecklistDescription'),
                  hintText: l10n.get('customChecklistDescriptionHint'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: SizedBox(
            height: 52,
              child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        _isSaving = true;
                      });
                      _saveChecklist();
                    },
              child: Text(
                _isEditing
                    ? l10n.get('saveChecklistChanges')
                    : l10n.get('saveChecklistAndAddSpot'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
