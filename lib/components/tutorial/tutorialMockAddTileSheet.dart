import 'package:flutter/material.dart';

/// A non-functional mock of the add-tile bottom sheet used during the tutorial.
/// Visually mirrors `PreviewAddWidget.renderModal()` so users can see the UI
/// being described, but all buttons and inputs are inert.
class TutorialMockAddTileSheet extends StatelessWidget {
  const TutorialMockAddTileSheet({Key? key}) : super(key: key);

  static const double sheetHeight = 340;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
    );

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: EdgeInsets.only(top: 8, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Action buttons row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _mockActionButton(
                  icon:
                      Icon(Icons.refresh, color: colorScheme.primary, size: 20),
                  label: 'Revise',
                  colorScheme: colorScheme,
                ),
                _mockActionButton(
                  icon:
                      Icon(Icons.shuffle, color: colorScheme.primary, size: 20),
                  label: 'Shuffle',
                  colorScheme: colorScheme,
                ),
                _mockActionButton(
                  icon: _buildTripleChevron(colorScheme),
                  label: 'Defer All',
                  colorScheme: colorScheme,
                ),
                _mockActionButton(
                  icon: Icon(Icons.more_time,
                      color: colorScheme.primary, size: 20),
                  label: 'Options',
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 0.5),

          // Name input
          Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'What do you need to do?',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.edit_outlined,
                    color: colorScheme.primary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Duration input
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Duration (e.g., 30 min)',
                hintStyle: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(Icons.timer_outlined,
                    color: colorScheme.primary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outline),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Submit button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: null, // Disabled — demo only
                icon: Icon(Icons.add, size: 20),
                label: Text('Add Tile',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor:
                      colorScheme.primary.withValues(alpha: 0.7),
                  disabledForegroundColor:
                      colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockActionButton({
    required Widget icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 9, color: colorScheme.primary),
        ),
      ],
    );
  }

  Widget _buildTripleChevron(ColorScheme colorScheme) {
    return SizedBox(
      width: 30,
      height: 20,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child:
                Icon(Icons.chevron_right, color: colorScheme.primary, size: 16),
          ),
          Positioned(
            left: 7,
            top: 0,
            bottom: 0,
            child:
                Icon(Icons.chevron_right, color: colorScheme.primary, size: 16),
          ),
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child:
                Icon(Icons.chevron_right, color: colorScheme.primary, size: 16),
          ),
        ],
      ),
    );
  }
}
