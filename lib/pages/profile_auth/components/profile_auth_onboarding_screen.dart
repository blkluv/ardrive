import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/misc/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'profile_auth_shell.dart';

class ProfileAuthOnboarding extends StatefulWidget {
  @override
  _ProfileAuthOnboardingState createState() => _ProfileAuthOnboardingState();
}

class _ProfileAuthOnboardingState extends State<ProfileAuthOnboarding> {
  final int onboardingPageCount = 4;
  int _onboardingStepIndex = 0;

  @override
  Widget build(BuildContext context) {
    switch (_onboardingStepIndex) {
      case 0:
        return ProfileAuthShell(
          illustration: _buildIllustrationSection(
            Image.asset(
              R.images.profile.newUserPermanent,
              fit: BoxFit.contain,
            ),
          ),
          contentWidthFactor: 0.75,
          content: DefaultTextStyle(
            style: Theme.of(context).textTheme.headline6!,
            textAlign: TextAlign.center,
            child: Builder(
              builder: (context) => Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.welcomeToThePermaweb,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!
                      .ardriveIsntJustAnotherCloudSyncApp),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.anyFilesWillOutliveYou),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.weDoAFewThingsDifferently),
                ],
              ),
            ),
          ),
          contentFooter: _buildOnboardingStepFooter(),
        );
      case 1:
        return ProfileAuthShell(
          illustration: _buildIllustrationSection(
            Image.asset(
              R.images.profile.newUserPayment,
              fit: BoxFit.contain,
            ),
          ),
          contentWidthFactor: 0.75,
          content: DefaultTextStyle(
            style: Theme.of(context).textTheme.headline6!,
            textAlign: TextAlign.center,
            child: Builder(
              builder: (context) => Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.payPerFile,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.noSubscriptions),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.monthlyCharges),
                ],
              ),
            ),
          ),
          contentFooter: _buildOnboardingStepFooter(),
        );
      case 2:
        return ProfileAuthShell(
          illustration: _buildIllustrationSection(
            Image.asset(
              R.images.profile.newUserUpload,
              fit: BoxFit.contain,
            ),
          ),
          contentWidthFactor: 0.75,
          content: DefaultTextStyle(
            style: Theme.of(context).textTheme.headline6!,
            textAlign: TextAlign.center,
            child: Builder(
              builder: (context) => Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.secondsFromForever,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.decentralizedPermanent),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.greenCheckMark),
                ],
              ),
            ),
          ),
          contentFooter: _buildOnboardingStepFooter(),
        );
      case 3:
        return ProfileAuthShell(
          illustration: _buildIllustrationSection(
            Image.asset(
              R.images.profile.newUserPrivate,
              fit: BoxFit.contain,
            ),
          ),
          contentWidthFactor: 0.75,
          content: DefaultTextStyle(
            style: Theme.of(context).textTheme.headline6!,
            textAlign: TextAlign.center,
            child: Builder(
              builder: (context) => Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalPrivacyControl,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.yourChoice),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noOneWillSee),
                ],
              ),
            ),
          ),
          contentFooter: _buildOnboardingStepFooter(),
        );
      case 4:
        return ProfileAuthShell(
          illustration: _buildIllustrationSection(
            Image.asset(
              R.images.profile.newUserDelete,
              fit: BoxFit.contain,
            ),
          ),
          contentWidthFactor: 0.75,
          content: DefaultTextStyle(
            style: Theme.of(context).textTheme.headline6!,
            textAlign: TextAlign.center,
            child: Builder(
              builder: (context) => Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.neverDeleted,
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const SizedBox(height: 32),
                  Text(AppLocalizations.of(context)!.noDeleteButton),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.onceUploadedCantBeRemoved),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.thinkTwiceBeforeUploading),
                ],
              ),
            ),
          ),
          contentFooter: _buildOnboardingStepFooter(),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildIllustrationSection(Widget illustration) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration,
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 256, minHeight: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i <= onboardingPageCount; i++)
                  if (_onboardingStepIndex == i)
                    AnimatedContainer(
                      height: 16,
                      width: 16,
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    )
                  else
                    AnimatedContainer(
                      height: 8,
                      width: 8,
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    ),
              ],
            ),
          )
        ],
      );

  Widget _buildOnboardingStepFooter() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.chevron_left),
            label: Text('BACK'),
            onPressed: () {
              if (_onboardingStepIndex > 0) {
                setState(() => _onboardingStepIndex--);
              } else {
                context.read<ProfileAddCubit>().promptForWallet();
              }
            },
          ),
          TextButton(
            onPressed: () {
              if (_onboardingStepIndex < onboardingPageCount) {
                setState(() => _onboardingStepIndex++);
              } else {
                context.read<ProfileAddCubit>().completeOnboarding();
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('NEXT'),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
          )
        ],
      );
}
