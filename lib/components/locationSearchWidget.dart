import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';

class LocationSearchWidget extends SearchWidget {
  LocationSearchWidget(
      {onChanged,
      textField,
      onInputCompletion,
      listView,
      renderBelowTextfield = true,
      Key? key})
      : super(
            onChanged: onChanged,
            textField: textField,
            onInputCompletion: onInputCompletion,
            renderBelowTextfield: renderBelowTextfield,
            key: key);

  @override
  LocationSearchState createState() => LocationSearchState();
}

class LocationSearchState extends SearchWidgetState {}
