extends CharacterBody2D

enum State {
	IDLE,
	RUNNING,
	JUMP,
	FALL,
}

const GROUND_STATE := [State.IDLE, State.RUNNING]

const RUN_SPEED := 160.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.2 # 0~RunSpeed needs 0.2s
const AIR_ACCELERATION := RUN_SPEED / 0.02 # 0~RunSpeed needs 0.2s
const JUMP_VELOCITY := -320.0 # In 2D - Y direction, jump up means -XXX

var gravity := ProjectSettings.get("physics/2d/default_gravity") as float

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_VELOCITY / 2:
			velocity.y = JUMP_VELOCITY / 2	

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(delta)
		
		State.RUNNING:
			move(delta)
			
		State.JUMP:
			move(delta)
			
		State.FALL:
			move(delta)
	
func move(delta: float)	-> void:
	var direction := Input.get_axis("move_left", "move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x = move_toward(velocity.x, direction * RUN_SPEED, acceleration * delta)
	velocity.y += gravity * delta

	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
	
	move_and_slide()
	
			
func get_next_state(state: State) -> State:
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var shouldJump := can_jump and jump_request_timer.time_left > 0
	if shouldJump:
		return State.JUMP
	
	var direction := Input.get_axis("move_left", "move_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	
	match state:
		State.IDLE:
			if not is_on_floor():
				return State.FALL
			
			if not is_still:
				return State.RUNNING
		
		State.RUNNING:
			if not is_on_floor():
				return State.FALL
			if is_still:
				return State.IDLE
			
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			if is_on_floor():
				return State.IDLE if is_still else State.RUNNING
		
	return state
	
func transition_state(from: State, to: State) -> void:
	if from not in GROUND_STATE and to in GROUND_STATE:
		coyote_timer.stop()
		
	
	match to:
		State.IDLE:
			animation_player.play("idle")
		
		State.RUNNING:
			animation_player.play("running")
			
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
			
		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATE:
				coyote_timer.start()
