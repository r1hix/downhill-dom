# AGENTS.md

Arcade downhill mountain-bike combat game in Godot 4 (spiritual successor to *Downhill Domination*).
Pillars: blistering downhill momentum, slope-projected arcade physics, close-range combat (punches, kicks, thrown items), early-2000s low-poly look.

## Stack
- Godot 4.7.2 stable, GDScript with static typing.
- Physics: Jolt (`physics/3d/physics_engine` in Project Settings).
- Assets: headless Blender scripts in `tools/blender/` -> `.glb` in `assets/`.

## Commands
Fill in / adjust to match the repo; keep this list accurate.
```bash
godot --headless --import                              # re-import assets
godot --headless --check-only --script res://<file>.gd # syntax-check a script
godot --headless --quit-after 120 res://scenes/main.tscn  # boot smoke test
# Tests (if present): gdUnit4 / GUT command here
```

## Definition of Done (before ending any turn)
1. Project imports and the main scene boots headless with no new errors or warnings.
2. Tests pass (or a test scene was run) for anything touched.
3. `docs/architecture.md` updated if a gameplay system changed.
4. No dead code, unused files, or stray temp files left behind.

## Git
- Never commit to `main`. One branch per task, cut from an up-to-date `main` (`git checkout main && git pull origin main`).
- Branch names: `feat/`, `fix/`, `refactor/`, `assets/` + kebab-case.
- Conventional commits, atomic: `feat | fix | perf | docs | chore | refactor | test`.
- Merging = Pull Request only. Never run `git merge <branch>` into `main` locally, and never merge a PR unless told to.
  ```bash
  git push -u origin <branch>
  gh pr create --base main --head <branch> --title "<title>" --body "<changes + how tested>"
  ```
  Reply with the PR link and a short checklist of what was verified.
- **Ask first:** pushing to `origin main`, `git push --force`, `git reset --hard`, deleting branches, rewriting history.
- Do not commit `.godot/`, build output, or large binaries outside Git LFS (if used).

## Architecture Rules
- Move the bike along the terrain surface normal (slope-projected), not with plain top-down gravity.
- Arcade feel over realism: no Newtonian two-wheel bicycle simulation.
- Keep the scene tree modular: `CharacterBody3D` controller at root; Rider and Bike frame are separate child scenes.
- Terrain collision: trimesh/convex shapes or a 16-bit heightmap. No high-poly collision meshes.
- Never instantiate or free nodes inside `_physics_process()`. Pool or pre-instantiate transient entities (projectiles, impact particles, sparks).
- Use signals for cross-system communication; avoid hard-coded node paths between systems.

## Code Style
- Static types everywhere (`var speed: float`, typed function returns).
- Every `@export` has an `@export_group` and a `##` doc comment with valid range and gameplay effect.
- No commented-out code. Delete unused `.tscn`, `.gd`, `.blend`, and render dumps in the same change.

## Docs
- `docs/architecture.md`: state machines, combat sweeps, suspension/raycast constants. Keep current.
- `assets/README.md`: every new model, texture, and sound with source and license.

## Legal
- No proprietary or extracted assets (including from *Downhill Domination*/Sony) and no copyrighted audio. Only original or clearly licensed (CC0/CC-BY) assets, recorded in `assets/README.md`.