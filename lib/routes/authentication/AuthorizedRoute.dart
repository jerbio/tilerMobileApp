import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/components/status.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';

enum ActivePage { tilelist, search, addTile, procrastinate, review }

class AuthorizedRoute extends StatefulWidget {
  @override
  AuthorizedRouteState createState() => AuthorizedRouteState();
}

class AuthorizedRouteState extends State<StatefulWidget> {
  final SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  final ScheduleApi scheduleApi = new ScheduleApi();
  ActivePage selecedBottomMenu = ActivePage.tilelist;

  void _onBottomNavigationTap(int index) {
    ActivePage selectedPage = ActivePage.tilelist;
    switch (index) {
      case 0:
        {
          Navigator.pushNamed(context, '/SearchTile');
        }
        break;
      case 1:
        {
          Navigator.pushNamed(context, '/AddTile');
        }
        break;
      case 2:
        {
          selectedPage = ActivePage.review;
        }
        break;
    }
  }

  void disableSearch() {
    this.setState(() {
      selecedBottomMenu = ActivePage.tilelist;
    });
  }

  Widget generateSearchWidget() {
    var eventNameSearch = Scaffold(
      body: Container(
        child: EventNameSearchWidget(onInputCompletion: this.disableSearch),
      ),
    );

    return eventNameSearch;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // bool isSearchActive = selecedBottomMenu == 0;
    DayStatusWidget dayStatusWidget = DayStatusWidget();
    List<Widget> widgetChildren = [
      TileList(), //this is the deafault and we need to switch these to routes and so we dont loose back button support
      // AddTile(),
    ];
    dayStatusWidget.onDayStatusChange(DateTime.now());

    Widget? bottomNavigator;
    if (selecedBottomMenu == ActivePage.search) {
      bottomNavigator = null;
      var eventNameSearch = this.generateSearchWidget();
      widgetChildren.add(eventNameSearch);
    } else {
      bottomNavigator = ClipRRect(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          topLeft: Radius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(
              color: Color.fromRGBO(250, 254, 255, 1),
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.topRight,
                  colors: [
                    Color.fromRGBO(0, 119, 170, 0.75),
                    Color.fromRGBO(0, 194, 237, 0.75)
                  ])),
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.search, color: Colors.white),
                label: '',
              ),
              BottomNavigationBarItem(
                  icon: Icon(
                    Icons.add,
                    color: Color.fromRGBO(0, 0, 0, 0),
                  ),
                  label: ''),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today_outlined), label: ''),
            ],
            unselectedItemColor: Colors.white,
            selectedItemColor: Colors.black,
            backgroundColor: Colors.transparent,
            elevation: 0,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: _onBottomNavigationTap,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color.fromRGBO(250, 254, 255, 1),
      body: Stack(
        children: widgetChildren,
      ),
      bottomNavigationBar: bottomNavigator,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromRGBO(243, 243, 243, 1),
        onPressed: () {
          showGeneralDialog(
            barrierDismissible: true,
            barrierLabel: '',
            barrierColor: Colors.white70,
            transitionDuration: Duration(milliseconds: 300),
            pageBuilder: (ctx, anim1, anim2) => AlertDialog(
              contentPadding: EdgeInsets.fromLTRB(1, 1, 1, 1),
              insetPadding: EdgeInsets.fromLTRB(0, 250, 0, 0),
              titlePadding: EdgeInsets.fromLTRB(5, 5, 5, 5),
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.white),
                borderRadius: BorderRadius.all(
                  Radius.circular(20),
                ),
              ),
              content: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2),
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.topRight,
                    colors: [
                      Color.fromRGBO(0, 119, 170, 0.75),
                      Color.fromRGBO(0, 194, 237, 0.75)
                    ],
                  ),
                ),
                child: SizedBox(
                  height: size.height * 0.3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).pushNamed('/ForecastPreview');
                        },
                        child: ListTile(
                          leading: Image.asset('assets/images/binocular.png'),
                          title: Text(
                            AppLocalizations.of(context)!.forecast,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/AddTile');
                        },
                        child: ListTile(
                          leading: Icon(
                            Icons.add,
                            color: Colors.white,
                          ),
                          title: Text(
                            AppLocalizations.of(context)!.addTile,
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: Colors.white),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: Image.asset('assets/images/move_forward.png'),
                        title: Text(
                          AppLocalizations.of(context)!.procrastinate,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              elevation: 2,
            ),
            transitionBuilder: (ctx, anim1, anim2, child) => BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: 4 * anim1.value, sigmaY: 4 * anim1.value),
              child: FadeTransition(
                child: child,
                opacity: anim1,
              ),
            ),
            context: context,
          );
        },
        child: Icon(
          Icons.add,
          size: 35,
          color: Color.fromRGBO(0, 194, 237, 1),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
