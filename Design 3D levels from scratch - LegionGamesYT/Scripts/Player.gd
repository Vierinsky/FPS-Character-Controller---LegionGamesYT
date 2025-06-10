extends CharacterBody3D

# Velocidad actual del jugador (puede ser caminar o sprint)
var speed

# Constantes para movimiento y sensibilidad del mouse
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.8
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.001

# Variables para el efecto de head bob (oscilación de la cámara al caminar)
const BOB_FREQ = 2.0       # Frecuencia del head bob (más alto = más rápido)
const BOB_AMP = 0.08       # Amplitud del movimiento del head bob
var t_bob = 0.0            # Tiempo acumulado para calcular la fase del bob

# Variables para la modificación dinámica del FOV (campo de visión)
const BASE_FOV = 75.0      # FOV base de la cámara
const FOV_CHANGE = 1.5     # Cuánto se expande el FOV al correr

# Gravedad que se aplica al personaje
var gravity = 9.8

# Referencias a nodos del jugador (cabeza y cámara)
@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	# Oculta y bloquea el cursor dentro de la ventana del juego
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Control de cámara con el movimiento del mouse
	if event is InputEventMouseMotion:
		# Rota la cabeza del personaje horizontalmente (izquierda/derecha)
		head.rotate_y(-event.relative.x * SENSITIVITY)
		# Rota la cámara verticalmente (arriba/abajo)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		# Limita la rotación vertical para no mirar completamente hacia atrás
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	# Aplica gravedad si no está en el suelo
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Salto si se presiona la tecla correspondiente y está en el suelo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Cambia la velocidad entre caminar y correr según la tecla "sprint"
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Obtiene el vector de entrada del jugador según las teclas de movimiento
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	# Obtiene la dirección del movimiento con respecto a la cámara
	var cam_basis = head.global_transform.basis
	var direction = (cam_basis.x * input_dir.x + cam_basis.z * input_dir.y).normalized()

	# Aplica movimiento con o sin inercia según si el jugador está en el suelo o en el aire
	if is_on_floor():
		if direction:
			# Movimiento directo si se está presionando una dirección
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# Si no se presiona ninguna dirección, interpola hacia 0 para frenar suavemente (inercia)
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		# En el aire, el movimiento es más suave (menor control)
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Calcula el efecto de head bob si el jugador se está moviendo en el suelo
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)

	# Modifica el FOV solo si se está haciendo sprint y hay dirección
	var target_fov = BASE_FOV
	if Input.is_action_pressed("sprint") and direction:
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		target_fov += FOV_CHANGE * velocity_clamped

	# Interpola suavemente el FOV hacia el objetivo
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	# Aplica el movimiento al cuerpo del jugador
	move_and_slide()

func _headbob(time) -> Vector3:
	# Función que devuelve un Vector3 para mover la cámara oscilando (head bob)
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP          # Movimiento vertical
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP      # Movimiento lateral
	return pos
