/// AUREN AAA game production contract.
///
/// Every AUREN game is authored against this contract before it is considered
/// production-ready. The contract keeps the Flutter shell separate from the
/// real-time 3D runtime so games can be upgraded to a native 3D runtime
/// without rewriting the AUREN account, profile, ranking and store layers.
class AaaGameSpec {
  final String gameId;
  final String runtime;
  final String camera;
  final String multiplayer;
  final List<String> systems;
  final List<String> qualityGates;

  const AaaGameSpec({
    required this.gameId,
    this.runtime = '3D runtime',
    this.camera = 'third-person / adaptive',
    this.multiplayer = 'online-ready',
    this.systems = const [],
    this.qualityGates = const [],
  });
}

class AurenAaaGameManifest {
  static const all = <AaaGameSpec>[
    AaaGameSpec(
      gameId: 'lost_world',
      camera: 'third-person cinematic',
      systems: [
        'streaming_world',
        'character_controller',
        'combat',
        'quests',
        'inventory',
        'vehicles',
        'dynamic_weather',
        'day_night',
        'npc_ai',
        'online_coop',
        'save_progress',
      ],
      qualityGates: [
        'original IP',
        '3D environment',
        'animated characters',
        'spatial audio',
        'controller/touch support',
        'stable 30fps mobile target',
      ],
    ),
    AaaGameSpec(
      gameId: 'football',
      camera: 'broadcast / player',
      systems: ['3d_players', 'ball_physics', 'career', 'online_matchmaking', 'ranked'],
    ),
    AaaGameSpec(
      gameId: 'racing',
      camera: 'cockpit / chase',
      systems: ['3d_vehicles', 'vehicle_physics', 'tracks', 'weather', 'online_races'],
    ),
    AaaGameSpec(
      gameId: 'boxing',
      camera: 'arena',
      systems: ['3d_fighters', 'combat_animation', 'stamina', 'career', 'ranked'],
    ),
    AaaGameSpec(
      gameId: 'wars',
      camera: 'tactical',
      systems: ['3d_units', 'destruction', 'strategy_ai', 'territories', 'online_battles'],
    ),
    AaaGameSpec(
      gameId: 'samurai',
      camera: 'third-person',
      systems: ['3d_combat', 'parry', 'bosses', 'quests', 'online_duels'],
    ),
    AaaGameSpec(
      gameId: 'crime_files',
      camera: 'third-person / investigation',
      systems: ['3d_locations', 'evidence', 'npc_dialogue', 'branching_cases', 'co_op'],
    ),
    AaaGameSpec(
      gameId: 'zombies',
      camera: 'third-person / first-person',
      systems: ['3d_survival', 'enemy_ai', 'loot', 'crafting', 'co_op'],
    ),
    AaaGameSpec(
      gameId: 'pirates',
      camera: 'third-person / ship',
      systems: ['3d_ships', 'naval_combat', 'open_world', 'crew_ai', 'co_op'],
    ),
  ];

  static AaaGameSpec forGame(String id) {
    for (final spec in all) {
      if (spec.gameId == id) return spec;
    }
    return AaaGameSpec(
      gameId: id,
      systems: const ['3d_world', 'game_specific_rules', 'save_progress', 'online_ready'],
      qualityGates: const ['3d assets', 'animation', 'audio', 'mobile performance'],
    );
  }
}
