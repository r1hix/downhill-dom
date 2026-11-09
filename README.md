# Downhill Domination

A high-speed arcade downhill bike combat game built in Godot 4 — a spiritual successor to the PS2 classic *Downhill Domination*.

Blistering downhill momentum, steep mountain drops, responsive arcade slope-physics, proximity melee brawling, and airborne trick combos.

---

## Features

- **Slope-Projected Arcade Physics**: Downhill gravity vectors are projected onto terrain surface normals via downward raycasting, allowing bikes to maintain blistering speed and traction down 40-degree mountain descents.
- **Dynamic Camera Juice**: Speed-sensitive FOV expansion (up to 108°), camera trailing, and quadratic trauma-based screen shake on high-impact landings and combat hits.
- **Proximity Combat System**: Fast left and right melee punches/kicks (`attack_left`, `attack_right`) with directional hitboxes to stagger and wipe out rival riders.
- **Airborne Stunt & Trick Combos**: Launch off ramps and pull off Tabletops, Supermans, and Tailwhips with the `trick_modifier` key to earn score and boost adrenaline.
- **Adrenaline Turbo Boost**: Fill the boost meter with combat hits and clean stunts to unleash extreme straight-line rocket speed.
- **60 Hz Fixed Physics**: Configured for high-velocity collision stability.

---

## Controls

| Action | Primary Key | Secondary / Mouse |
| :--- | :--- | :--- |
| **Accelerate / Pedal** | `W` | `Up Arrow` |
| **Brake / Reverse** | `S` | `Down Arrow` |
| **Steer Left** | `A` | `Left Arrow` |
| **Steer Right** | `D` | `Right Arrow` |
| **Jump / Bunnyhop** | `Space` | — |
| **Attack Left** | `Q` | `Left Mouse Button` |
| **Attack Right** | `E` | `Right Mouse Button` |
| **Turbo Boost / Trick Modifier** | `Shift` (hold) | — |

---

## Getting Started

### Prerequisites
- [Godot Engine 4.3+](https://godotengine.org/) (tested on Godot 4.7.2)
- [Blender](https://www.blender.org/) (for 3D asset modeling and pipeline)

### Running the Game

```bash
# Clone the repository
git clone https://github.com/r1hix/downhill-dom.git
cd downhill-dom

# Launch in Godot Editor
godot -e

# Or launch directly into the test track
godot
```

---

## Project Structure

```
downhill-dom/
├── AGENTS.md                  # Development guidelines and agent rules
├── README.md                  # Project overview and controls
├── project.godot              # Godot 4 engine configuration (60 Hz physics, 1080p, inputs)
├── assets/                    # 3D models, textures, audio, shaders
├── docs/
│   └── architecture.md        # Technical physics, combat, and camera architecture
├── scenes/
│   ├── levels/                # Tracks and downhill environments
│   │   └── test_track.tscn    # 40-degree downward 200m ramp test course
│   ├── opponents/             # AI rivals and combatants
│   ├── player/                # Player bike, rider models, and rigs
│   │   └── player_bike.tscn   # CharacterBody3D bike with camera & raycast
│   ├── ui/                    # HUD, speedometer, boost gauge, trick notifications
│   ├── player_bike.tscn
│   └── test_track.tscn
└── scripts/
    ├── autoloads/
    │   └── game_manager.gd    # Race state, scoring, and global event bus
    ├── combat/                # Melee hitboxes, projectiles, and damage models
    ├── player/
    │   └── bike_controller.gd # Slope physics, camera shake, steering lean, boost
    ├── terrain/               # Surface normal projection and track tools
    └── bike_controller.gd
```

---

## License

MIT License. See project files for details.
