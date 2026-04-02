import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'auth_screen.dart';

class WelcomeScreen extends HookConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();
    final currentPage = useState(0);

    final introPages = [
      _IntroPage(
        icon: FIcons.users,
        title: 'welcome.page1.title'.tr(),
        description: 'welcome.page1.description'.tr(),
      ),
      _IntroPage(
        icon: FIcons.calendar,
        title: 'welcome.page2.title'.tr(),
        description: 'welcome.page2.description'.tr(),
      ),
      _IntroPage(
        icon: FIcons.trophy,
        title: 'welcome.page3.title'.tr(),
        description: 'welcome.page3.description'.tr(),
      ),
    ];

    final isLastIntroPage = currentPage.value == introPages.length - 1;
    final isAuthPage = currentPage.value == introPages.length;


    return FScaffold(
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: (index) => currentPage.value = index,
              children: [
                ...introPages,
                const AuthScreen(),
              ],
            ),
          ),
          if (!isAuthPage)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: pageController,
                      count: introPages.length + 1,
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: context.theme.colors.primary,
                        dotColor: context.theme.colors.border,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _IntroPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: context.theme.colors.primary,
          ),
          const SizedBox(height: 32),
          Text(
            title,
            style: context.theme.typography.xl2.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: context.theme.typography.md.copyWith(
              color: context.theme.colors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
