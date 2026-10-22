import 'package:flutter_test/flutter_test.dart';
import 'package:passe/course/course_hub.dart';
import 'package:passe/manage_tab/freeplay_section/main.dart';
import 'package:passe/manage_tab/lobby_section/feed/main.dart';
import 'package:passe/manage_tab/lobby_section/freeplay_section/main.dart';
import 'package:passe/manage_tab/main.dart';
import 'package:passe/manage_tab/schedule_section/main.dart';
import 'package:passe/professional/pro_mode/pending_requests_main.dart';
import 'package:passe/professional/pro_mode/pro_schedule_main.dart';

void main() {
  test('player Manage order is Lobby, Schedule, Course, Freeplay', () {
    expect(ManageTab.primaryIndex, 0);
    expect(ManageTab.scheduleIndex, 1);
    expect(ManageTab.playerCourseIndex, 2);
    expect(ManageTab.manageSections[0].build(), isA<LobbySubtab>());
    expect(ManageTab.manageSections[1].build(), isA<ScheduleSection>());
    expect(ManageTab.manageSections[2].build(), isA<CourseHubSection>());
    expect(ManageTab.playerFreeplayIndex, 3);
    expect(ManageTab.manageSections[3].build(), isA<PlayerFreeplaySubtab>());
  });

  test('coach Manage order is Courses, Schedule, History', () {
    final sections = ManageTab.proManageSections('pro-1', isCoach: true);

    expect(sections[0].build(), isA<ProCoursesSection>());
    expect(sections[1].build(), isA<ScheduleSection>());
    expect(sections[2].build(), isA<ProCoursesSection>());
  });

  test('referee Manage order is Requests, Schedule, History', () {
    final sections = ManageTab.proManageSections('pro-1');

    expect(sections[0].build(), isA<ProPendingRequestsSection>());
    expect(sections[1].build(), isA<ProScheduleSection>());
  });

  test('host Manage order is Listings, Schedule', () {
    expect(ManageTab.hostManageSections[0].build(), isA<HostFreeplaySection>());
    expect(ManageTab.hostManageSections[1].build(), isA<ScheduleSection>());
    expect(
      (ManageTab.hostManageSections[1].build() as ScheduleSection).dataSource,
      ScheduleDataSource.host,
    );
  });
}
