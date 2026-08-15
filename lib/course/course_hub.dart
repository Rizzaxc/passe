import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/model/enum.dart';
import '../core/state/selected_sport_state.dart';
import '../router.dart';
import '../ui/main.dart';
import 'course_card.dart';
import 'course_controller.dart';
import 'model.dart';

/// Manage ▸ Courses (player side): every course the user is enrolled in plus
/// every coach they have messaged.
class CourseHubSection extends ConsumerWidget {
  const CourseHubSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCoursesProvider);
    // A course is bound to one sport for its whole life (`course.sport_id`),
    // so the hub is scoped to the context sport the same way the Manage ▸
    // Lobby list is (`lobby_controller.dart`'s `sport_id == Sport.index`
    // filter) — without this, a course with a coach who happens to teach
    // several sports (`professional.sports`) showed up regardless of which
    // sport was selected, which read as "the same coach thread" bleeding
    // across sports even though messaging that coach under a different
    // sport correctly starts a brand new, separate course.
    final sport = ref.watch(selectedSportStateProvider).value;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PSectionHeader(
          title: 'course.title'.tr(),
          suffix: Semantics(
            button: true,
            label: 'course.findCoach'.tr(),
            child: FButton.icon(
              variant: .ghost,
              onPress: () => const DiscoverProfessionalRoute().go(context),
              child: const Icon(FLucideIcons.search),
            ),
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const _CourseListSkeleton(),
            error: (_, _) => _CourseListState(
              icon: FLucideIcons.cloudOff,
              message: 'course.loadFailed'.tr(),
              actionLabel: 'course.retry'.tr(),
              actionIcon: FLucideIcons.refreshCw,
              onAction: () => ref.invalidate(myCoursesProvider),
              onRefresh: () => ref.refresh(myCoursesProvider.future),
            ),
            data: (all) {
              final courses = sport == null || sport == Sport.others
                  ? const <CourseSummary>[]
                  : all.where((c) => c.sportId == sport.index).toList();
              return courses.isEmpty
                  ? _CourseListState(
                      icon: FLucideIcons.graduationCap,
                      message: 'course.emptyPlayer'.tr(),
                      actionLabel: 'course.findCoach'.tr(),
                      actionIcon: FLucideIcons.search,
                      onAction: () =>
                          const DiscoverProfessionalRoute().go(context),
                      onRefresh: () => ref.refresh(myCoursesProvider.future),
                    )
                  : _CourseList(
                      courses: courses,
                      onRefresh: () => ref.refresh(myCoursesProvider.future),
                    );
            },
          ),
        ),
      ],
    );
  }
}

/// Coach Manage ▸ Courses / History. Both tabs deliberately reuse the same
/// hub hierarchy; only the status filter and empty copy differ.
class ProCoursesSection extends ConsumerWidget {
  final bool endedOnly;

  const ProCoursesSection({super.key, this.endedOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(proCoursesProvider);
    // Same context-sport scoping as the player-side hub above — a coach who
    // teaches several sports shouldn't see a badminton student's course
    // while soccer is selected.
    final sport = ref.watch(selectedSportStateProvider).value;

    ref.listen(proCoursesProvider, (_, next) {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PSectionHeader(
          title: endedOnly
              ? 'course.courseHistory'.tr()
              : 'course.activeCourses'.tr(),
        ),
        Expanded(
          child: async.when(
            loading: () => const _CourseListSkeleton(),
            error: (_, _) => _CourseListState(
              icon: FLucideIcons.cloudOff,
              message: 'course.loadFailed'.tr(),
              actionLabel: 'course.retry'.tr(),
              actionIcon: FLucideIcons.refreshCw,
              onAction: () => ref.invalidate(proCoursesProvider),
              onRefresh: () => ref.refresh(proCoursesProvider.future),
            ),
            data: (all) {
              final courses = (sport == null || sport == Sport.others
                      ? const <CourseSummary>[]
                      : all.where((c) => c.sportId == sport.index))
                  .where(
                    (course) => endedOnly
                        ? course.status == CourseStatus.ended
                        : course.status == CourseStatus.active,
                  )
                  .toList();

              if (courses.isEmpty) {
                return _CourseListState(
                  icon: endedOnly
                      ? FLucideIcons.archive
                      : FLucideIcons.graduationCap,
                  message: endedOnly
                      ? 'course.emptyCoachHistory'.tr()
                      : 'course.emptyCoach'.tr(),
                  onRefresh: () => ref.refresh(proCoursesProvider.future),
                );
              }

              return _CourseList(
                courses: courses,
                coachSide: true,
                onRefresh: () => ref.refresh(proCoursesProvider.future),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CourseList extends StatelessWidget {
  final List<CourseSummary> courses;
  final bool coachSide;
  final Future<void> Function() onRefresh;

  const _CourseList({
    required this.courses,
    required this.onRefresh,
    this.coachSide = false,
  });

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final course = courses[index];
        return CourseCard(
          course: course,
          coachSide: coachSide,
          onTap: () => CourseDetailRoute(id: course.courseId).push(context),
        );
      },
    ),
  );
}

class _CourseListSkeleton extends StatelessWidget {
  const _CourseListSkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 32),
    itemCount: 3,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (_, _) => const CourseCardSkeleton(),
  );
}

class _CourseListState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Future<void> Function() onRefresh;

  const _CourseListState({
    required this.icon,
    required this.message,
    required this.onRefresh,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    child: LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 56).clamp(0, double.infinity),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PEmptySectionPlaceholder(
                    hero: Icon(
                      icon,
                      size: 64,
                      color: context.theme.colors.mutedForeground,
                    ),
                    subtitle: message,
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 4),
                    FButton(
                      onPress: onAction,
                      prefix: actionIcon == null
                          ? null
                          : Icon(actionIcon, size: 16),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
