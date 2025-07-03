import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

//ey: not used
class ConfirmationDialog extends StatelessWidget {
  ConfirmationDialog(
      {super.key,
      required this.height,
      required this.textContent,
      required this.popEvent,
      required this.proceedEvent});

  double height;
  VoidCallback popEvent;
  VoidCallback proceedEvent;
  String textContent;

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(height / (height / 30))),
      child: Container(
        height: height / (height / 207),
        width: height / (height / 412),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(height / (height / 30)),
          border: Border.all(
            color: Colors.black,
            width: height / height,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: constraints.maxWidth * 0.6,
                child: Text(
                  textContent,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    color: Colors.white,
                    fontSize: height / (height / 14),
                  ),
                ),
              ),
              SizedBox(
                height: height / (height / 20),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: proceedEvent,
                    child: Container(
                      width: height / (height / 92),
                      height: height / (height / 23),
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9A6).withOpacity(0.65),
                        borderRadius:
                            BorderRadius.circular(height / (height / 30)),
                      ),
                      child: Center(
                        child: Text(
                          'Yes',
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: height / (height / 14),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: height / (height / 15),
                  ),
                  GestureDetector(
                    onTap: popEvent,
                    child: Container(
                      width: height / (height / 92),
                      height: height / (height / 23),
                      decoration: BoxDecoration(
                        color: Color(0xFFD9D9D9A6).withOpacity(0.65),
                        borderRadius:
                            BorderRadius.circular(height / (height / 30)),
                      ),
                      child: Center(
                        child: Text(
                          'No',
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: height / (height / 14),
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
