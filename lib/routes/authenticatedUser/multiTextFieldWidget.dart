import 'package:flutter/material.dart';

//ey: not used
class MultiTextFieldWidget extends StatefulWidget {
  final Function? onDoneTyping;
  final Function? onTextChange;
  final String? value;
  MultiTextFieldWidget({this.value, this.onDoneTyping, this.onTextChange});
  @override
  _MultiTextFieldState createState() => _MultiTextFieldState();
}

class _MultiTextFieldState extends State<MultiTextFieldWidget> {
  TextEditingController noteFieldController = TextEditingController();
  FocusNode notesFieldFocusNode = FocusNode();
  bool hasTextChanged = false;
  String? noteResult = null;
  String? focusText = null;
  @override
  void initState() {
    super.initState();
    this.noteResult = this.widget.value;
    noteFieldController.value = TextEditingValue(text: noteResult ?? "");
  }

  void onNoteFieldChange() {
    if (noteFieldController.text != noteResult) {
      setState(() {
        noteResult = noteFieldController.text;
        hasTextChanged = true;
      });
    }
  }

  void onNoteFieldOutOfFocus() {
    String? priorFocusText = focusText;
    focusText = this.noteFieldController.text;
    if (!notesFieldFocusNode.hasFocus) {
      if (hasTextChanged && priorFocusText != focusText) {
        hasTextChanged = false;
        if (this.widget.onDoneTyping != null) {
          this.widget.onDoneTyping!(focusText);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
