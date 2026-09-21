extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var yaw := 0.0
var pitch := -12.0
var move_input := Vector2.ZERO
var joystick_touch := -1
var look_touch := -1
var last_look := Vector2.ZERO
var sprint := false
var status_label: Label

func _ready() -> void:
    _build_world()
    _build_player()
    _build_ui()

func _build_world() -> void:
    var env := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.025, 0.035, 0.045)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.45, 0.50, 0.58)
    environment.ambient_light_energy = 0.65
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.environment = environment
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_energy = 1.0
    sun.shadow_enabled = true
    add_child(sun)

    var ground := StaticBody3D.new()
    ground.name = "Ground"
    add_child(ground)

    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(80, 0.4, 80)
    mesh.mesh = box
    mesh.position.y = -0.2
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.12, 0.16, 0.12)
    mat.roughness = 1.0
    mesh.material_override = mat
    ground.add_child(mesh)

    var shape := CollisionShape3D.new()
    var collision := BoxShape3D.new()
    collision.size = Vector3(80, 0.4, 80)
    shape.shape = collision
    shape.position.y = -0.2
    ground.add_child(shape)

    for p in [Vector3(8,0,5), Vector3(-10,0,-6), Vector3(15,0,-12), Vector3(-18,0,12)]:
        _make_ruin(p)

func _make_ruin(pos: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    add_child(body)
    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(4, 3, 3)
    mesh.mesh = box
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.20, 0.22, 0.23)
    mat.roughness = 0.9
    mesh.material_override = mat
    body.add_child(mesh)
    var shape := CollisionShape3D.new()
    var cs := BoxShape3D.new()
    cs.size = Vector3(4, 3, 3)
    shape.shape = cs
    body.add_child(shape)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1.2, 10)
    add_child(player)

    var capsule := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    capsule.shape = capsule_shape
    capsule.position.y = 0.9
    player.add_child(capsule)

    var body_mesh := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.45
    capsule_mesh.height = 1.8
    body_mesh.mesh = capsule_mesh
    body_mesh.position.y = 0.9
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.18, 0.48, 0.32)
    body_mesh.material_override = mat
    player.add_child(body_mesh)

    var pivot := Node3D.new()
    pivot.name = "CameraPivot"
    pivot.position = Vector3(0, 1.45, 0)
    player.add_child(pivot)

    camera = Camera3D.new()
    camera.position = Vector3(0, 1.5, 5.5)
    camera.rotation_degrees.x = 0
    camera.current = true
    pivot.add_child(camera)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    status_label = Label.new()
    status_label.text = "PROJECT Z  •  DAY 1\\nHP 100   |   STAMINA 100\\nV0.1 FOUNDATION"
    status_label.position = Vector2(28, 24)
    status_label.add_theme_font_size_override("font_size", 24)
    layer.add_child(status_label)

    var help := Label.new()
    help.text = "MOVE: WASD / LEFT STICK     LOOK: SWIPE RIGHT     SPRINT: SHIFT"
    help.position = Vector2(28, 660)
    help.add_theme_font_size_override("font_size", 18)
    layer.add_child(help)

    var sprint_button := Button.new()
    sprint_button.text = "SPRINT"
    sprint_button.position = Vector2(1080, 570)
    sprint_button.size = Vector2(150, 70)
    sprint_button.button_down.connect(func(): sprint = true)
    sprint_button.button_up.connect(func(): sprint = false)
    layer.add_child(sprint_button)

func _physics_process(delta: float) -> void:
    if not player:
        return

    var keyboard := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var input_vec := keyboard
    if move_input.length() > 0.1:
        input_vec = move_input

    var basis := player.global_transform.basis
    var direction := (basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
    var speed := 7.0 if sprint or Input.is_action_pressed("sprint") else 4.0
    player.velocity.x = direction.x * speed
    player.velocity.z = direction.z * speed
    player.velocity.y -= 20.0 * delta
    player.move_and_slide()

    if player.position.y < -5:
        player.position = Vector3(0, 2, 10)
        player.velocity = Vector3.ZERO

    status_label.text = "PROJECT Z  •  DAY 1\\nHP 100   |   STAMINA %d\\nV0.1 FOUNDATION" % int(100.0 if speed > 5 else 82.0)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            if event.position.x < get_viewport().size.x * 0.45 and joystick_touch == -1:
                joystick_touch = event.index
                move_input = Vector2.ZERO
            elif look_touch == -1:
                look_touch = event.index
                last_look = event.position
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                move_input = Vector2.ZERO
            if event.index == look_touch:
                look_touch = -1

    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            var center := Vector2(150, get_viewport().size.y - 150)
            move_input = (event.position - center) / 100.0
            move_input = move_input.limit_length(1.0)
        elif event.index == look_touch:
            var delta := event.position - last_look
            last_look = event.position
            player.rotate_y(-delta.x * 0.004)
            pitch = clamp(pitch - delta.y * 0.15, -45.0, 35.0)
            camera.rotation_degrees.x = pitch
