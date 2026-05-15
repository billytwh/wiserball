import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WiserApp());
}

class WiserApp extends StatelessWidget {
  const WiserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wiser Sport',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

enum Team { red, white }

enum BallState { contesting, firstLocked, secondLocked, struckOut }

extension BallStateX on BallState {
  BallState next() {
    return switch (this) {
      BallState.contesting => BallState.firstLocked,
      BallState.firstLocked => BallState.secondLocked,
      BallState.secondLocked => BallState.struckOut,
      BallState.struckOut => BallState.struckOut,
    };
  }

  BallState prev() {
    return switch (this) {
      BallState.contesting => BallState.contesting,
      BallState.firstLocked => BallState.contesting,
      BallState.secondLocked => BallState.firstLocked,
      BallState.struckOut => BallState.secondLocked,
    };
  }

  int points() {
    return switch (this) {
      BallState.contesting => 5,
      BallState.firstLocked => 2,
      BallState.secondLocked => 1,
      BallState.struckOut => 0,
    };
  }

  String label() {
    return switch (this) {
      BallState.contesting => 'Contesting',
      BallState.firstLocked => 'First-Locked',
      BallState.secondLocked => 'Second-Locked',
      BallState.struckOut => 'Struck-Out',
    };
  }
}

enum CompetitionType { single, double, team }

extension CompetitionTypeX on CompetitionType {
  String label() {
    return switch (this) {
      CompetitionType.single => 'Single',
      CompetitionType.double => 'Double',
      CompetitionType.team => 'Team',
    };
  }

  int activeBallsPerTeam() {
    return switch (this) {
      CompetitionType.single => 5,
      CompetitionType.double => 6,
      CompetitionType.team => 7,
    };
  }
}

enum FoulSeverity { general, severe }

extension FoulSeverityX on FoulSeverity {
  String label() {
    return switch (this) {
      FoulSeverity.general => 'General',
      FoulSeverity.severe => 'Severe',
    };
  }
}

class FoulEntry {
  final int epochMs;
  final Team team;
  final int ballNumber;
  final FoulSeverity severity;
  final String note;
  final bool instantElimination;

  const FoulEntry({
    required this.epochMs,
    required this.team,
    required this.ballNumber,
    required this.severity,
    required this.note,
    required this.instantElimination,
  });

  Map<String, dynamic> toJson() => {
        'epochMs': epochMs,
        'team': team.name,
        'ballNumber': ballNumber,
        'severity': severity.name,
        'note': note,
        'instantElimination': instantElimination,
      };

  static FoulEntry fromJson(Map<String, dynamic> json) {
    return FoulEntry(
      epochMs: json['epochMs'] as int,
      team: Team.values.byName(json['team'] as String),
      ballNumber: json['ballNumber'] as int,
      severity: FoulSeverity.values.byName(json['severity'] as String),
      note: (json['note'] as String?) ?? '',
      instantElimination: (json['instantElimination'] as bool?) ?? false,
    );
  }
}

class GameState {
  final CompetitionType competitionType;
  final List<BallState> red;
  final List<BallState> white;
  final bool rescueMode;
  final int totalSeconds;
  final int? timerEndAtEpochMs;
  final List<FoulEntry> fouls;

  const GameState({
    required this.competitionType,
    required this.red,
    required this.white,
    required this.rescueMode,
    required this.totalSeconds,
    required this.timerEndAtEpochMs,
    required this.fouls,
  });

  factory GameState.initial() {
    return const GameState(
      competitionType: CompetitionType.team,
      red: [
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
      ],
      white: [
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
        BallState.contesting,
      ],
      rescueMode: false,
      totalSeconds: 90 * 60,
      timerEndAtEpochMs: null,
      fouls: [],
    );
  }

  int activeBallsPerTeam() => competitionType.activeBallsPerTeam();

  int remainingSeconds(int nowEpochMs) {
    final end = timerEndAtEpochMs;
    if (end == null) return totalSeconds;
    final remainingMs = end - nowEpochMs;
    if (remainingMs <= 0) return 0;
    return (remainingMs / 1000).ceil();
  }

  GameState copyWith({
    CompetitionType? competitionType,
    List<BallState>? red,
    List<BallState>? white,
    bool? rescueMode,
    int? totalSeconds,
    int? timerEndAtEpochMs,
    List<FoulEntry>? fouls,
  }) {
    return GameState(
      competitionType: competitionType ?? this.competitionType,
      red: red ?? this.red,
      white: white ?? this.white,
      rescueMode: rescueMode ?? this.rescueMode,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      timerEndAtEpochMs: timerEndAtEpochMs ?? this.timerEndAtEpochMs,
      fouls: fouls ?? this.fouls,
    );
  }

  Map<String, dynamic> toJson() => {
        'competitionType': competitionType.name,
        'red': red.map((e) => e.name).toList(growable: false),
        'white': white.map((e) => e.name).toList(growable: false),
        'rescueMode': rescueMode,
        'totalSeconds': totalSeconds,
        'timerEndAtEpochMs': timerEndAtEpochMs,
        'fouls': fouls.map((e) => e.toJson()).toList(growable: false),
      };

  static GameState fromJson(Map<String, dynamic> json) {
    final redList = (json['red'] as List<dynamic>? ?? const [])
        .cast<String>()
        .map(BallState.values.byName)
        .toList(growable: false);
    final whiteList = (json['white'] as List<dynamic>? ?? const [])
        .cast<String>()
        .map(BallState.values.byName)
        .toList(growable: false);

    return GameState(
      competitionType:
          CompetitionType.values.byName(json['competitionType'] as String),
      red: _padToSeven(redList),
      white: _padToSeven(whiteList),
      rescueMode: (json['rescueMode'] as bool?) ?? false,
      totalSeconds: (json['totalSeconds'] as int?) ?? 90 * 60,
      timerEndAtEpochMs: json['timerEndAtEpochMs'] as int?,
      fouls: ((json['fouls'] as List<dynamic>?) ?? const [])
          .whereType<Map>()
          .map((e) => FoulEntry.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  static List<BallState> _padToSeven(List<BallState> input) {
    if (input.length >= 7) return input.take(7).toList(growable: false);
    final out = input.toList(growable: true);
    while (out.length < 7) {
      out.add(BallState.contesting);
    }
    return out.toList(growable: false);
  }
}

class GameStorage {
  static const _key = 'wiserSport.gameState.v1';

  Future<GameState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class ScoreResult {
  final int redPoints;
  final int whitePoints;

  const ScoreResult({required this.redPoints, required this.whitePoints});

  String winnerLabel() {
    if (redPoints > whitePoints) return 'Red Wins';
    if (whitePoints > redPoints) return 'White Wins';
    return 'Tie';
  }
}

class GameController extends ChangeNotifier {
  final GameStorage storage;
  GameState _state;
  Timer? _timer;
  Timer? _saveDebounce;
  DateTime _lastSavedAt = DateTime.fromMillisecondsSinceEpoch(0);

  GameController({required this.storage, required GameState initialState})
      : _state = initialState;

  GameState get state => _state;

  Future<void> restore() async {
    final loaded = await storage.load();
    if (loaded != null) {
      _state = loaded;
    }
    _startTickIfNeeded();
    notifyListeners();
  }

  void setCompetitionType(CompetitionType type) {
    _state = _state.copyWith(competitionType: type);
    _scheduleSave();
    notifyListeners();
  }

  void toggleRescueMode() {
    _state = _state.copyWith(rescueMode: !_state.rescueMode);
    _scheduleSave();
    notifyListeners();
  }

  bool isBallEnabled(int ballIndex) {
    return ballIndex < _state.activeBallsPerTeam();
  }

  void tapBall(Team team, int ballIndex) {
    if (!isBallEnabled(ballIndex)) return;
    final list = (team == Team.red ? _state.red : _state.white).toList();
    final current = list[ballIndex];
    list[ballIndex] = _state.rescueMode ? current.prev() : current.next();
    if (team == Team.red) {
      _state = _state.copyWith(red: list);
    } else {
      _state = _state.copyWith(white: list);
    }
    _scheduleSave();
    notifyListeners();
  }

  void instantEliminate(Team team, int ballNumber) {
    final index = ballNumber - 1;
    if (index < 0 || index >= 7) return;
    if (!isBallEnabled(index)) return;

    final list = (team == Team.red ? _state.red : _state.white).toList();
    list[index] = BallState.struckOut;
    if (team == Team.red) {
      _state = _state.copyWith(red: list);
    } else {
      _state = _state.copyWith(white: list);
    }
    _scheduleSave();
    notifyListeners();
  }

  void addFoul({
    required Team team,
    required int ballNumber,
    required FoulSeverity severity,
    required String note,
    required bool instantElimination,
  }) {
    final entry = FoulEntry(
      epochMs: DateTime.now().millisecondsSinceEpoch,
      team: team,
      ballNumber: ballNumber,
      severity: severity,
      note: note,
      instantElimination: instantElimination,
    );
    final updated = [entry, ..._state.fouls];
    _state = _state.copyWith(fouls: updated);
    if (instantElimination) {
      this.instantEliminate(team, ballNumber);
      return;
    }
    _scheduleSave();
    notifyListeners();
  }

  void clearAll() {
    _timer?.cancel();
    _timer = null;
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _state = GameState.initial();
    storage.clear();
    notifyListeners();
  }

  void startMatchTimer() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final remaining = _state.remainingSeconds(now);
    if (remaining <= 0) return;
    if (_state.timerEndAtEpochMs != null) return;

    final endAt = now + remaining * 1000;
    _state = _state.copyWith(timerEndAtEpochMs: endAt);
    _startTickIfNeeded();
    _scheduleSave();
    notifyListeners();
  }

  void resetMatchTimer() {
    _timer?.cancel();
    _timer = null;
    _state = _state.copyWith(timerEndAtEpochMs: null);
    _scheduleSave();
    notifyListeners();
  }

  void _startTickIfNeeded() {
    _timer?.cancel();
    final end = _state.timerEndAtEpochMs;
    if (end == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (_state.remainingSeconds(now) == 0) {
        t.cancel();
      }
      notifyListeners();
      final sinceLastSave = DateTime.now().difference(_lastSavedAt);
      if (sinceLastSave.inSeconds >= 10) {
        _scheduleSave(immediate: true);
      }
    });
  }

  ScoreResult calculateScore() {
    final active = _state.activeBallsPerTeam();
    final redPoints =
        _state.red.take(active).fold(0, (sum, s) => sum + s.points());
    final whitePoints =
        _state.white.take(active).fold(0, (sum, s) => sum + s.points());
    return ScoreResult(redPoints: redPoints, whitePoints: whitePoints);
  }

  void flushSave() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    _doSave();
  }

  void _scheduleSave({bool immediate = false}) {
    if (immediate) {
      _doSave();
      return;
    }
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), _doSave);
  }

  void _doSave() {
    _lastSavedAt = DateTime.now();
    storage.save(_state);
  }

  @override
  void dispose() {
    flushSave();
    _timer?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final GameController _controller;
  int _tabIndex = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = GameController(
      storage: GameStorage(),
      initialState: GameState.initial(),
    );
    _init();
  }

  Future<void> _init() async {
    await _controller.restore();
    if (mounted) {
      setState(() {
        _ready = true;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller.flushSave();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      MatchPage(controller: _controller),
      ToolsPage(controller: _controller),
      const ReferencePage(),
    ];

    return Scaffold(
      body: pages[_tabIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports), label: 'Match'),
          NavigationDestination(icon: Icon(Icons.rule), label: 'Tools'),
          NavigationDestination(icon: Icon(Icons.menu_book), label: 'Reference'),
        ],
      ),
    );
  }
}

class MatchPage extends StatelessWidget {
  final GameController controller;

  const MatchPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final now = DateTime.now().millisecondsSinceEpoch;
        final remaining = state.remainingSeconds(now);
        final mm = (remaining ~/ 60).toString().padLeft(2, '0');
        final ss = (remaining % 60).toString().padLeft(2, '0');
        final timerStarted = state.timerEndAtEpochMs != null;

        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Wiser Sport'),
              actions: [
                IconButton(
                  onPressed: () {
                    _confirmReset(context);
                  },
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reset Match',
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<CompetitionType>(
                          value: state.competitionType,
                          items: CompetitionType.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.label()),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (v) {
                            if (v != null) controller.setCompetitionType(v);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Competition Type',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonal(
                        onPressed: controller.toggleRescueMode,
                        child: Text(state.rescueMode ? 'Rescue: ON' : 'Rescue'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Game Timer'),
                                const SizedBox(height: 8),
                                Text(
                                  '$mm:$ss',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall,
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed:
                                timerStarted || remaining == 0 ? null : () {
                              controller.startMatchTimer();
                            },
                            child: const Text('Start'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: () => controller.resetMatchTimer(),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      final result = controller.calculateScore();
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Result'),
                          content: Text(
                            'Red: ${result.redPoints}\nWhite: ${result.whitePoints}\n\n${result.winnerLabel()}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Calculate Winner'),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Balls'),
                            const SizedBox(height: 12),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, c) {
                                  final size = c.biggest;
                                  final crossAxisCount =
                                      size.width ~/ 64 >= 7 ? 7 : 4;
                                  return GridView.count(
                                    crossAxisCount: crossAxisCount,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    children: [
                                      for (var i = 0; i < 7; i++)
                                        BallTile(
                                          team: Team.red,
                                          ballNumber: i + 1,
                                          state: state.red[i],
                                          enabled: controller.isBallEnabled(i),
                                          onTap: () =>
                                              controller.tapBall(Team.red, i),
                                        ),
                                      for (var i = 0; i < 7; i++)
                                        BallTile(
                                          team: Team.white,
                                          ballNumber: i + 1,
                                          state: state.white[i],
                                          enabled: controller.isBallEnabled(i),
                                          onTap: () =>
                                              controller.tapBall(Team.white, i),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Match'),
        content: const Text('Clear all balls, timer, and foul logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      controller.clearAll();
    }
  }
}

class BallTile extends StatelessWidget {
  final Team team;
  final int ballNumber;
  final BallState state;
  final bool enabled;
  final VoidCallback onTap;

  const BallTile({
    super.key,
    required this.team,
    required this.ballNumber,
    required this.state,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = team == Team.red ? Colors.red : Colors.grey.shade200;
    final borderColor = team == Team.red ? Colors.red : Colors.grey.shade700;
    final fillColor = switch (state) {
      BallState.contesting => Colors.transparent,
      BallState.firstLocked => Colors.yellow.shade600,
      BallState.secondLocked => Colors.red.shade700,
      BallState.struckOut => Colors.grey.shade400,
    };

    final textColor = team == Team.red ? Colors.white : Colors.black;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.25,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            color: state == BallState.contesting ? teamColor : fillColor,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$ballNumber',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: state == BallState.contesting
                            ? textColor
                            : Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Text(
                  state.label(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: state == BallState.contesting
                            ? textColor
                            : Colors.white,
                      ),
                ),
              ),
              if (state == BallState.struckOut)
                const Positioned.fill(
                  child: Center(
                    child: Icon(Icons.close, size: 42, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ToolsPage extends StatelessWidget {
  final GameController controller;

  const ToolsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Referee Tools')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const InterceptionTimerCard(),
            const SizedBox(height: 12),
            const OutOfBoundsCard(),
            const SizedBox(height: 12),
            FoulLoggerCard(controller: controller),
          ],
        ),
      ),
    );
  }
}

class InterceptionTimerCard extends StatefulWidget {
  const InterceptionTimerCard({super.key});

  @override
  State<InterceptionTimerCard> createState() => _InterceptionTimerCardState();
}

class _InterceptionTimerCardState extends State<InterceptionTimerCard> {
  Timer? _timer;
  int _remainingMs = 2000;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _remainingMs = 2000;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() {
        _remainingMs -= 50;
        if (_remainingMs <= 0) {
          _remainingMs = 0;
          t.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final seconds = (_remainingMs / 1000).toStringAsFixed(2);
    final done = _remainingMs == 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Interception (2s)'),
                  const SizedBox(height: 8),
                  Text(
                    seconds,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: done ? Colors.red : null,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _start,
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}

class OutOfBoundsCard extends StatefulWidget {
  const OutOfBoundsCard({super.key});

  @override
  State<OutOfBoundsCard> createState() => _OutOfBoundsCardState();
}

class _OutOfBoundsCardState extends State<OutOfBoundsCard> {
  bool _completelyOutside = false;
  bool _touchedOutsideObject = false;

  @override
  Widget build(BuildContext context) {
    final isOut = _completelyOutside && _touchedOutsideObject;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Out-of-Bounds Checklist'),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _completelyOutside,
              onChanged: (v) => setState(() => _completelyOutside = v),
              title: const Text('Ball completely outside boundary line'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _touchedOutsideObject,
              onChanged: (v) => setState(() => _touchedOutsideObject = v),
              title: const Text('Ball touched ground/object outside'),
            ),
            const SizedBox(height: 8),
            Text(
              isOut ? 'OUT' : 'NOT OUT',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isOut ? Colors.red : Colors.green,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class FoulLoggerCard extends StatefulWidget {
  final GameController controller;

  const FoulLoggerCard({super.key, required this.controller});

  @override
  State<FoulLoggerCard> createState() => _FoulLoggerCardState();
}

class _FoulLoggerCardState extends State<FoulLoggerCard> {
  Team _team = Team.red;
  int _ballNumber = 1;
  FoulSeverity _severity = FoulSeverity.general;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final active = widget.controller.state.activeBallsPerTeam();
        if (_ballNumber > active) _ballNumber = active;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Foul Logger'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Team>(
                        value: _team,
                        items: const [
                          DropdownMenuItem(
                            value: Team.red,
                            child: Text('Red'),
                          ),
                          DropdownMenuItem(
                            value: Team.white,
                            child: Text('White'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _team = v ?? _team),
                        decoration: const InputDecoration(labelText: 'Team'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _ballNumber,
                        items: [
                          for (var i = 1; i <= active; i++)
                            DropdownMenuItem(value: i, child: Text('Ball $i')),
                        ],
                        onChanged: (v) =>
                            setState(() => _ballNumber = v ?? _ballNumber),
                        decoration:
                            const InputDecoration(labelText: 'Ball Number'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<FoulSeverity>(
                  value: _severity,
                  items: FoulSeverity.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.label()),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (v) =>
                      setState(() => _severity = v ?? _severity),
                  decoration: const InputDecoration(labelText: 'Severity'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    final instantElimination = _severity == FoulSeverity.severe;
                    widget.controller.addFoul(
                      team: _team,
                      ballNumber: _ballNumber,
                      severity: _severity,
                      note: _noteController.text.trim(),
                      instantElimination: instantElimination,
                    );
                    _noteController.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          instantElimination
                              ? 'Severe foul logged + instant elimination'
                              : 'Foul logged',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    _severity == FoulSeverity.severe
                        ? 'Log Severe + Eliminate'
                        : 'Log Foul',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Recent'),
                const SizedBox(height: 8),
                if (widget.controller.state.fouls.isEmpty)
                  const Text('No fouls logged yet.')
                else
                  ...widget.controller.state.fouls
                      .take(10)
                      .map((e) => _FoulRow(entry: e)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FoulRow extends StatelessWidget {
  final FoulEntry entry;

  const _FoulRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final time = DateTime.fromMillisecondsSinceEpoch(entry.epochMs);
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final ss = time.second.toString().padLeft(2, '0');
    final team = entry.team == Team.red ? 'Red' : 'White';
    final flag = entry.instantElimination ? ' (ELIM)' : '';
    final note = entry.note.isEmpty ? '' : ' - ${entry.note}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        '$hh:$mm:$ss  $team Ball ${entry.ballNumber}  ${entry.severity.label()}$flag$note',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class ReferencePage extends StatelessWidget {
  const ReferencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Reference')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Field Dimensions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('• Centerline: 12m'),
            const Text('• Boundary range: 30m to 43m'),
            const Text('• Service lines: per handbook diagram'),
            const SizedBox(height: 16),
            Text(
              'Equipment Specs',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('• Ball: 90mm, 168g'),
            const Text('• Flags: per handbook dimensions'),
            const SizedBox(height: 16),
            Text(
              'Scoring (Timer Expiry)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text('• Contesting: 5 points'),
            const Text('• First-Locked (Yellow): 2 points'),
            const Text('• Second-Locked (Red): 1 point'),
          ],
        ),
      ),
    );
  }
}

