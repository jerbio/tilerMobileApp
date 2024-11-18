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
    return Container(
      child: ListView(
        shrinkWrap: true,
        children: [
          ContactInputFieldWidget(
            readOnly: this.widget.isReadOnly,
            contacts: contacts,
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
      ),
    );
  }
}
