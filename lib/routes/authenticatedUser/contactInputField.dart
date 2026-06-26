import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

class ContactInputFieldWidget extends StatefulWidget {
  final List<Contact>? contacts;
  final Function? onContactUpdate;
  final double? contentHeight;
  final bool isReadOnly;
  ContactInputFieldWidget(
      {this.onContactUpdate,
      this.contentHeight,
      this.contacts,
      this.isReadOnly = true});
  @override
  _ContactInputFieldWidgetState createState() =>
      _ContactInputFieldWidgetState();
}

class _ContactInputFieldWidgetState extends State<ContactInputFieldWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<Contact> _contacts = [];
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  bool _showValidationError = false;
  bool _isExpanded = false;
  bool _isInputValid = false;

  @override
  void initState() {
    super.initState();
    if (this.widget.contacts != null) {
      this._contacts = this.widget.contacts!;
    }
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final text = _controller.text;
    final isValid = text.isNotEmpty && _isValidContact(text);
    final clearError = text.isEmpty && _showValidationError;
    if (isValid != _isInputValid || clearError) {
      setState(() {
        _isInputValid = isValid;
        if (clearError) _showValidationError = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool _isValidContact(String input) {
    return Utility.isEmail(input) || Utility.isPhoneNumber(input);
  }

  void _addContact(String contactVal) {
    if (contactVal.isEmpty) return;
    var priorContact = _contacts.toList();
    if (_isValidContact(contactVal)) {
      setState(() {
        final contactObj = Contact();
        if (Utility.isEmail(contactVal)) {
          contactObj.email = contactVal;
        }
        if (Utility.isPhoneNumber(contactVal)) {
          contactObj.phoneNumber = contactVal;
        }
        _contacts.add(contactObj);
        _showValidationError = false;
      });
      _controller.clear();
      // Stay expanded and refocus for rapid multi-add.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
      if (this.widget.onContactUpdate != null &&
          !priorContact.any((eachContact) =>
              eachContact.email == contactVal ||
              eachContact.phoneNumber == contactVal)) {
        this.widget.onContactUpdate!(_contacts);
      }
    } else {
      setState(() {
        _showValidationError = true;
      });
    }
  }

  void _removeContact(Contact contact) {
    if (!this.widget.isReadOnly) {
      setState(() {
        _contacts.remove(contact);
      });
      if (this.widget.onContactUpdate != null) {
        this.widget.onContactUpdate!(_contacts);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isReadOnly = this.widget.isReadOnly;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: _showValidationError
                    ? colorScheme.error
                    : colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ..._contacts.map((contact) => _buildPill(contact)),
                      if (!isReadOnly && _isExpanded)
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 80,
                            maxWidth: 220,
                          ),
                          child: _buildTextField(),
                        ),
                    ],
                  ),
                ),
                if (!isReadOnly)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _isExpanded
                        ? _buildCheckButton(loc)
                        : _buildExpandButton(loc),
                  ),
              ],
            ),
          ),
          if (_showValidationError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text(
                loc.invalidContactFormat,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpandButton(AppLocalizations loc) {
    return IconButton(
      icon: const Icon(Icons.add),
      tooltip: loc.addContact,
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
      ),
      onPressed: () {
        setState(() {
          _isExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      },
    );
  }

  Widget _buildCheckButton(AppLocalizations loc) {
    return IconButton(
      icon: const Icon(Icons.check),
      tooltip: loc.addContact,
      style: IconButton.styleFrom(
        backgroundColor: _isInputValid
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        foregroundColor: _isInputValid
            ? colorScheme.onPrimary
            : colorScheme.onSurface.withOpacity(0.38),
        disabledBackgroundColor: colorScheme.surfaceContainerHighest,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        shape: const CircleBorder(),
      ),
      onPressed: _isInputValid ? () => _addContact(_controller.text) : null,
    );
  }

  Widget _buildTextField() {
    return TextField(
        style: TileTextStyles.inputTextStyle(colorScheme.onSurface),
        controller: _controller,
        focusNode: _focusNode,
        cursorColor: colorScheme.primary,
        cursorWidth: 2.0,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            hintStyle: TextStyle(
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: TileDimensions.inputFontSize,
                color: colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w100),
            hintText: AppLocalizations.of(context)!.addContact,
            border: InputBorder.none),
        onSubmitted: (value) {
          _addContact(value);
        },
        onEditingComplete: () {
          _addContact(_controller.text);
        },
        onTapOutside: (PointerDownEvent event) {
          FocusManager.instance.primaryFocus?.unfocus();
        });
  }

  Widget _buildPill(Contact contact) {
    return Chip(
      avatar: Icon(
        (contact.phoneNumber.isNot_NullEmptyOrWhiteSpace()
            ? Icons.messenger_outline
            : Icons.person_2_outlined),
        color: colorScheme.onPrimary,
      ),
      label: Text(contact.email ?? contact.phoneNumber ?? ""),
      deleteIcon: this.widget.isReadOnly
          ? null
          : Icon(Icons.close, color: colorScheme.onPrimary),
      side: BorderSide.none,
      onDeleted: this.widget.isReadOnly ? null : () => _removeContact(contact),
      backgroundColor: colorScheme.primary,
      labelStyle: TextStyle(color: colorScheme.onPrimary),
    );
  }
}
