import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  late List<Contact> _contacts = [];
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  @override
  void initState() {
    super.initState();
    if (this.widget.contacts != null) {
      this._contacts = this.widget.contacts!;
    }
  }

  @override
  void didChangeDependencies() {
    theme=Theme.of(context);
    colorScheme=theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidContact(String input) {
    // Simple email and phone number validation
    return Utility.isEmail(input) || Utility.isPhoneNumber(input);
  }

  void _addContact(String contactVal) {
    if (contactVal.isEmpty) {
      return;
    }
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
      });
      _controller
          .clear(); // Clear the text input field after adding the contact
    }
    if (this.widget.onContactUpdate != null &&
        !priorContact.any((eachContact) =>
            eachContact.email == contactVal ||
            eachContact.phoneNumber == contactVal)) {
      this.widget.onContactUpdate!(_contacts);
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            height: this.widget.contentHeight,
            child: ListView(
              shrinkWrap: true,
              reverse: true,
              children: [
                Wrap(
                  spacing: 8.0,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  runSpacing: 8.0,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  children: [
                    ..._contacts.map((contact) => _buildPill(contact)).toList(),
                  ],
                ),
              ],
            ),
          ),
          if (!this.widget.isReadOnly) _buildTextField(),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      alignment: Alignment.center,
      width: (MediaQuery.of(context)
          .size
          .width), // You can adjust the width or make it responsive
      height: TileDimensions.inputHeight,
      child: TextField(
          style: TileTextStyles.inputTextStyle(colorScheme.onSurface),
          controller: _controller,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
              hintStyle: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: TileDimensions.inputFontSize,
                  color: colorScheme.onSurface,
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
          }),
    );
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
          : Icon(
              Icons.close,
              color: colorScheme.onPrimary
            ),
      side: BorderSide.none,
      onDeleted: this.widget.isReadOnly ? null : () => _removeContact(contact),
      backgroundColor: colorScheme.primary,
      labelStyle: TextStyle(color: colorScheme.onPrimary),
    );
  }
}
