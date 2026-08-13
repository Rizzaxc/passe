import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../router.dart';
import '../ui/main.dart';
import 'course_card.dart';
import 'course_controller.dart';
import 'model.dart';

/// Manage ▸ Coaching (player side): every course the user is enrolled in plus
/// every coach they've messaged.
///
/// Replaced the booking-backed `CoachingSection`, which grouped
/// `professional_booking` rows by coach to *look* like a course.
class CourseHubSection extends ConsumerWidget {
  const CourseHubSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCoursesProvider);

    ref.listen(myCoursesProvider, (_, next) {
      if (next is AsyncError && context.mounted) {
        showFToast(
          context: context,
          icon: const Icon(FLucideIcons.circleX),
          variant: .destructive,
          title: Text('course.loadFailed'.tr()),
          alignment: .bottomCenter,
        );
      }
    });

    return async.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (_, _) => _Refreshable(
        onRefresh: () => ref.refresh(myCoursesProvider.future),
        child: PEmptySectionPlaceholder(subtitle: 'course.loadFailed'.tr()),
      ),
      data: (courses) => _Refreshable(
        onRefresh: () => ref.refresh(myCoursesProvider.future),
        child: courses.isEmpty
            ? PEmptySectionPlaceholder(subtitle: 'course.emptyPlayer'.tr())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final course in courses)
                    CourseCard(
                      course: course,
                      onTap: () =>
                          CourseDetailRoute(id: course.courseId).push(context),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Pro mode ▸ Courses (coach side): the same relationships from the other end,
/// with the coach's to-do counts surfaced on each card.
///
/// One provider backs two tabs: the inbox shows live courses, and pro mode's
/// third tab passes [endedOnly] to become a course history. Splitting them
/// client-side keeps a coach's "what needs me today" list free of finished
/// work without a second round trip — `pro_courses_data` already returns the
/// status.
class ProCoursesSection extends ConsumerWidget {
  final bool endedOnly;

  const ProCoursesSection({super.key, this.endedOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proCoursesProvider);

    return async.when(
      loading: () => const Center(child: FCircularProgress()),
      error: (_, _) => _Refreshable(
        onRefresh: () => ref.refresh(proCoursesProvider.future),
        child: PEmptySectionPlaceholder(subtitle: 'course.loadFailed'.tr()),
      ),
      data: (all) {
        final courses = all
            .where(
              (c) => endedOnly
                  ? c.status == CourseStatus.ended
                  : c.status == CourseStatus.active,
            )
            .toList();

        return _Refreshable(
          onRefresh: () => ref.refresh(proCoursesProvider.future),
          child: courses.isEmpty
              ? PEmptySectionPlaceholder(
                  subtitle: endedOnly
                      ? 'course.emptyCoachHistory'.tr()
                      : 'course.emptyCoach'.tr(),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final course in courses)
                      CourseCard(
                        course: course,
                        coachSide: true,
                        onTap: () =>
                            CourseDetailRoute(id: course.courseId).push(context),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// Every feed-like screen in the app is pull-to-refresh; these are no exception.
class _Refreshable extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const _Refreshable({required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [child],
    ),
  );
}
