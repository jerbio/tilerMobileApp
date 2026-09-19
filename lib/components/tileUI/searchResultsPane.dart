// The search results pane: a PINNED header (result count + provider filter
// chips) above the scrolling results (2026-09-19).
//
// The header used to be the first item inside the results ListView, so a few
// rows in the filters were gone and switching provider meant scrolling back
// to the top. Here the list scrolls under a header that never moves.
//
// The tap-to-dismiss the list has always had stays: a tap on empty space —
// below a short list, or on the header's padding — hides the results, while
// a tap on a result card is claimed by the card (SearchResultTapTarget).
import 'package:flutter/material.dart';

class SearchResultsPane extends StatelessWidget {
  const SearchResultsPane({
    super.key,
    required this.header,
    required this.results,
    required this.onDismiss,
    this.decoration,
  });

  /// Pinned above the list.
  final Widget header;

  /// The scrolling rows: cards, banners, empty/error messages.
  final List<Widget> results;

  /// Hides the results; a tap anywhere no child claims.
  final VoidCallback onDismiss;
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      child: Container(
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Expanded(
              // A tap on the list's empty space is not claimed by the
              // Scrollable (it only recognises drags), so it reaches the
              // pane's dismisser above.
              child: ListView(children: results),
            ),
          ],
        ),
      ),
    );
  }
}
