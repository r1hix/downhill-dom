class_name BikeController
extends CharacterBody3D

## Signals for gameplay systems (UI, combat, trick scoring)
signal airtime_started
signal airtime_ended(duration: float)
signal attack_triggered(side: String)
signal trick_performed(trick_name: String)

@export_group("Speed & Acceleration")
@export var base_speed: float = 12.0
@export var max_speed: float = 48.0
@export var acceleration: float = 18.0
@export var brake_deceleration: float = 28.0
@export var natural_drag: float = 2.0

@export_group("Slope & Gravity")
@export var base_gravity: float = 22.0
@export var slope_gravity_multiplier: float = 32.0
@export var ground_snap_force: float = 20.0
@export var slope_alignment_speed: float = 12.0

@export_group("Handling & Steering")
@export var turn_speed: float = 2.4
@export var max_lean_angle: float = 32.0 # Degrees
@export var lean_interpolation_speed: float = 9.0

@export_group("Jump & Airtime")
@export var jump_impulse: float = 14.0
@export var air_control_speed: float = 1.2
@export var air_gravity: float = 26.0

@export_group("Combat")
@export var attack_cooldown: float = 0.4
@export var attack_range: float = 2.5

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

func _ready() -> void:
	# Ensure the raycast exclusion and configuration
	if ground_ray:
		ground_ray.add_exception(self)
		ground_ray.enabled = true
	
	# Initial speed to kick off downhill descent
	current_forward_speed = base_speed

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_check_ground_contact(delta)
	_handle_combat_inputs()
	
	if is_grounded:
		_process_ground_physics(delta)
	else:
		_process_air_physics(delta)
	
	_handle_steering_and_lean(delta)
	move_and_slide()

## Timers & Cooldowns
func _update_timers(delta: float) -> void:
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0.0:
			can_attack = true

## Ground Contact & Airtime Detection
func _check_ground_contact(delta: float) -> void:
	var was_grounded: bool = is_grounded
	is_grounded = ground_ray.is_colliding()
	
	if is_grounded:
		ground_normal = ground_ray.get_collision_normal()
		if not was_grounded:
			# Just landed
			emit_signal("airtime_ended", air_time)
			air_time = 0.0
	else:
		ground_normal = Vector3.UP
		if was_grounded:
			# Just became airborne
			emit_signal("airtime_started")
		air_time += delta

## Ground Movement with Slope-Projected Artificial Gravity
func _process_ground_physics(delta: float) -> void:
	var bike_forward: Vector3 = -global_transform.basis.z.normalized()
	
	# Project forward vector onto the contact surface plane
	var slope_forward: Vector3 = (bike_forward - ground_normal * bike_forward.dot(ground_normal)).normalized()
	
	# Calculate downhill gravity pull along the slope
	# Vector3.DOWN projected onto the surface gives the steepest descent vector
	var downhill_vector: Vector3 = (Vector3.DOWN - ground_normal * Vector3.DOWN.dot(ground_normal))
	var downhill_component: float = downhill_vector.dot(slope_forward)
	
	# Accelerate / Brake input
	var accel_input: float = 0.0
	if Input.is_action_pressed("accelerate"):
		accel_input += 1.0
	if Input.is_action_pressed("brake"):
		accel_input -= 1.0
	
	# Drive speed calculation
	if accel_input > 0.0:
		current_forward_speed += acceleration * delta
	elif accel_input < 0.0:
		current_forward_speed -= brake_deceleration * delta
	else:
		current_forward_speed -= natural_drag * delta
	
	# Downhill slope acceleration: gravity pulls the bike faster down steep slopes
	current_forward_speed += downhill_component * slope_gravity_multiplier * delta
	current_forward_speed = clamp(current_forward_speed, 0.0, max_speed)
	
	# Calculate target velocity: slope forward velocity + snap force against surface
	var target_velocity: Vector3 = slope_forward * current_forward_speed
	# Apply artificial normal downforce to keep bike glued to the slope at high velocity
	target_velocity -= ground_normal * ground_snap_force
	
	# Handle Jump
	if Input.is_action_just_pressed("jump"):
		target_velocity += (ground_normal * 0.7 + Vector3.UP * 0.3).normalized() * jump_impulse
		is_grounded = false
	
	velocity = target_velocity
	
	# Align bike up-vector smoothly with ground normal
	_align_to_surface_normal(ground_normal, delta)

## Air Physics & Tricks
func _process_air_physics(delta: float) -> void:
	# Standard arcade airborne gravity
	velocity.y -= air_gravity * delta
	
	# Air drag on horizontal speed
	var horizontal_vel: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	current_forward_speed = horizontal_vel.length()
	
	# Trick modifier airborne actions
	if Input.is_action_pressed("trick_modifier"):
		if Input.is_action_just_pressed("attack_left"):
			emit_signal("trick_performed", "Tabletop Left")
		elif Input.is_action_just_pressed("attack_right"):
			emit_signal("trick_performed", "Tabletop Right")
		elif Input.is_action_just_pressed("jump"):
			emit_signal("trick_performed", "Tailwhip")
	
	# Slowly orient bike towards velocity direction while airborne
	if velocity.length_squared() > 1.0:
		var target_up: Vector3 = Vector3.UP
		_align_to_surface_normal(target_up, delta * 0.5)

## Steering & Mesh Banking / Lean
func _handle_steering_and_lean(delta: float) -> void:
	var steer_input: float = 0.0
	if Input.is_action_pressed("steer_left"):
		steer_input += 1.0
	if Input.is_action_pressed("steer_right"):
		steer_input -= 1.0
	
	var effective_turn_speed: float = turn_speed if is_grounded else (turn_speed * air_control_speed)
	
	# Yaw rotation around local Y axis
	if abs(steer_input) > 0.01:
		rotate_object_local(Vector3.UP, steer_input * effective_turn_speed * delta)
	
	# Banking / Roll Lean on the visual model
	var speed_ratio: float = clamp(current_forward_speed / max_speed, 0.25, 1.0)
	var target_lean_deg: float = -steer_input * max_lean_angle * speed_ratio
	var target_lean_rad: float = deg_to_rad(target_lean_deg)
	
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

## Combat Actions (Punches, Kicks)
func _handle_combat_inputs() -> void:
	if not can_attack:
		return
	
	if Input.is_action_just_pressed("attack_left") and not Input.is_action_pressed("trick_modifier"):
		_execute_attack("left")
	elif Input.is_action_just_pressed("attack_right") and not Input.is_action_pressed("trick_modifier"):
		_execute_attack("right")

func _execute_attack(side: String) -> void:
	can_attack = false
	attack_timer = attack_cooldown
	emit_signal("attack_triggered", side)
	
	# Perform proximity hit check for opponents
	var attack_dir: Vector3 = -global_transform.basis.x if side == "left" else global_transform.basis.x
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		global_position + Vector3.UP * 0.5 + attack_dir * attack_range
	)
	query.exclude = [get_rid()]
	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		var collider: Object = result.collider
		if collider and collider.has_method("take_hit"):
			collider.take_hit(attack_dir * 10.0)
