import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/integrationWidgetRoute.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

import 'bloc/integrations_bloc.dart';

class Connections extends StatelessWidget {
  static const String routeName = '/Connections';

  const Connections({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>();
    final  localization= AppLocalizations.of(context)!;
    return CancelAndProceedTemplateWidget(
      routeName: routeName,
      appBar:AppBar(
        title: Text(localization.connections),
        automaticallyImplyLeading: false,
      ),
      child: ListView(
        children: [
          const SizedBox(height: 16),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/google.svg',
            title: localization.googleCalendar,
            onTap: () =>
                _navigateToIntegration(context, IntegrationType.googleCalendar),
              colorScheme: colorScheme,
            tileThemeExtension: tileThemeExtension!,
            localization:  localization,
          ),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/microsoft.svg',
            title: localization.microsoft,
            isComingSoon: true,
            colorScheme: colorScheme,
            tileThemeExtension: tileThemeExtension!,
            localization:  localization,
          ),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/apple.svg',
            title: localization.appleCalendar,
            isComingSoon: true,
            colorScheme: colorScheme,
            tileThemeExtension: tileThemeExtension!,
            localization:  localization,
          ),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/googleTasks.svg',
            title: localization.googleTasks,
            isComingSoon: true,
            colorScheme: colorScheme,
            tileThemeExtension: tileThemeExtension!,
            localization:  localization,
          ),
          _buildIntegrationRow(
            iconPath: 'assets/icons/settings/slack.svg',
            title: localization.slack,
            isComingSoon: true,
            colorScheme: colorScheme,
            tileThemeExtension: tileThemeExtension!,
            localization:  localization,
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationRow({
    required String iconPath,
    required String title,
    required ColorScheme colorScheme,
    required TileThemeExtension tileThemeExtension,
    required AppLocalizations localization,
    bool isComingSoon = false,
    VoidCallback? onTap,


  }) {
    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(colorScheme.onSurface, BlendMode.srcIn),
      ),
      title: Text(
        title,
        style:  const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: _buildAddButton(onTap, !isComingSoon,colorScheme,tileThemeExtension,localization),
      contentPadding: EdgeInsets.symmetric(horizontal: 30),
    );
  }

  Widget _buildAddButton(VoidCallback? onTap, bool isImplemented,ColorScheme colorScheme,TileThemeExtension tileThemeExtension,AppLocalizations localization) {
    ButtonStyle _addStyle = TextButton.styleFrom(
      foregroundColor:colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.primary),
      ),
    );

    ButtonStyle _comingSoonStyle = TextButton.styleFrom(
      backgroundColor: tileThemeExtension.surfaceContainerDisabled,
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
        child: Text(isImplemented ?  localization.add :  localization.comingSoon),
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
