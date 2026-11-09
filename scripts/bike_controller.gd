class_name BikeController
extends CharacterBody3D

## High-speed arcade downhill bike controller with slope-projected physics,
## dynamic trauma-based camera juice, combat brawling sweeps, and adrenaline boost.

# Gameplay & UI Signals
signal airtime_started
signal airtime_ended(duration: float, was_clean: bool)
signal attack_triggered(side: String)
signal attack_hit(target: Node, side: String)
signal trick_performed(trick_name: String, points: int)
signal adrenaline_updated(current: float, max_value: float)
signal health_updated(current: float, max_value: float)
signal player_wiped_out
signal player_recovered

@export_group("Speed & Acceleration")
## Base minimum cruising speed when rolling downhill (m/s). Range: [5.0, 25.0]
@export var base_speed: float = 14.0
## Maximum natural downhill sprint speed without boost (m/s). Range: [30.0, 60.0]
@export var max_speed: float = 46.0
## Pedal acceleration applied when holding accelerate (m/s²). Range: [10.0, 35.0]
@export var acceleration: float = 22.0
## Braking deceleration rate when holding brake (m/s²). Range: [15.0, 50.0]
@export var brake_deceleration: float = 34.0
## Passive rolling air and mechanical drag deceleration (m/s²). Range: [0.5, 5.0]
@export var natural_drag: float = 1.8

@export_group("Adrenaline & Turbo Boost")
## Current adrenaline / boost energy. Range: [0.0, 100.0]
@export var max_adrenaline: float = 100.0
## Top speed multiplier attained while turbo boosting. Range: [1.2, 1.8]
@export var boost_speed_multiplier: float = 1.45
## Extra acceleration force during turbo boost (m/s²). Range: [20.0, 60.0]
@export var boost_acceleration: float = 38.0
## Depletion rate of adrenaline per second while boosting (units/s). Range: [10.0, 40.0]
@export var boost_depletion_rate: float = 24.0

@export_group("Slope & Gravity Physics")
## Base artificial downward gravity strength (m/s²). Range: [15.0, 40.0]
@export var base_gravity: float = 24.0
## Downhill acceleration scaling factor applied along steep surface gradients. Range: [20.0, 50.0]
@export var slope_gravity_multiplier: float = 36.0
## Artificial downforce pressing the bike against contact normals to prevent unintended launching. Range: [10.0, 35.0]
@export var ground_snap_force: float = 22.0
## Interpolation speed for slerping bike up-vector towards terrain surface normal. Range: [5.0, 20.0]
@export var slope_alignment_speed: float = 14.0

@export_group("Handling & Banking")
## Turn steering rate in radians per second. Range: [1.5, 4.0]
@export var turn_speed: float = 2.6
## Maximum visual banking lean angle on sharp turns (degrees). Range: [15.0, 45.0]
@export var max_lean_angle: float = 34.0
## Smoothing interpolation speed for banking lean roll transitions. Range: [5.0, 15.0]
@export var lean_interpolation_speed: float = 10.0

@export_group("Airtime & Jump")
## Vertical launch impulse applied on jump (m/s). Range: [8.0, 22.0]
@export var jump_impulse: float = 15.0
## Air steering authority multiplier relative to grounded turn speed. Range: [0.2, 1.0]
@export var air_control_speed: float = 0.75
## Gravity applied when airborne (m/s²). Range: [18.0, 35.0]
@export var air_gravity: float = 28.0

@export_group("Combat & Melee")
## Cooldown time between melee punches/kicks (seconds). Range: [0.2, 1.0]
@export var attack_cooldown: float = 0.35
## Effective reach of melee punch/kick sweeps (meters). Range: [1.5, 4.0]
@export var attack_range: float = 2.8
## Damage dealt to rival racers per melee hit. Range: [10.0, 50.0]
@export var attack_damage: float = 25.0
## Adrenaline rewarded on successful combat hit. Range: [10.0, 50.0]
@export var adrenaline_per_hit: float = 30.0

@export_group("Camera Juice & Feedback")
## Base field of view at low velocities (degrees). Range: [65.0, 85.0]
@export var camera_base_fov: float = 75.0
## Maximum field of view at terminal downhill velocity (degrees). Range: [85.0, 115.0]
@export var camera_max_fov: float = 98.0
## Field of view attained while turbo boosting (degrees). Range: [95.0, 120.0]
@export var camera_boost_fov: float = 108.0
## Rate of FOV interpolation (units/s). Range: [3.0, 12.0]
@export var fov_lerp_speed: float = 7.0
## Rate of trauma decay per second for camera shake. Range: [0.5, 3.0]
@export var trauma_decay: float = 1.6
## Maximum camera shake translation offset (meters). Range: [0.05, 0.4]
@export var max_shake_offset: float = 0.18
## Maximum camera shake rotation roll (degrees). Range: [1.0, 8.0]
@export var max_shake_angle: float = 3.5

# Node References
@onready var ground_ray: RayCast3D = $RayCast3D
@onready var visuals: Node3D = $Visuals
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

# Internal State
var current_forward_speed: float = 0.0
var is_grounded: bool = false
var ground_normal: Vector3 = Vector3.UP
var air_time: float = 0.0
var can_attack: bool = true
var attack_timer: float = 0.0
var current_lean: float = 0.0

# Adrenaline & Boost State
var adrenaline: float = 35.0
var is_boosting: bool = false

# Health & Wipeout State
var health: float = 100.0
var max_health: float = 100.0
var is_wiped_out: bool = false
var wipeout_timer: float = 0.0
var is_invulnerable: bool = false
var invulnerable_timer: float = 0.0

# Active Trick State
var current_trick: String = ""
var trick_timer: float = 0.0

# Camera Shake Trauma
var trauma: float = 0.0
var noise_time: float = 0.0
var camera_initial_pos: Vector3 = Vector3.ZERO
var camera_initial_rot: Vector3 = Vector3.ZERO

func _ready() -> void:
	if ground_ray:
		ground_ray.add_exception(self)
		ground_ray.enabled = true
	
	if camera:
		camera_initial_pos = camera.position
		camera_initial_rot = camera.rotation
	
	current_forward_speed = base_speed
	emit_signal("adrenaline_updated", adrenaline, max_adrenaline)
	emit_signal("health_updated", health, max_health)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	
	if is_wiped_out:
		_process_wipeout_state(delta)
		move_and_slide()
		_update_camera(delta)
		return
	
	_check_ground_contact(delta)
	_handle_boost_input(delta)
	_handle_combat_inputs()
	
	if is_grounded:
		_process_ground_physics(delta)
	else:
		_process_air_physics(delta)
	
	_handle_steering_and_lean(delta)
	move_and_slide()
	_update_camera(delta)

## Timers & Cooldown Maintenance
func _update_timers(delta: float) -> void:
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true
	
	if is_invulnerable:
		invulnerable_timer -= delta
		if invulnerable_timer <= 0.0:
			is_invulnerable = false
			if visuals:
				visuals.visible = true
		else:
			# Recovery flash effect
			if visuals:
				visuals.visible = int(Time.get_ticks_msec() / 80) % 2 == 0
	
	if trick_timer > 0.0:
		trick_timer -= delta
		if trick_timer <= 0.0:
			current_trick = ""

## Camera Shake & Dynamic FOV
func _update_camera(delta: float) -> void:
	if not camera:
		return
	
	# Dynamic FOV interpolation based on speed & boost
	var target_fov: float = camera_base_fov
	if is_boosting:
		target_fov = camera_boost_fov
	else:
		var speed_ratio: float = clamp(current_forward_speed / max_speed, 0.0, 1.0)
		target_fov = lerp(camera_base_fov, camera_max_fov, speed_ratio)
	
	camera.fov = lerp(camera.fov, target_fov, fov_lerp_speed * delta)
	
	# Trauma Camera Shake Calculation
	if trauma > 0.0:
		trauma = max(0.0, trauma - trauma_decay * delta)
		noise_time += delta * 30.0
		var shake_amount: float = trauma * trauma # Quadratic falloff
		
		var offset_x: float = sin(noise_time * 1.2) * max_shake_offset * shake_amount
		var offset_y: float = cos(noise_time * 1.5) * max_shake_offset * shake_amount
		var roll: float = deg_to_rad(sin(noise_time * 1.8) * max_shake_angle * shake_amount)
		
		camera.position = camera_initial_pos + Vector3(offset_x, offset_y, 0.0)
		camera.rotation = camera_initial_rot + Vector3(0.0, 0.0, roll)
	else:
		camera.position = camera.position.lerp(camera_initial_pos, 10.0 * delta)
		camera.rotation = camera.rotation.lerp(camera_initial_rot, 10.0 * delta)

## Adds screen shake trauma [0.0 - 1.0]
func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

## Ground Contact & Airtime
func _check_ground_contact(delta: float) -> void:
	var was_grounded: bool = is_grounded
	is_grounded = ground_ray.is_colliding()
	
	if is_grounded:
		ground_normal = ground_ray.get_collision_normal()
		if not was_grounded:
			# Landed from air
			var clean_landing: bool = current_trick == ""
			if not clean_landing:
				# Crashed while mid-trick!
				take_wipeout(air_time * 15.0)
			else:
				# Clean landing bonus
				var landing_points: int = int(air_time * 150.0)
				if air_time > 0.8:
					add_trauma(clamp(air_time * 0.25, 0.2, 0.6))
					_add_adrenaline(air_time * 15.0)
					if GameManager:
						GameManager.add_score(landing_points, "AIRTIME LANDING (%.1fs)" % air_time)
				emit_signal("airtime_ended", air_time, clean_landing)
			
			air_time = 0.0
			current_trick = ""
	else:
		ground_normal = Vector3.UP
		if was_grounded:
			emit_signal("airtime_started")
		air_time += delta

## Turbo Boost Mechanics
func _handle_boost_input(delta: float) -> void:
	var boost_requested: bool = Input.is_action_pressed("trick_modifier") and is_grounded
	if boost_requested and adrenaline > 1.0:
		is_boosting = true
		adrenaline = max(0.0, adrenaline - boost_depletion_rate * delta)
		emit_signal("adrenaline_updated", adrenaline, max_adrenaline)
		add_trauma(0.08 * delta) # Mild continuous rumble
	else:
		is_boosting = false

## Ground Movement with Slope-Projected Physics
func _process_ground_physics(delta: float) -> void:
	var bike_forward: Vector3 = -global_transform.basis.z.normalized()
	
	# Project forward vector onto surface normal plane
	var slope_forward: Vector3 = (bike_forward - ground_normal * bike_forward.dot(ground_normal)).normalized()
	
	# Steepest downhill descent projection
	var downhill_vector: Vector3 = (Vector3.DOWN - ground_normal * Vector3.DOWN.dot(ground_normal))
	var downhill_component: float = downhill_vector.dot(slope_forward)
	
	# User Acceleration / Brake
	var accel_input: float = 0.0
	if Input.is_action_pressed("accelerate"):
		accel_input += 1.0
	if Input.is_action_pressed("brake"):
		accel_input -= 1.0
	
	# Effective acceleration and max speed with boost
	var effective_max: float = max_speed * (boost_speed_multiplier if is_boosting else 1.0)
	var current_accel: float = (acceleration + boost_acceleration) if is_boosting else acceleration
	
	if accel_input > 0.0 or is_boosting:
		current_forward_speed += current_accel * delta
	elif accel_input < 0.0:
		current_forward_speed -= brake_deceleration * delta
	else:
		current_forward_speed -= natural_drag * delta
	
	# Downhill momentum
	current_forward_speed += downhill_component * slope_gravity_multiplier * delta
	current_forward_speed = clamp(current_forward_speed, 0.0, effective_max)
	
	# Target velocity along slope tangent + snap downforce
	var target_velocity: Vector3 = slope_forward * current_forward_speed
	target_velocity -= ground_normal * ground_snap_force
	
	# Handle Jump
	if Input.is_action_just_pressed("jump"):
		target_velocity += (ground_normal * 0.7 + Vector3.UP * 0.3).normalized() * jump_impulse
		is_grounded = false
		add_trauma(0.2)
	
	velocity = target_velocity
	_align_to_surface_normal(ground_normal, delta)

## Air Physics & Trick Execution
func _process_air_physics(delta: float) -> void:
	velocity.y -= air_gravity * delta
	
	var horizontal_vel: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	current_forward_speed = horizontal_vel.length()
	
	# Airborne Trick Combos
	if Input.is_action_pressed("trick_modifier"):
		if Input.is_action_just_pressed("attack_left") and current_trick == "":
			_trigger_trick("Tabletop Left", 250, 20.0, 0.6)
		elif Input.is_action_just_pressed("attack_right") and current_trick == "":
			_trigger_trick("Tabletop Right", 250, 20.0, 0.6)
		elif Input.is_action_just_pressed("jump") and current_trick == "":
			_trigger_trick("Tailwhip 360", 500, 35.0, 0.8)
		elif Input.is_action_just_pressed("accelerate") and current_trick == "":
			_trigger_trick("Superman", 400, 30.0, 0.75)
	
	# Align slowly to trajectory velocity while airborne
	if velocity.length_squared() > 1.0:
		_align_to_surface_normal(Vector3.UP, delta * 0.6)

func _trigger_trick(trick_name: String, points: int, adrenaline_gain: float, duration: float) -> void:
	current_trick = trick_name
	trick_timer = duration
	_add_adrenaline(adrenaline_gain)
	add_trauma(0.15)
	emit_signal("trick_performed", trick_name, points)
	if GameManager:
		GameManager.add_score(points, trick_name)

## Steering & Mesh Banking / Lean
func _handle_steering_and_lean(delta: float) -> void:
	var steer_input: float = 0.0
	if Input.is_action_pressed("steer_left"):
		steer_input += 1.0
	if Input.is_action_pressed("steer_right"):
		steer_input -= 1.0
	
	var effective_turn_speed: float = turn_speed if is_grounded else (turn_speed * air_control_speed)
	
	if abs(steer_input) > 0.01:
		rotate_object_local(Vector3.UP, steer_input * effective_turn_speed * delta)
	
	var speed_ratio: float = clamp(current_forward_speed / max_speed, 0.25, 1.0)
	var target_lean_rad: float = deg_to_rad(-steer_input * max_lean_angle * speed_ratio)
	
	current_lean = lerp_angle(current_lean, target_lean_rad, lean_interpolation_speed * delta)
	
	if visuals:
		visuals.rotation.z = current_lean

## Surface Normal Alignment
func _align_to_surface_normal(target_normal: Vector3, delta: float) -> void:
	var current_up: Vector3 = global_transform.basis.y
	var blended_up: Vector3 = current_up.lerp(target_normal, slope_alignment_speed * delta).normalized()
	
	var current_forward: Vector3 = -global_transform.basis.z
	var projected_forward: Vector3 = (current_forward - blended_up * current_forward.dot(blended_up)).normalized()
	
	if projected_forward.length_squared() > 0.001:
		var right: Vector3 = projected_forward.cross(blended_up).normalized()
		global_transform.basis = Basis(right, blended_up, -projected_forward)

## Combat Actions & Proximity Melee Sweeps
func _handle_combat_inputs() -> void:
	if not can_attack or is_wiped_out:
		return
	
	if Input.is_action_just_pressed("attack_left") and not Input.is_action_pressed("trick_modifier"):
		_execute_attack("left")
	elif Input.is_action_just_pressed("attack_right") and not Input.is_action_pressed("trick_modifier"):
		_execute_attack("right")

func _execute_attack(side: String) -> void:
	can_attack = false
	attack_timer = attack_cooldown
	emit_signal("attack_triggered", side)
	
	# Animate visual fist punch if present
	_play_punch_animation(side)
	
	# Proximity melee hit query
	var attack_dir: Vector3 = -global_transform.basis.x if side == "left" else global_transform.basis.x
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.6,
		global_position + Vector3.UP * 0.6 + attack_dir * attack_range
	)
	query.exclude = [get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	
	if result:
		var collider: Object = result.collider
		if collider and collider.has_method("take_hit"):
			collider.take_hit(attack_dir * 18.0, attack_damage, self)
			_add_adrenaline(adrenaline_per_hit)
			add_trauma(0.35)
			emit_signal("attack_hit", collider, side)
			if GameManager:
				GameManager.add_score(150, "COMBAT PUNCH HIT!")

func _play_punch_animation(side: String) -> void:
	var fist: Node3D = visuals.get_node_or_null("LeftFist" if side == "left" else "RightFist")
	if fist:
		var tween: Tween = create_tween()
		var start_pos: Vector3 = fist.position
		var punch_offset: Vector3 = Vector3(-0.75 if side == "left" else 0.75, 0.15, -0.2)
		tween.tween_property(fist, "position", start_pos + punch_offset, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(fist, "position", start_pos, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

## Health & Wipeout System
func take_hit(impact_force: Vector3, damage: float, attacker: Node = null) -> void:
	if is_invulnerable or is_wiped_out:
		return
	
	health = max(0.0, health - damage)
	emit_signal("health_updated", health, max_health)
	add_trauma(0.5)
	
	# Push bike from impact
	velocity += impact_force
	current_forward_speed = max(5.0, current_forward_speed - 8.0)
	
	if health <= 0.0:
		take_wipeout(damage)

func take_wipeout(_penalty: float = 0.0) -> void:
	if is_wiped_out:
		return
	
	is_wiped_out = true
	wipeout_timer = 1.6
	current_forward_speed = 0.0
	velocity = Vector3(randf_range(-4, 4), 6.0, randf_range(-4, 4))
	add_trauma(0.8)
	emit_signal("player_wiped_out")

func _process_wipeout_state(delta: float) -> void:
	velocity.y -= air_gravity * delta
	velocity.x = lerp(velocity.x, 0.0, 3.0 * delta)
	velocity.z = lerp(velocity.z, 0.0, 3.0 * delta)
	
	# Tumble bike visuals
	if visuals:
		visuals.rotate_x(8.0 * delta)
		visuals.rotate_z(6.0 * delta)
	
	wipeout_timer -= delta
	if wipeout_timer <= 0.0:
		_recover_from_wipeout()

func _recover_from_wipeout() -> void:
	is_wiped_out = false
	health = 60.0
	current_forward_speed = base_speed
	is_invulnerable = true
	invulnerable_timer = 2.0
	if visuals:
		visuals.rotation = Vector3.ZERO
	emit_signal("health_updated", health, max_health)
	emit_signal("player_recovered")

func _add_adrenaline(amount: float) -> void:
	adrenaline = clamp(adrenaline + amount, 0.0, max_adrenaline)
	emit_signal("adrenaline_updated", adrenaline, max_adrenaline)
