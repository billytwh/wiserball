import 'package:flutter_test/flutter_test.dart';
import 'package:wiser_sport/main.dart';

void main() {
  test('ball state points', () {
    expect(BallState.contesting.points(), 5);
    expect(BallState.firstLocked.points(), 2);
    expect(BallState.secondLocked.points(), 1);
    expect(BallState.struckOut.points(), 0);
  });

  test('competition type active balls', () {
    expect(CompetitionType.single.activeBallsPerTeam(), 5);
    expect(CompetitionType.double.activeBallsPerTeam(), 6);
    expect(CompetitionType.team.activeBallsPerTeam(), 7);
  });

  test('game state remaining seconds', () {
    final now = 1_000_000;
    final state = GameState.initial().copyWith(
      timerEndAtEpochMs: now + 1500,
    );
    expect(state.remainingSeconds(now), 2);
    expect(state.remainingSeconds(now + 1500), 0);
    expect(state.remainingSeconds(now + 2500), 0);
  });

  test('game state serialization roundtrip', () {
    final state = GameState.initial().copyWith(
      competitionType: CompetitionType.double,
      red: [
        BallState.contesting,
        BallState.firstLocked,
        BallState.secondLocked,
        BallState.struckOut,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
      ],
      rescueMode: true,
      timerEndAtEpochMs: 123456,
      fouls: const [
        FoulEntry(
          epochMs: 1,
          team: Team.red,
          ballNumber: 1,
          severity: FoulSeverity.severe,
          note: 'test',
          instantElimination: true,
        ),
      ],
    );
    final json = state.toJson();
    final restored = GameState.fromJson(json);
    expect(restored.competitionType, CompetitionType.double);
    expect(restored.red[1], BallState.firstLocked);
    expect(restored.rescueMode, true);
    expect(restored.timerEndAtEpochMs, 123456);
    expect(restored.fouls.length, 1);
    expect(restored.fouls.first.instantElimination, true);
  });
}

