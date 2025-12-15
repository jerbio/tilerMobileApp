import 'package:flutter/material.dart';
import 'package:tiler_app/components/vibeChat/VibeActionTile.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';

class VibeChat extends StatelessWidget {
  const VibeChat({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight=MediaQuery.of(context).size.height;
    final screenWidth=MediaQuery.of(context).size.width;
    return Container(
      height: screenHeight * 0.5,
      width: screenWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: screenWidth *0.3,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildMessage('Hi! Can you help me?', true,screenWidth),
                _buildMessage('Of course! How can I help you?', false,screenWidth),
                _buildMessage('I need to schedule deep work sessions', true,screenWidth),
                _buildMessage('I\'ll look into your schedule', false,screenWidth),
                _buildMessage('That would be great!', true,screenWidth),
                _buildMessage('I found these slots:\nMonday 1-3 PM\nTuesday 9:30-12 PM\nFriday 10-11 AM ', false,screenWidth),
                _buildMessage('Perfect! Create them please', true,screenWidth),
                _buildMessage('Perfect! Create them please Perfect! Create them please Perfect! Create them please Perfect! Create them please Perfect! Create them pleasePerfect! Create them pleasev  Perfect! Create them please Perfect! Create them please Perfect! Create them please Perfect! Create them please Perfect! Create them please ', false,screenWidth),
                _buildMessage('Creating tiles now...', false,screenWidth),
                _buildMessage('Yes please!', true,screenWidth),
                _buildMessage('Done! Your tiles are ready', false,screenWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
      {VibeAction? action, required ColorScheme colorScheme}){
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.all(5),
        padding: EdgeInsets.all(5),
        constraints: BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.red, // border color
            width: 2,          // border width
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              color: colorScheme.primary,
              size: 12,
            ),
            Flexible(
              child: Text(
                  action!.descriptions!,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(String text, bool isUser,double width ) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Builder(
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              constraints: BoxConstraints(maxWidth:width *0.65),
              decoration: BoxDecoration(
                color: isUser ? colorScheme.surfaceContainerHighest : colorScheme.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isUser ? 16 : 4),
                  topRight: Radius.circular(isUser ? 4 : 16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? colorScheme.onSurface : colorScheme.onPrimary,
                ),
              ),
            );
          }
      ),
    );
  }
}
