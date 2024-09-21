import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ContactInputField extends StatefulWidget {
  final Function? onContactUpdate;
  ContactInputField({this.onContactUpdate});
  @override
  _ContactInputFieldState createState() => _ContactInputFieldState();
}

class _ContactInputFieldState extends State<ContactInputField> {
  final emailRegex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  final phoneRegex = RegExp(r"^\+?[0-9]{7,15}$");
  final TextEditingController _controller = TextEditingController();
  final List<Contact> _contacts = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidContact(String input) {
    // Simple email and phone number validation

    return emailRegex.hasMatch(input) || phoneRegex.hasMatch(input);
  }

  void _addContact(String contactVal) {
    if (_isValidContact(contactVal)) {
      setState(() {
        final contactObj = Contact();
        if (emailRegex.hasMatch(contactVal)) {
          contactObj.email = contactVal;
        }
        if (phoneRegex.hasMatch(contactVal)) {
          contactObj.phoneNumber = contactVal;
        }
        _contacts.add(contactObj);
      });
      _controller
          .clear(); // Clear the text input field after adding the contact
    }
    if (this.widget.onContactUpdate != null) {
      this.widget.onContactUpdate!(_contacts);
    }
  }

  void _removeContact(Contact contact) {
    setState(() {
      _contacts.remove(contact);
    });
    if (this.widget.onContactUpdate != null) {
      this.widget.onContactUpdate!(_contacts);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildTextField(),
              ..._contacts.map((contact) => _buildPill(contact)).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return Container(
      width: 150, // You can adjust the width or make it responsive
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: AppLocalizations.of(context)!.addContact,
        ),
        onSubmitted: (value) {
          _addContact(value);
        },
        onEditingComplete: () {
          _addContact(_controller.text);
        },
      ),
    );
  }

  Widget _buildPill(Contact contact) {
    return Chip(
      label: Text(contact.email ?? contact.phoneNumber ?? ""),
      deleteIcon: Icon(Icons.close),
      onDeleted: () => _removeContact(contact),
      backgroundColor: Colors.blueAccent.shade100,
      labelStyle: TextStyle(color: Colors.white),
    );
  }
}
