import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../core/model/enum.dart';
import '../core/state/selected_sport_state.dart';

/// First-run onboarding shown once after login when no context sport is chosen.
/// Walks through the four tabs, then requires the user to pick a context sport
/// (the app is scoped to one sport at a time) before it can be dismissed.
///
/// Presented as a barrier-locked full-screen route by [showOnboarding] so it
/// can't be swiped away without choosing a sport.
Future<void> showOnboarding(BuildContext context) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const _OnboardingScreen(),
    ),
  );
}

class _Feature {
  final IconData icon;
  final String titleKey;
  final String bodyKey;
  const _Feature(this.icon, this.titleKey, this.bodyKey);
}

const _features = [
  _Feature(FLucideIcons.compass, 'onboarding.home.title', 'onboarding.home.body'),
  _Feature(FLucideIcons.users, 'onboarding.manage.title', 'onboarding.manage.body'),
  _Feature(FLucideIcons.heartPulse, 'onboarding.health.title', 'onboarding.health.body'),
  _Feature(FLucideIcons.user, 'onboarding.profile.title', 'onboarding.profile.body'),
];

class _OnboardingScreen extends HookConsumerWidget {
  const _OnboardingScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final colors = context.theme.colors;

    // Last page (index == _features.length) is the sport picker.
    final sportPageIndex = _features.length;
    final onSportPage = currentPage.value == sportPageIndex;

    void finish(Sport sport) {
      ref.read(selectedSportStateProvider.notifier).change(sport);
      ref.read(othersAlertShownProvider.notifier).setShown();
      Navigator.of(context).pop();
    }

    return PopScope(
      canPop: false,
      child: FScaffold(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: pageController,
                onPageChanged: (i) => currentPage.value = i,
                children: [
                  for (final f in _features)
                    _FeaturePage(
                      icon: f.icon,
                      title: f.titleKey.tr(),
                      body: f.bodyKey.tr(),
                    ),
                  _SportPickPage(onPick: finish),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: pageController,
                      count: _features.length + 1,
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: colors.primary,
                        dotColor: colors.border,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!onSportPage)
                      FButton(
                        onPress: () => pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        child: Text('onboarding.next'.tr()),
                      )
                    else
                      Text(
                        'onboarding.pickSportHint'.tr(),
                        style: context.theme.typography.body.sm
                            .copyWith(color: colors.mutedForeground),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: colors.secondary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 44, color: colors.primary),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: context.theme.typography.body.xl2
                .copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: context.theme.typography.body.md
                .copyWith(color: colors.mutedForeground, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SportPickPage extends StatelessWidget {
  final void Function(Sport) onPick;

  const _SportPickPage({required this.onPick});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final sports =
        Sport.values.where((s) => s != Sport.others).toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'onboarding.sport.title'.tr(),
            style: context.theme.typography.body.xl2
                .copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'onboarding.sport.body'.tr(),
            style: context.theme.typography.body.md
                .copyWith(color: colors.mutedForeground, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (final sport in sports)
                FButton(
                  variant: .outline,
                  prefix: sport.getIcon(size: 18),
                  onPress: () => onPick(sport),
                  child: Text(sport.getLocalizedName(context)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
