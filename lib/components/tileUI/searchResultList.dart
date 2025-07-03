import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//ey: not used
class SearchResultList extends StatefulWidget {
  late List<Widget> children;
  SearchResultList({children, Key? key}) : super(key: key) {
    assert(children != null);
    this.children = children;
  }
  @override
  SearchResultListState createState() => SearchResultListState();
}

class SearchResultListState extends State<SearchResultList> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: this.widget.children,
    );
  }
}
