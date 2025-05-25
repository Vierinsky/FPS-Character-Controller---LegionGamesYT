extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.001

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8


@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x,deg_to_rad(-90), deg_to_rad(90)) # Modifiqué a -90 y a 90

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back") # Saqué "up"
	
	# El siguiente bloque de código lo modifique por mi cuenta. Sin seguir el tutorial: 
	
	# var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var cam_basis = head.global_transform.basis
	var direction = (cam_basis.x * input_dir.x + cam_basis.z * input_dir.y).normalized()
	
	# Hasta aqui llega mi modificación
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
