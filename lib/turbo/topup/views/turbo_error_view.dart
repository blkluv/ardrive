import 'package:ardrive/turbo/topup/blocs/turbo_topup_flow_bloc.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:ardrive_ui/ardrive_ui.dart';
import 'package:flutter/material.dart';

class TurboErrorView extends StatelessWidget {
  const TurboErrorView({
    super.key,
    required this.errorType,
    required this.onTryAgain,
    required this.onDismiss,
  });

  final TurboErrorType errorType;
  final Function onTryAgain;
  final Function onDismiss;

  String _getErrorMessageForErrorType(BuildContext context) {
    switch (errorType) {
      case TurboErrorType.sessionExpired:
        return appLocalizationsOf(context).turboErrorMessageSessionExpired;
      case TurboErrorType.unknown:
        return appLocalizationsOf(context).turboErrorMessageUnknown;
      case TurboErrorType.server:
        return appLocalizationsOf(context).turboErrorMessageServer;
      case TurboErrorType.fetchPaymentIntentFailed:
        return appLocalizationsOf(context)
            .turboErrorMessageEstimationInformationFailed;
      case TurboErrorType.fetchEstimationInformationFailed:
        return appLocalizationsOf(context)
            .turboErrorMessageEstimationInformationFailed;
      case TurboErrorType.network:
        return appLocalizationsOf(context).turboErrorMessageNetwork;
      default:
        return appLocalizationsOf(context).turboErrorMessageUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ArDriveCard(
      height: 513,
      contentPadding: EdgeInsets.zero,
      content: Column(
        children: [
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 26, right: 26),
                child: ArDriveClickArea(
                  child: GestureDetector(
                      onTap: () {
                        onDismiss();
                        Navigator.pop(context);
                      },
                      child: ArDriveIcons.x()),
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Column(
              children: [
                ArDriveIcons.triangle(
                  size: 50,
                  color: ArDriveTheme.of(context)
                      .themeData
                      .colors
                      .themeErrorDefault,
                ),
                Text(appLocalizationsOf(context).theresBeenAProblem,
                    style: ArDriveTypography.body.leadBold()),
                const SizedBox(height: 16),
                Text(
                  _getErrorMessageForErrorType(context),
                  style: ArDriveTypography.body.buttonNormalRegular(
                    color: ArDriveTheme.of(context)
                        .themeData
                        .colors
                        .themeFgDefault,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: ArDriveButton(
                maxHeight: 44,
                maxWidth: 143,
                text: appLocalizationsOf(context).tryAgain,
                fontStyle: ArDriveTypography.body.buttonLargeBold(
                  color: Colors.white,
                ),
                onPressed: () {
                  onTryAgain();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
