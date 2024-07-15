import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import '../../../bloc/forecast/forecast_bloc.dart';
import '../../../styles.dart';

class CompletedTiles extends StatelessWidget {
  const CompletedTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForecastBloc(),
      child: ForecastView(),
    );
  }
}

class ForecastView extends StatelessWidget {
  const ForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return CancelAndProceedTemplateWidget(
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          "Complete Tiles",
          style: TextStyle(
              color: TileStyles.appBarTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      child: Container(),
    );
  }
}
