// Step 4.3d — Date and time selection.
//
// THE PLATFORM PICKERS STAY. `showDatePicker` and `showTimePicker` are kept
// rather than replaced with house-styled screens, and that is a deliberate
// decision rather than an omission (D42). They already deliver, on both
// platforms, everything a hand-built replacement would have to re-earn: full
// localization including non-Gregorian calendars, 12/24-hour selection from
// the locale, RTL layout, keyboard entry, screen-reader support, and large
// text. Re-implementing that surface would be a large accessibility and
// locale regression bought with visual consistency alone.
//
// WHAT THIS FILE IS FOR. The bugs in date and time selection do not live in
// the picker chrome; they live in how a picked value is COMBINED with the
// value already in the draft. Those rules are pure, and this is where they
// are stated and tested:
//
//   * picking a date must change only the calendar day, never the time;
//   * picking a time must change only the wall-clock time, never the day;
//   * a deadline is the END of the chosen day, not its start.
//
// Getting any of these wrong moves a value the user did not touch, which is
// exactly the class of defect the plan asks Step 4.3d to rule out.
//
// A NOTE ON DST. These functions build local `DateTime`s, so on a
// spring-forward day a wall-clock time that does not exist is normalized
// forward by Dart (02:30 becomes 03:30 where 02:00-03:00 is skipped). That is
// the correct and only sane behaviour for "the user asked for 2:30 on this
// day" — but it means the returned time is not always the time requested, and
// callers must read the result back rather than assume it. The Fixed Block's
// end row already re-derives from the draft, so it shows the normalized value.
//
// Plain date/time values only, no Add Tile state, so any flow can use them.
import 'package:flutter/material.dart';

/// The result of picking a DATE for a value that also carries a time.
///
/// The wall-clock time from [current] is carried onto the picked day, so
/// choosing a date never silently moves the block's time.
DateTime applyPickedDate(DateTime current, DateTime pickedDay) => DateTime(
      pickedDay.year,
      pickedDay.month,
      pickedDay.day,
      current.hour,
      current.minute,
    );

/// The result of picking a TIME for a value that also carries a date.
///
/// The calendar day from [current] is preserved.
DateTime applyPickedTime(DateTime current, TimeOfDay picked) => DateTime(
      current.year,
      current.month,
      current.day,
      picked.hour,
      picked.minute,
    );

/// The deadline for a chosen day: its final minute.
///
/// "Complete by Friday" means the end of Friday, not the start of it. The
/// legacy flow used 23:59 and the wire contract is unchanged.
DateTime deadlineForPickedDay(DateTime pickedDay) =>
    DateTime(pickedDay.year, pickedDay.month, pickedDay.day, 23, 59);

/// The selectable window around [anchor], matching the legacy +/-180 days.
///
/// Returned as a record so the two bounds cannot be swapped at a call site.
({DateTime first, DateTime last}) addTileDateWindow(DateTime anchor) => (
      first: anchor.subtract(const Duration(days: 180)),
      last: anchor.add(const Duration(days: 180)),
    );
