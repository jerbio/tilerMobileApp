import 'package:flutter/material.dart';
import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/routes/authenticatedUser/contactInputField.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UserListViewWidget extends StatefulWidget {
  final List<Contact>? contacts;
  final Function? onContactListUpdate;
  final double? contentHeight;
  UserListViewWidget(
      {this.contacts, this.onContactListUpdate, this.contentHeight});
  @override
  State<StatefulWidget> createState() => _UserListViewState();
}

class _UserListViewState extends State<UserListViewWidget> {
  final int maxContactItems = 5;
  List<Contact> contacts = [];
  @override
  void initState() {
    super.initState();
    contacts = this.widget.contacts ?? [];
  }

  Widget generateContactCircle(Contact contact) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: CircleAvatar(
        child: Text(
          contact.displayedIdentifier?.capitalize()[0] ?? "",
          style: TileStyles.defaultTextStyle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var viableContacts = contacts
        .where((element) =>
            element.displayedIdentifier.isNot_NullEmptyOrWhiteSpace())
        .map((e) => generateContactCircle(e));
    return Row(
      // shrinkWrap: true,
      // mainAxisAlignment: ,
      children: [
        ...viableContacts.take(maxContactItems),
        if (viableContacts.length > maxContactItems)
          Text(
            AppLocalizations.of(context)!.numberOfMoreUsers(
                (viableContacts.length - maxContactItems).toString()),
            style: TileStyles.defaultTextStyle,
          )
        else
          SizedBox.shrink()
      ],
    );
  }
}
