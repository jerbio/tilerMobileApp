import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';

class ContactListView extends StatefulWidget {
  final List<Contact>? contacts;
  final Function? onContactListUpdate;
  final bool isReadOnly;
  final double? contentHeight;
  ContactListView(
      {this.contacts,
      this.onContactListUpdate,
      this.isReadOnly = false,
      this.contentHeight});
  @override
  State<StatefulWidget> createState() => _ContactListViewState();
}

class _ContactListViewState extends State<ContactListView> {
  List<Contact> contacts = [];
  @override
  void initState() {
    super.initState();
    contacts = this.widget.contacts ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        ContactInputFieldWidget(
          contacts: contacts,
          // contentHeight: this.widget.contentHeight ??
          //     (contacts.isEmpty
          //         ? 0
          //         : contacts.length < 3
          //             ? 50
          //             : 100),
          onContactUpdate: (List<Contact> updatedContacts) {
            setState(() {
              this.contacts = updatedContacts;
            });
            if (this.widget.onContactListUpdate != null) {
              this.widget.onContactListUpdate!(updatedContacts);
            }
          },
        )
      ],
    );
  }
}
