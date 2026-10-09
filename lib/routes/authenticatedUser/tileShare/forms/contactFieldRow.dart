import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'package:tiler_app/util.dart';

/// Adding a person by email or phone number, as a form kit row (icon chip,
/// label, plain field, add button) - for the tilette sheet now and the create
/// flow later. Hands each valid entry to [onContact] and clears for the next;
/// an invalid one says so under the field.
class ContactFieldRow extends StatefulWidget {
  final String label;
  final ValueChanged<Contact> onContact;

  /// Shown under the field, e.g. that the person is already invited.
  final String? message;

  const ContactFieldRow({
    super.key,
    required this.label,
    required this.onContact,
    this.message,
  });

  @override
  State<ContactFieldRow> createState() => _ContactFieldRowState();
}

class _ContactFieldRowState extends State<ContactFieldRow> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _invalid = false;

  bool get _valid => _isContact(_controller.text.trim());

  static bool _isContact(String value) =>
      Utility.isEmail(value) || Utility.isPhoneNumber(value);

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final String value = _controller.text.trim();
    if (value.isEmpty) return;
    if (!_isContact(value)) {
      setState(() => _invalid = true);
      return;
    }
    final Contact contact = Contact();
    if (Utility.isEmail(value)) contact.email = value;
    if (Utility.isPhoneNumber(value)) contact.phoneNumber = value;
    _controller.clear();
    setState(() => _invalid = false);
    widget.onContact(contact);
    // Stay in the field for the next person.
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String? message = _invalid ? l10n.invalidContactFormat : widget.message;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: AddTileIconChip(icon: Icons.person_add_alt_1_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Text(widget.label,
                    style: textTheme.labelSmall?.copyWith(
                        color: tokens.textSecondary, letterSpacing: 0.6)),
                TextField(
                  controller: _controller,
                  focusNode: _focus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _invalid = false),
                  onSubmitted: (_) => _add(),
                  style: textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: l10n.addContact,
                    hintStyle: textTheme.titleMedium
                        ?.copyWith(color: tokens.textSecondary),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(message,
                        style:
                            textTheme.bodySmall?.copyWith(color: scheme.error)),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.addContact,
            onPressed: _valid ? _add : null,
            icon: Icon(Icons.add_circle,
                color: _valid ? scheme.primary : tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}
