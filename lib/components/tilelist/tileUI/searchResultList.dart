import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchResultList extends StatefulWidget {
  List<Widget> children;
  SearchResultList({children, Key key}) : super(key: key);
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
