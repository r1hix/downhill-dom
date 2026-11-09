# Downhill Domination - Technical Architecture

A high-speed arcade downhill mountain bike combat game built in Godot 4, inspired by *Downhill Domination*.

---

## 1. Core Physics & Slope Projection

### Slope-Projected Artificial Gravity
Standard Newtonian physics treats gravity as a vertical downward vector $\vec{g} = (0, -g, 0)$, which causes high-velocity bikes on steep $40^\circ$ slopes to skip, ramp off micro-crests unintentionally, or lose traction.

Our system models downhill momentum through surface tangent projection:
1. **Raycast Surface Sampling**:
   - A downward `RayCast3D` (length: 1.2m, local origin $y = 0.5\text{m}$) casts from the bike center towards the ground.
   - Extracts the contact surface normal $\hat{N}$.
2. **Tangent Velocity Projection**:
   - The vehicle heading $\vec{V}_{\text{forward}} = -\text{transform.basis.z}$ is projected onto the contact plane:
     $$\vec{T}_{\text{slope}} = \text{normalize}\left(\vec{V}_{\text{forward}} - \hat{N} (\vec{V}_{\text{forward}} \cdot \hat{N})\right)$$
3. **Downhill Slope Momentum**:
   - World gravity $\vec{g} = (0, -1, 0)$ is projected along the surface tangent:
     $$\vec{G}_{\text{downhill}} = \vec{g} - \hat{N} (\vec{g} \cdot \hat{N})$$
   - Forward acceleration scales directly with the downhill dot product:
     $$a_{\text{slope}} = (\vec{G}_{\text{downhill}} \cdot \vec{T}_{\text{slope}}) \times \text{slope\_gravity\_multiplier}$$
4. **Normal Ground Clamping**:
   - Artificial downforce is applied opposite to the surface normal ($-\hat{N} \times \text{ground\_snap\_force}$) to keep the tires glued to the slope at extreme speeds ($> 45\text{ m/s}$ / $160\text{ km/h}$).

---

## 2. Dynamic Camera & Sensory Juice

- **Dynamic Velocity FOV**:
  - FOV scales continuously from base ($75^\circ$) to terminal velocity ($98^\circ$), jumping to $108^\circ$ during Turbo Boost.
- **Trauma-Based Screen Shake**:
  - Non-linear camera shake using quadratic trauma falloff ($\text{shake} = \text{trauma}^2$).
  - Triggered on hard landings, combat punches/kicks, jump takeoff, and wipeouts.

---

## 3. Combat & Proximity Brawling

- **Directional Melee Attacks**:
  - Left / Right punch/kick triggers (`attack_left`, `attack_right`).
  - Queries physics direct space state using directional sweeps ($2.8\text{m}$ range).
- **Impact Reactions**:
  - Deals damage, applies impulse vector, rewards +30 Adrenaline, and adds camera trauma.
  - Knockdowns occur when rival health depletes to zero.

---

## 4. Airtime & Trick Combo System

- **Airborne Detection**:
  - Raycast loss-of-contact triggers airborne state and timer.
- **Trick Combinations**:
  - Holding `trick_modifier` (Shift) while pressing combat or jump buttons initiates airborne stunts (Tabletop, Superman, Tailwhip 360).
  - Rewards Adrenaline and score.
  - Requires clean landing; landing mid-trick induces a wipeout.

---

## 5. Controls & Input Mapping

| Action | Primary Key | Secondary / Mouse |
| :--- | :--- | :--- |
| `accelerate` | `W` | `Up Arrow` |
| `brake` | `S` | `Down Arrow` |
| `steer_left` | `A` | `Left Arrow` |
| `steer_right` | `D` | `Right Arrow` |
| `attack_left` | `Q` | `Left Mouse Button` |
| `attack_right` | `E` | `Right Mouse Button` |
| `trick_modifier` / `boost` | `Shift` | — |
| `jump` | `Space` | — |
