import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

enum NotificationOverlayMessageType { success, error, info, warning }

class NotificationOverlayMessage {
  OverlayEntry? _overlayEntry;

  // Function to show the toast
  void showToast(
    BuildContext context,
    String message,
    NotificationOverlayMessageType messageType,
  ) {
    // Remove any existing overlay before showing a new one
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }

    _overlayEntry = _createOverlayEntry(context, message, messageType);
    Overlay.of(context)!.insert(_overlayEntry!);
  }

  // Function to create the overlay
  OverlayEntry _createOverlayEntry(
    BuildContext context,
    String message,
    NotificationOverlayMessageType messageType,
  ) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => _NotificationOverlayWidget(
        message: message,
        messageType: messageType,
        onDismiss: () {
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );

    return overlayEntry;
  }

  // Dispose method to clean up the overlay when needed
  void dispose() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
  }
}

class _NotificationOverlayWidget extends StatefulWidget {
  final String message;
  final NotificationOverlayMessageType messageType;
  final VoidCallback onDismiss;

  const _NotificationOverlayWidget({
    Key? key,
    required this.message,
    required this.messageType,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _NotificationOverlayWidgetState createState() =>
      _NotificationOverlayWidgetState();
}

class _NotificationOverlayWidgetState extends State<_NotificationOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500), // Duration of fade-out animation
      vsync: this,
    );

    // Define the opacity animation
    _opacityAnimation =
        Tween<double>(begin: 1.0, end: 0.0).animate(_animationController);

    // Start the fade-out animation after a delay
    Future.delayed(Duration(milliseconds: 2500), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    // Remove the overlay when the animation is complete
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Build method with FadeTransition
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    double calculateSizeByHeight(double value) {
      return height / (height / value);
    }

    return Positioned(
      bottom: calculateSizeByHeight(50),
      left: MediaQuery.of(context).size.width * 0.075,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: calculateSizeByHeight(10),
                horizontal: calculateSizeByHeight(20),
              ),
              decoration: BoxDecoration(
                color: _getNotificationColor(widget.messageType),
                border: Border.all(
                  color: _getNotificationBorderColor(widget.messageType),
                  width: height / (height / 1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: calculateSizeByHeight(20),
                    width: calculateSizeByHeight(20),
                    margin: EdgeInsets.only(right: calculateSizeByHeight(10)),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getNotificationBorderColor(widget.messageType),
                    ),
                    child: Center(
                      child: Icon(
                        _getNotificationIconData(widget.messageType),
                        size: calculateSizeByHeight(10),
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: calculateSizeByHeight(10)),
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color:
                              _getNotificationBorderColor(widget.messageType),
                          fontFamily: TileTextStyles.rubikFontName,
                        ),
                        softWrap: true,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(
                      Icons.close,
                      color: _getNotificationBorderColor(widget.messageType),
                      size: calculateSizeByHeight(20),
                    ),
                  ),
                ],
              ),
            )
            // child: Container(
            //   height: calculateSizeByHeight(58),
            //   padding: const EdgeInsets.symmetric(
            //     vertical: 10.0,
            //     horizontal: 20.0,
            //   ),
            //   decoration: BoxDecoration(
            //     color: _getNotificationColor(widget.messageType),
            //     border: Border.all(
            //       color: _getNotificationBorderColor(widget.messageType),
            //       width: height / (height / 1),
            //     ),
            //     borderRadius: BorderRadius.circular(12),
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     children: [
            //       Row(
            //         children: [
            //           Container(
            //             height: height / (height / 20),
            //             width: height / (height / 20),
            //             margin: EdgeInsets.only(right: height / (height / 10)),
            //             decoration: BoxDecoration(
            //               shape: BoxShape.circle,
            //               color: _getNotificationBorderColor(widget.messageType),
            //             ),
            //             child: Center(
            //               child: Icon(
            //                 _getNotificationIconData(widget.messageType),
            //                 size: height / (height / 10),
            //                 color: Colors.white,
            //               ),
            //             ),
            //           ),
            //           Text(
            //             widget.message,
            //             style: TextStyle(
            //                 color: _getNotificationBorderColor(widget.messageType),
            //                 fontFamily: TileStyles.rubikFontName),
            //             textAlign: TextAlign.center,
            //           ),
            //         ],
            //       ),
            //       GestureDetector(
            //         onTap: () {
            //           // Remove the overlay immediately when the close icon is tapped
            //           widget.onDismiss();
            //         },
            //         child: Icon(
            //           Icons.close,
            //           color: _getNotificationBorderColor(widget.messageType),
            //           size: calculateSizeByHeight(20),
            //         ),
            //       )
            //     ],
            //   ),
            // ),
            ),
      ),
    );
  }

  // Helper methods for colors and icons
  Color _getNotificationColor(NotificationOverlayMessageType type) {
    switch (type) {
      case NotificationOverlayMessageType.success:
        return Color(0xFFE6F9F0);
      case NotificationOverlayMessageType.warning:
        return Color(0xFFFFF8E1);
      case NotificationOverlayMessageType.error:
        return Color(0xFFFCE4EC);
      case NotificationOverlayMessageType.info:
        return Color(0xFFE1F5FE);
      default:
        return Colors.grey;
    }
  }

  Color _getNotificationBorderColor(NotificationOverlayMessageType type) {
    switch (type) {
      case NotificationOverlayMessageType.success:
        return Color(0xFF00C853);
      case NotificationOverlayMessageType.warning:
        return Color(0xFFFFA000);
      case NotificationOverlayMessageType.error:
        return Color(0xFFD32F2F);
      case NotificationOverlayMessageType.info:
        return Color(0xFF0288D1);
      default:
        return Colors.black;
    }
  }

  IconData _getNotificationIconData(NotificationOverlayMessageType type) {
    switch (type) {
      case NotificationOverlayMessageType.success:
        return Icons.check;
      case NotificationOverlayMessageType.error:
        return Icons.dangerous;
      case NotificationOverlayMessageType.warning:
        return Icons.warning;
      case NotificationOverlayMessageType.info:
        return FontAwesomeIcons.info;
      default:
        return FontAwesomeIcons.question;
    }
  }
}
