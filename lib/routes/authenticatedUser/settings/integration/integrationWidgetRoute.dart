import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationRoute.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IntegrationWidgetRoute extends StatelessWidget {
  static final String routeName = '/Integrations';
  Widget renderPending() {
    List<Widget> centerElements = [
      Center(
          child: SizedBox(
            child: CircularProgressIndicator(),
            height: 200.0,
            width: 200.0,
          )),
      Center(
          child: Image.asset('assets/images/tiler_logo_black.png',
              fit: BoxFit.cover, scale: 7)),
    ];
    return Container(
      decoration: TileStyles.defaultBackground,
      child: Center(child: Stack(children: centerElements)),
    );
  }

  Widget renderAddNewIntegration(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: TileStyles.primaryColor,
        foregroundColor:TileStyles.primaryContrastTextColor,
      ),
      onPressed:()=> context.read<IntegrationsBloc>().add(AddIntegrationEvent()),
      // if(value !=null){
      //   Location defaultLocation = Location.fromDefault();
      //   Map<String, dynamic> locationParams = {
      //     'location': defaultLocation,
      //   };
      //   Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //           builder: (context) => LocationRoute(
      //             disableNickName: true,
      //             hideHomeButton: true,
      //             hideWorkButton: true,
      //             locationArgs: locationParams,
      //           )
      //       )
      //   ).whenComplete(() {
      //     Location? populatedLocation = locationParams['location'] as Location? ?? Location.fromDefault();
      //     AnalysticsSignal.send('INTEGRATION_GOOGLE_LOCATION_NAVIGATION');
      //     if (populatedLocation != null && value.containsKey('id')) {
      //       String integrationId = value['id'];
      //       integrationApi.addIntegrationLocation(populatedLocation, integrationId);
      //     }
      //   });
      // }
      // },
      child: Text(
        AppLocalizations.of(context)!.addGoogleCalendar,
        style: TextStyle(
            fontSize: 16
        ),
      ),
    );
  }

  Widget renderEmpty(BuildContext context) {
    return Container(
      child: Text(AppLocalizations.of(context)!.noThirdPartyIntegtions),
    );
  }

  Widget renderIntegrations(List<CalendarIntegration> integrations,BuildContext context) {
    if (integrations.isEmpty) {
      return renderEmpty(context);
    }
    List<CalendarIntegration> orderedIntegrations = integrations;
    return ListView.builder(
      itemCount: orderedIntegrations.length,
      itemBuilder: (context, index) {
        final integration = orderedIntegrations[index];
        return _IntegrationItem(integration: integration);
      },
    );
  }

  Widget generateContent(IntegrationsState state,BuildContext context) {
    if (state is IntegrationsInitial) {
      context.read<IntegrationsBloc>().add(GetIntegrationsEvent());
      return renderPending();
    }
    if (state is IntegrationsLoading) {
      return renderPending();
    }
    if (state is IntegrationsLoaded ) {
      if (state.integrations.isNotEmpty) {
        return renderIntegrations(state.integrations,context);
      }
    }
    if(state is IntegrationsError){
      if (state.integrations.isNotEmpty) {
        return renderIntegrations(state.integrations,context);
      }
    }
    return renderEmpty(context);
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            //imp3: does the reset needed? if yes move consumer up
            //context.read<IntegrationsBloc>().add(ResetIntegrationsEvent());
            Navigator.pop(context);
          },
        ),
        title: const Text('Google Calender'),
      ),
      body: BlocConsumer<IntegrationsBloc, IntegrationsState>(
        listener: (context, state) {
          NotificationOverlayMessage notificationOverlayMessage =
          NotificationOverlayMessage();
          if (state is IntegrationAdded) {
            //_handleNewIntegration(context, state.integrationId);
          } else if (state is IntegrationDeleted) {
            notificationOverlayMessage.showToast(
              context,
              AppLocalizations.of(context)!.deletedCalendar(state.integrationInfo),
              NotificationOverlayMessageType.success,
            );
          } else if (state is IntegrationsError) {
            notificationOverlayMessage.showToast(
              context,
              state.errorMessage,
              NotificationOverlayMessageType.error,
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child:  Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Center(
                    child: generateContent(state,context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(50.0),
                child: renderAddNewIntegration(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntegrationItem extends StatelessWidget {
  final CalendarIntegration integration;
  const _IntegrationItem({required this.integration,});

  String _getCityFromLocation(Location? location) {
    String _capitalize(String text) {
      if (text.isEmpty) return text;
      return text[0].toUpperCase() + text.substring(1);
    }
    String? _extractCity(String? text, {bool hi=false}) {
      if (text != null && text.isNotEmpty) {
        List<String> parts = text.split(',').map((e) => e.trim()).toList();
        if (parts.length == 1) {
          return _capitalize(parts.first);
        }
        return _capitalize(parts[parts.length - 2]);
      }
      return null;
    }
    return
      _extractCity(location?.address)??
          _extractCity(location?.description) ??
          "Set location";
  }

  void _updateLocation(BuildContext context,CalendarIntegration integration){
    Map<String, dynamic> locationParams = {
      'location': integration.location,
    };
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LocationRoute(
              disableNickName: true,
              hideHomeButton: true,
              hideWorkButton: true,
              locationArgs: locationParams,
            ),
        ),
    ).whenComplete(() {
      Location? populatedLocation = locationParams['location'] as Location? ?? Location.fromDefault();
      AnalysticsSignal.send('INTEGRATION_GOOGLE_LOCATION_NAVIGATION');
      if (populatedLocation != null) {
        if (integration.id != null) {
          integration.location = populatedLocation;
          context.read<IntegrationsBloc>().add(UpdateIntegrationLocationEvent(integrationId: integration.id!,location: populatedLocation));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String titleText = integration.email ?? integration.userId ?? integration.id ?? "";
    return ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 0),
        subtitle: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/settings/MyLocations.svg',
              width: 16,
              height: 16,
              color: Colors.grey,
            ),
            SizedBox(width: 4),
            GestureDetector(
              onTap: ()=>_updateLocation(context,integration),
              child:SizedBox(
                width: 150,
                child: Text(
                  _getCityFromLocation(integration.location),
                  style: TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        title: Container(
          child: Text(
            titleText,
            style: TextStyle(overflow: TextOverflow.ellipsis),
          ),
        ),
        trailing: IntrinsicWidth(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: TileStyles.primaryColor),
              ),
            ),
            onPressed: ()=> context.read<IntegrationsBloc>().add(DeleteIntegrationEvent(integration: integration)),
            child: Text("Disconnect"),
          ),
        )
    );

  }
}
