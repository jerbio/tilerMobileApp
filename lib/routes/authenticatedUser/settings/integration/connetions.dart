import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/integrationWidgetRoute.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'bloc/integrations_bloc.dart';

class Connections extends StatelessWidget {
  static const String routeName = '/Connections';

  const Connections({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      routeName: routeName,
      appBar: TileStyles.CancelAndProceedAppBar(
          AppLocalizations.of(context)!.connections),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/google.svg',
            title: AppLocalizations.of(context)!.googleCalendar,
            context: context,
            onTap: () =>
                _navigateToIntegration(context, IntegrationType.googleCalendar),
          ),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/microsoft.svg',
            title: AppLocalizations.of(context)!.microsoft,
            context: context,
            isComingSoon: true,
          ),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/apple.svg',
            title: AppLocalizations.of(context)!.appleCalendar,
            context: context,
            isComingSoon: true,
          ),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/googleTasks.svg',
            title: AppLocalizations.of(context)!.googleTasks,
            context: context,
            isComingSoon: true,
          ),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/slack.svg',
            title: AppLocalizations.of(context)!.slack,
            context: context,
            isComingSoon: true,
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationRow({
    required String iconPath,
    required String title,
    required BuildContext context,
    bool isComingSoon = false,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: _buildAddButton(onTap, !isComingSoon, context),
      contentPadding: EdgeInsets.symmetric(horizontal: 30),
    );
  }

  Widget _buildAddButton(
      VoidCallback? onTap, bool isImplemented, BuildContext context) {
    ButtonStyle _addStyle = TextButton.styleFrom(
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: TileStyles.primaryColor),
      ),
    );

    ButtonStyle _comingSoonStyle = TextButton.styleFrom(
      backgroundColor: const Color(0xFFEEEEEE),
      foregroundColor: const Color(0xFF999999),
      padding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: 150),
      child: TextButton(
        style: isImplemented ? _addStyle : _comingSoonStyle,
        onPressed: isImplemented ? onTap : null,
        child: Text(isImplemented
            ? AppLocalizations.of(context)!.integrationConfigure
            : AppLocalizations.of(context)!.comingSoon),
      ),
    );
  }

  void _navigateToIntegration(BuildContext context, IntegrationType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => IntegrationsBloc(
            getContextCallBack: () => context,
            integrationType: type,
          ),
          child: IntegrationWidgetRoute(),
        ),
      ),
    );
  }
}
