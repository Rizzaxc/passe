import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:passe/health_tab/health_controller.dart';
import 'package:passe/health_tab/health_data_service.dart';

void main() {
  group('health platform data types', () {
    test('uses HealthKit distance categories on iOS', () {
      expect(healthDistanceDataTypes(isIOS: true), const [
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.DISTANCE_CYCLING,
        HealthDataType.DISTANCE_SWIMMING,
      ]);
    });

    test('uses Health Connect distance delta on Android', () {
      expect(healthDistanceDataTypes(isIOS: false), const [
        HealthDataType.DISTANCE_DELTA,
      ]);
    });

    test('avoids the unmapped total-calories key on iOS', () {
      expect(
        healthAdditionalEnergyDataType(isIOS: true),
        HealthDataType.BASAL_ENERGY_BURNED,
      );
      expect(
        healthAdditionalEnergyDataType(isIOS: false),
        HealthDataType.TOTAL_CALORIES_BURNED,
      );
    });
  });

  group('activity health evidence', () {
    test('an overlapping Workout record is high evidence', () {
      expect(
        healthEvidenceFor(
          hasWorkout: true,
          easySeconds: 0,
          moderateSeconds: 0,
          hardSeconds: 0,
        ),
        HealthEvidence.high,
      );
    });

    test('ten minutes of easy-zone data is medium evidence', () {
      expect(
        healthEvidenceFor(
          hasWorkout: false,
          easySeconds: 600,
          moderateSeconds: 0,
          hardSeconds: 0,
        ),
        HealthEvidence.medium,
      );
    });

    test('less than ten minutes without a Workout is not enough', () {
      expect(
        healthEvidenceFor(
          hasWorkout: false,
          easySeconds: 300,
          moderateSeconds: 299,
          hardSeconds: 0,
        ),
        HealthEvidence.none,
      );
    });
  });
}
