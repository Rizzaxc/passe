import 'package:flutter_test/flutter_test.dart';
import 'package:passe/course/course_hub.dart';
import 'package:passe/manage_tab/freeplay_section/main.dart';
import 'package:passe/manage_tab/lobby_section/feed/main.dart';
import 'package:passe/manage_tab/main.dart';
import 'package:passe/manage_tab/schedule_section/main.dart';
import 'package:passe/professional/pro_mode/pending_requests_main.dart';
import 'package:passe/professional/pro_mode/pro_schedule_main.dart';

void main() {
  test('player Manage order is Lobby, Schedule, Course', () {
    expect(ManageTab.primaryIndex, 0);
    expect(ManageTab.scheduleIndex, 1);
    expect(ManageTab.playerCourseIndex, 2);
    expect(ManageTab.manageSections[0].child, isA<LobbySubtab>());
    expect(ManageTab.manageSections[1].child, isA<ScheduleSection>());
    expect(ManageTab.manageSections[2].child, isA<CourseHubSection>());
  });

  test('coach Manage order is Courses, Schedule, History', () {
    final sections = ManageTab.proManageSections('pro-1', isCoach: true);

    expect(sections[0].child, isA<ProCoursesSection>());
    expect(sections[1].child, isA<ScheduleSection>());
    expect(sections[2].child, isA<ProCoursesSection>());
  });

  test('referee Manage order is Requests, Schedule, History', () {
    final sections = ManageTab.proManageSections('pro-1');

    expect(sections[0].child, isA<ProPendingRequestsSection>());
    expect(sections[1].child, isA<ProScheduleSection>());
  });

  test('host Manage order is Listings, Schedule', () {
    expect(ManageTab.hostManageSections[0].child, isA<HostFreeplaySection>());
    expect(ManageTab.hostManageSections[1].child, isA<ScheduleSection>());
    expect(
      (ManageTab.hostManageSections[1].child as ScheduleSection).dataSource,
      ScheduleDataSource.host,
    );
  });
}
