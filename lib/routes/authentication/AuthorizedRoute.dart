import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/status.dart';
import 'package:tiler_app/components/tileUI/eventNameSearch.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/routes/authentication/register.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tiler_app/util.dart';

class AuthorizedRoute extends StatefulWidget {
  @override
  AuthorizedRouteState createState() => AuthorizedRouteState();
}

class AuthorizedRouteState extends State<StatefulWidget> {
  final SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  final ScheduleApi scheduleApi = new ScheduleApi();
  int selecedBottomMenu = -1;

  void _onBottomNavigationTap(int index) {
    selecedBottomMenu = index;
    this.setState(() {
      selecedBottomMenu = index;
    });
  }

  void disableSearch() {
    this.setState(() {
      selecedBottomMenu = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isSearchActive = selecedBottomMenu == 0;
    DayStatusWidget dayStatusWidget = DayStatusWidget();
    List<Widget> widgetChildren = [
      TileList(),
      ElevatedButton(
        child: Text('Log Out'),
        onPressed: () async {
          Authentication authentication = new Authentication();
          await authentication.deleteCredentials();
          while (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegistrationRoute()),
          );
        },
      ),
      dayStatusWidget,
    ];
    dayStatusWidget.onDayStatusChange(DateTime.now());

    Widget? bottomNavigator;
    if (isSearchActive) {
      bottomNavigator = null;
      var eventNameSearch = Scaffold(
        body: Container(
          child: EventNameSearchWidget(onInputCompletion: this.disableSearch),
        ),
      );
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
              BottomNavigationBarItem(icon: Icon(Icons.usb), label: ''),
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
        bottomNavigationBar: bottomNavigator);
  }
}
