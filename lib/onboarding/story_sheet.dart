import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../ui/sheet.dart';
import 'onboarding_controller.dart';

/// Shows the "how Passe works" story as a half-height sheet over the real,
/// already sport-scoped shell — rather than a full-screen carousel that
/// walls the user off from the app they just landed in. Marks the story
/// done regardless of how the sheet closes (finished or swiped away): once
/// shown, it shouldn't nag again.
Future<void> showStorySheet(BuildContext context, WidgetRef ref) async {
  await showPSheet(context: context, builder: (_) => const _StorySheetContent());
  if (!context.mounted) return;
  await ref.read(onboardingStateProvider.notifier).completeStory();
}

class _StorySheetContent extends HookWidget {
  const _StorySheetContent();

  static const _slideCount = 3;
  static const _icons = [
    FLucideIcons.compass,
    FLucideIcons.users,
    FLucideIcons.trophy,
  ];

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController();
    final currentPage = useState(0);
    final colors = context.theme.colors;
    final isLast = currentPage.value == _slideCount - 1;

    void onNext() {
      if (isLast) {
        Navigator.of(context).pop();
      } else {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: (i) => currentPage.value = i,
              children: [
                for (var i = 0; i < _slideCount; i++)
                  _StorySlide(
                    icon: _icons[i],
                    title: 'onboarding.story.s${i + 1}.title'.tr(),
                    body: 'onboarding.story.s${i + 1}.body'.tr(),
                  ),
              ],
            ),
          ),
          SmoothPageIndicator(
            controller: pageController,
            count: _slideCount,
            effect: WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: colors.primary,
              dotColor: colors.border,
            ),
          ),
          const SizedBox(height: 16),
          FButton(
            onPress: onNext,
            child: Text(isLast ? 'onboarding.done'.tr() : 'onboarding.next'.tr()),
          ),
        ],
      ),
    );
  }
}

class _StorySlide extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _StorySlide({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 32, color: colors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: context.theme.typography.body.xl.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: context.theme.typography.body.sm.copyWith(color: colors.mutedForeground, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
