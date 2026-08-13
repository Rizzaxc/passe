// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The signed-in user's courses and coach inquiries (`my_courses_data`).
///
/// Includes threads where they're only `inquiring` — messaging a coach is the
/// first step of the same flow, not a separate inbox.

@ProviderFor(myCourses)
final myCoursesProvider = MyCoursesProvider._();

/// The signed-in user's courses and coach inquiries (`my_courses_data`).
///
/// Includes threads where they're only `inquiring` — messaging a coach is the
/// first step of the same flow, not a separate inbox.

final class MyCoursesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourseSummary>>,
          List<CourseSummary>,
          FutureOr<List<CourseSummary>>
        >
    with
        $FutureModifier<List<CourseSummary>>,
        $FutureProvider<List<CourseSummary>> {
  /// The signed-in user's courses and coach inquiries (`my_courses_data`).
  ///
  /// Includes threads where they're only `inquiring` — messaging a coach is the
  /// first step of the same flow, not a separate inbox.
  MyCoursesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myCoursesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myCoursesHash();

  @$internal
  @override
  $FutureProviderElement<List<CourseSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourseSummary>> create(Ref ref) {
    return myCourses(ref);
  }
}

String _$myCoursesHash() => r'6079f9a924acefbac681b32047962d94529c7393';

/// The coach-side inbox (`pro_courses_data`) — same rows from the other end,
/// carrying the coach's to-do counts (pending proposals, unwritten reports).

@ProviderFor(proCourses)
final proCoursesProvider = ProCoursesProvider._();

/// The coach-side inbox (`pro_courses_data`) — same rows from the other end,
/// carrying the coach's to-do counts (pending proposals, unwritten reports).

final class ProCoursesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CourseSummary>>,
          List<CourseSummary>,
          FutureOr<List<CourseSummary>>
        >
    with
        $FutureModifier<List<CourseSummary>>,
        $FutureProvider<List<CourseSummary>> {
  /// The coach-side inbox (`pro_courses_data`) — same rows from the other end,
  /// carrying the coach's to-do counts (pending proposals, unwritten reports).
  ProCoursesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proCoursesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proCoursesHash();

  @$internal
  @override
  $FutureProviderElement<List<CourseSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CourseSummary>> create(Ref ref) {
    return proCourses(ref);
  }
}

String _$proCoursesHash() => r'0f4e1042a2ecbbd292518569130329ba456565f3';

/// Read-only fast path for "Nhắn tin": does the caller already have a live
/// (inquiring or enrolled) thread with this coach for this sport? Lets a
/// repeat tap skip straight to the existing course instead of reopening the
/// compose sheet. Null means no thread exists yet.

@ProviderFor(courseWithCoach)
final courseWithCoachProvider = CourseWithCoachFamily._();

/// Read-only fast path for "Nhắn tin": does the caller already have a live
/// (inquiring or enrolled) thread with this coach for this sport? Lets a
/// repeat tap skip straight to the existing course instead of reopening the
/// compose sheet. Null means no thread exists yet.

final class CourseWithCoachProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Read-only fast path for "Nhắn tin": does the caller already have a live
  /// (inquiring or enrolled) thread with this coach for this sport? Lets a
  /// repeat tap skip straight to the existing course instead of reopening the
  /// compose sheet. Null means no thread exists yet.
  CourseWithCoachProvider._({
    required CourseWithCoachFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'courseWithCoachProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courseWithCoachHash();

  @override
  String toString() {
    return r'courseWithCoachProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as (String, int);
    return courseWithCoach(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CourseWithCoachProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courseWithCoachHash() => r'fc34e5f7fc0f0abcc9a2f0cfc4c97ea8a5c7a14d';

/// Read-only fast path for "Nhắn tin": does the caller already have a live
/// (inquiring or enrolled) thread with this coach for this sport? Lets a
/// repeat tap skip straight to the existing course instead of reopening the
/// compose sheet. Null means no thread exists yet.

final class CourseWithCoachFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, (String, int)> {
  CourseWithCoachFamily._()
    : super(
        retry: null,
        name: r'courseWithCoachProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Read-only fast path for "Nhắn tin": does the caller already have a live
  /// (inquiring or enrolled) thread with this coach for this sport? Lets a
  /// repeat tap skip straight to the existing course instead of reopening the
  /// compose sheet. Null means no thread exists yet.

  CourseWithCoachProvider call(String professionalId, int sportId) =>
      CourseWithCoachProvider._(
        argument: (professionalId, sportId),
        from: this,
      );

  @override
  String toString() => r'courseWithCoachProvider';
}

@ProviderFor(courseDetail)
final courseDetailProvider = CourseDetailFamily._();

final class CourseDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<CourseDetail>,
          CourseDetail,
          FutureOr<CourseDetail>
        >
    with $FutureModifier<CourseDetail>, $FutureProvider<CourseDetail> {
  CourseDetailProvider._({
    required CourseDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'courseDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$courseDetailHash();

  @override
  String toString() {
    return r'courseDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CourseDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CourseDetail> create(Ref ref) {
    final argument = this.argument as String;
    return courseDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CourseDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$courseDetailHash() => r'2fbfeea34e22a24ccf99bcdf4c6ae19e21611168';

final class CourseDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CourseDetail>, String> {
  CourseDetailFamily._()
    : super(
        retry: null,
        name: r'courseDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CourseDetailProvider call(String courseId) =>
      CourseDetailProvider._(argument: courseId, from: this);

  @override
  String toString() => r'courseDetailProvider';
}

/// The coach's own diary clash check, used to warn (never block) when
/// scheduling or approving. Returns times only — deliberately nothing that
/// would tell a student who else their coach teaches.

@ProviderFor(hasCourseConflict)
final hasCourseConflictProvider = HasCourseConflictFamily._();

/// The coach's own diary clash check, used to warn (never block) when
/// scheduling or approving. Returns times only — deliberately nothing that
/// would tell a student who else their coach teaches.

final class HasCourseConflictProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// The coach's own diary clash check, used to warn (never block) when
  /// scheduling or approving. Returns times only — deliberately nothing that
  /// would tell a student who else their coach teaches.
  HasCourseConflictProvider._({
    required HasCourseConflictFamily super.from,
    required (String, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'hasCourseConflictProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$hasCourseConflictHash();

  @override
  String toString() {
    return r'hasCourseConflictProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as (String, DateTime, DateTime);
    return hasCourseConflict(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is HasCourseConflictProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$hasCourseConflictHash() => r'99d2e596263a92e56746cd542d2657ac882c7619';

/// The coach's own diary clash check, used to warn (never block) when
/// scheduling or approving. Returns times only — deliberately nothing that
/// would tell a student who else their coach teaches.

final class HasCourseConflictFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<bool>,
          (String, DateTime, DateTime)
        > {
  HasCourseConflictFamily._()
    : super(
        retry: null,
        name: r'hasCourseConflictProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The coach's own diary clash check, used to warn (never block) when
  /// scheduling or approving. Returns times only — deliberately nothing that
  /// would tell a student who else their coach teaches.

  HasCourseConflictProvider call(
    String professionalId,
    DateTime start,
    DateTime end,
  ) => HasCourseConflictProvider._(
    argument: (professionalId, start, end),
    from: this,
  );

  @override
  String toString() => r'hasCourseConflictProvider';
}

/// Every write in the course subsystem. One controller rather than several so
/// callers only have to invalidate one thing after a mutation.

@ProviderFor(CourseActionController)
final courseActionControllerProvider = CourseActionControllerProvider._();

/// Every write in the course subsystem. One controller rather than several so
/// callers only have to invalidate one thing after a mutation.
final class CourseActionControllerProvider
    extends $NotifierProvider<CourseActionController, bool> {
  /// Every write in the course subsystem. One controller rather than several so
  /// callers only have to invalidate one thing after a mutation.
  CourseActionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'courseActionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$courseActionControllerHash();

  @$internal
  @override
  CourseActionController create() => CourseActionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$courseActionControllerHash() =>
    r'862103c0e3ef5c03a8fbd12c026d37dcc2f47e9c';

/// Every write in the course subsystem. One controller rather than several so
/// callers only have to invalidate one thing after a mutation.

abstract class _$CourseActionController extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
