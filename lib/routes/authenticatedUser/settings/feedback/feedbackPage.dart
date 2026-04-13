import 'package:flutter/material.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/settingsApi.dart';

class FeedbackPage extends StatefulWidget {
  static final String routeName = '/Feedback';

  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<String> _categories = ['Bug', 'Feature', 'Enhancement', 'General'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isFormValid() {
    return _titleController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
  }

  Future<bool> _submitFeedback() async {
    if (!_isFormValid()) return false;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final settingsApi =
          SettingsApi(getContextCallBack: () => context);
      await settingsApi.sendFeedback(
        category: _selectedCategory,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        NotificationOverlayMessage().showToast(
          context,
          AppLocalizations.of(context)!.feedbackSubmitted,
          NotificationOverlayMessageType.success,
        );
        Navigator.pop(context);
      }
      return true;
    } catch (e) {
      if (mounted) {
        NotificationOverlayMessage().showToast(
          context,
          AppLocalizations.of(context)!.feedbackError,
          NotificationOverlayMessageType.error,
        );
        setState(() {
          _isSubmitting = false;
        });
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return CancelAndProceedTemplateWidget(
      routeName: FeedbackPage.routeName,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.feedback),
      ),
      onProceed: _isFormValid() && !_isSubmitting ? _submitFeedback : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.feedbackCategory,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(_getCategoryLabel(context, category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.feedbackTitle,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.feedbackTitleHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.feedbackDescription,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.feedbackDescriptionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(BuildContext context, String category) {
    switch (category) {
      case 'Bug':
        return AppLocalizations.of(context)!.feedbackCategoryBug;
      case 'Feature':
        return AppLocalizations.of(context)!.feedbackCategoryFeature;
      case 'Enhancement':
        return AppLocalizations.of(context)!.feedbackCategoryEnhancement;
      case 'General':
        return AppLocalizations.of(context)!.feedbackCategoryGeneral;
      default:
        return category;
    }
  }
}
