extends Node3D

# PROJECT Z - V0.1 Foundation
# Self-contained runtime scene: no external assets or Input Map actions required.

var player: CharacterBody3D
var camera: Camera3D
var status_label: Label
var joystick_base: Control
var joystick_knob: Control

var move_input := Vector2.ZERO
var joystick_touch := -1
var look_touch := -1
var joystick_center := Vector2.ZERO
var last_look := Vector2.ZERO
var sprint := false
var yaw := 0.0
var pitch := -10.0
var stamina := 100.0

const WALK_SPEED := 4.0
const SPRINT_SPEED := 7.0
const GRAVITY := 20.0
const LOOK_SENSITIVITY := 0.006

func _ready() -> void:
    _build_world()
    _build_player()
    _build_ui()
    _update_camera()

func _build_world() -> void:
    var world_environment := WorldEnvironment.new()
    world_environment.name = "WorldEnvironment"

    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.025, 0.035, 0.05)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.55, 0.60, 0.68)
    environment.ambient_light_energy = 0.8
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world_environment.environment = environment
    add_child(world_environment)

    var sun := DirectionalLight3D.new()
    sun.name = "Sun"
    sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
    sun.light_energy = 1.2
    sun.shadow_enabled = true
    add_child(sun)

    _make_ground()

    var ruins := [
        Vector3(8, 0, 5),
        Vector3(-10, 0, -6),
        Vector3(15, 0, -12),
        Vector3(-18, 0, 12),
        Vector3(4, 0, -18),
        Vector3(-20, 0, -15)
    ]

    for position in ruins:
        _make_ruin(position)

    _make_road(Vector3(0, 0.015, -2), Vector3(4, 0.03, 60))
    _make_road(Vector3(0, 0.02, 0), Vector3(60, 0.03, 4))

func _make_ground() -> void:
    var ground := StaticBody3D.new()
    ground.name = "Ground"
    add_child(ground)

    var mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(80, 0.4, 80)
    mesh.mesh = box
    mesh.position.y = -0.2

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.11, 0.14, 0.11)
    material.roughness = 1.0
    mesh.material_override = material
    ground.add_child(mesh)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(80, 0.4, 80)
    collision.shape = shape
    collision.position.y = -0.2
    ground.add_child(collision)

func _make_road(position: Vector3, size: Vector3) -> void:
    var road := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = size
    road.mesh = box
    road.position = position

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.09, 0.09, 0.085)
    material.roughness = 0.95
    road.material_override = material
    add_child(road)

func _make_ruin(position: Vector3) -> void:
    var body := StaticBody3D.new()
    body.name = "Ruin"
    body.position = position
    add_child(body)

    var building := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(4.0, 3.0, 3.0)
    building.mesh = box

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.20, 0.22, 0.23)
    material.roughness = 0.9
    building.material_override = material
    body.add_child(building)

    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(4.0, 3.0, 3.0)
    collision.shape = shape
    body.add_child(collision)

    # Simple roof slab for a ruined/industrial look.
    var roof := MeshInstance3D.new()
    var roof_box := BoxMesh.new()
    roof_box.size = Vector3(4.5, 0.25, 3.5)
    roof.mesh = roof_box
    roof.position = Vector3(0, 1.6, 0)
    var roof_material := StandardMaterial3D.new()
    roof_material.albedo_color = Color(0.14, 0.15, 0.15)
    roof_material.roughness = 1.0
    roof.material_override = roof_material
    body.add_child(roof)

func _build_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    player.position = Vector3(0, 1.0, 10)
    add_child(player)

    var collision := CollisionShape3D.new()
    var capsule_shape := CapsuleShape3D.new()
    capsule_shape.radius = 0.45
    capsule_shape.height = 1.8
    collision.shape = capsule_shape
    collision.position.y = 0.9
    player.add_child(collision)

    var body_mesh := MeshInstance3D.new()
    var capsule_mesh := CapsuleMesh.new()
    capsule_mesh.radius = 0.45
    capsule_mesh.height = 1.8
    body_mesh.mesh = capsule_mesh
    body_mesh.position.y = 0.9

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(0.16, 0.48, 0.30)
    material.roughness = 0.75
    body_mesh.material_override = material
    player.add_child(body_mesh)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.38
    head_mesh.height = 0.76
    head.mesh = head_mesh
    head.position = Vector3(0, 2.05, 0)
    var head_material := StandardMaterial3D.new()
    head_material.albedo_color = Color(0.55, 0.38, 0.28)
    head.material_override = head_material
    player.add_child(head)

    var camera_pivot := Node3D.new()
    camera_pivot.name = "CameraPivot"
    camera_pivot.position = Vector3(0, 1.45, 0)
    player.add_child(camera_pivot)

    camera = Camera3D.new()
    camera.name = "ThirdPersonCamera"
    camera.position = Vector3(0, 1.4, 6.0)
    camera.rotation_degrees = Vector3(pitch, 0.0, 0.0)
    camera.current = true
    camera.fov = 70.0
    camera_pivot.add_child(camera)

func _build_ui() -> void:
    var layer := CanvasLayer.new()
    layer.name = "HUD"
    add_child(layer)

    var top_panel := ColorRect.new()
    top_panel.position = Vector2(18, 18)
    top_panel.size = Vector2(330, 112)
    top_panel.color = Color(0.02, 0.03, 0.04, 0.82)
    layer.add_child(top_panel)

    status_label = Label.new()
    status_label.position = Vector2(16, 12)
    status_label.add_theme_font_size_override("font_size", 20)
    top_panel.add_child(status_label)

    var hint := Label.new()
    hint.text = "LEFT: MOVE     RIGHT: LOOK\nSPRINT: BUTTON / SHIFT"
    hint.position = Vector2(18, 138)
    hint.add_theme_font_size_override("font_size", 15)
    hint.modulate = Color(0.85, 0.88, 0.92, 0.85)
    layer.add_child(hint)

    # Responsive virtual joystick.
    joystick_base = ColorRect.new()
    joystick_base.name = "JoystickBase"
    joystick_base.position = Vector2(42, 0)
    joystick_base.size = Vector2(130, 130)
    joystick_base.color = Color(0.08, 0.10, 0.12, 0.55)
    joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(joystick_base)

    joystick_knob = ColorRect.new()
    joystick_knob.name = "JoystickKnob"
    joystick_knob.size = Vector2(58, 58)
    joystick_knob.color = Color(0.35, 0.55, 0.42, 0.75)
    joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(joystick_knob)

    _position_joystick(get_viewport().size)

    var sprint_button := Button.new()
    sprint_button.name = "SprintButton"
    sprint_button.text = "SPRINT"
    sprint_button.position = Vector2(0, 0)
    sprint_button.size = Vector2(155, 70)
    sprint_button.add_theme_font_size_override("font_size", 20)
    layer.add_child(sprint_button)
    sprint_button.button_down.connect(_on_sprint_down)
    sprint_button.button_up.connect(_on_sprint_up)

    _position_sprint_button(sprint_button, get_viewport().size)

    get_viewport().size_changed.connect(func():
        _position_joystick(get_viewport().size)
        _position_sprint_button(sprint_button, get_viewport().size)
    )

func _position_joystick(viewport_size: Vector2) -> void:
    joystick_center = Vector2(125, viewport_size.y - 125)
    joystick_base.position = joystick_center - joystick_base.size * 0.5
    joystick_knob.position = joystick_center - joystick_knob.size * 0.5

func _position_sprint_button(button: Button, viewport_size: Vector2) -> void:
    button.position = Vector2(viewport_size.x - 185, viewport_size.y - 125)

func _on_sprint_down() -> void:
    sprint = true

func _on_sprint_up() -> void:
    sprint = false

func _physics_process(delta: float) -> void:
    if player == null:
        return

    var keyboard_input := Vector2.ZERO

    if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        keyboard_input.x -= 1.0
    if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        keyboard_input.x += 1.0
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        keyboard_input.y -= 1.0
    if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        keyboard_input.y += 1.0

    if keyboard_input.length() > 1.0:
        keyboard_input = keyboard_input.normalized()

    var input_vector := move_input
    if keyboard_input.length() > 0.01:
        input_vector = keyboard_input

    var is_sprinting := sprint or Input.is_key_pressed(KEY_SHIFT)
    var speed := SPRINT_SPEED if is_sprinting else WALK_SPEED

    var direction := Vector3(input_vector.x, 0.0, input_vector.y)
    direction = direction.rotated(Vector3.UP, player.rotation.y)

    if direction.length() > 0.01:
        direction = direction.normalized()

    player.velocity.x = direction.x * speed
    player.velocity.z = direction.z * speed

    if not player.is_on_floor():
        player.velocity.y -= GRAVITY * delta
    else:
        player.velocity.y = 0.0

    player.move_and_slide()

    if player.position.y < -5.0:
        player.position = Vector3(0, 1.0, 10)
        player.velocity = Vector3.ZERO

    if is_sprinting and input_vector.length() > 0.1:
        stamina = max(0.0, stamina - 18.0 * delta)
        if stamina <= 0.0:
            sprint = false
    else:
        stamina = min(100.0, stamina + 12.0 * delta)

    _update_camera()
    _update_hud(is_sprinting)

func _update_camera() -> void:
    if camera == null:
        return

    camera.rotation_degrees.x = pitch
    camera.rotation_degrees.y = 0.0

func _update_hud(is_sprinting: bool) -> void:
    if status_label == null:
        return

    var state := "SPRINTING" if is_sprinting else "SURVIVING"
    status_label.text = "PROJECT Z  •  DAY 1\nHP 100   |   STAMINA %d\n%s  •  V0.1 FOUNDATION" % [int(stamina), state]

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            var viewport_width := get_viewport().size.x

            if event.position.x < viewport_width * 0.45 and joystick_touch == -1:
                joystick_touch = event.index
                joystick_center = event.position
                joystick_center.x = clamp(joystick_center.x, 80.0, viewport_width * 0.40)
                joystick_center.y = clamp(joystick_center.y, 80.0, get_viewport().size.y - 80.0)
                _move_joystick_visual()
                move_input = Vector2.ZERO
            elif look_touch == -1:
                look_touch = event.index
                last_look = event.position
        else:
            if event.index == joystick_touch:
                joystick_touch = -1
                move_input = Vector2.ZERO
                _position_joystick(get_viewport().size)
            if event.index == look_touch:
                look_touch = -1

    elif event is InputEventScreenDrag:
        if event.index == joystick_touch:
            var offset := event.position - joystick_center
            move_input = offset / 70.0
            move_input = move_input.limit_length(1.0)
            _move_joystick_visual()
        elif event.index == look_touch:
            var look_delta := event.position - last_look
            last_look = event.position

            player.rotate_y(-look_delta.x * LOOK_SENSITIVITY)
            pitch = clamp(pitch - look_delta.y * 0.15, -35.0, 25.0)
            _update_camera()

    elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        player.rotate_y(-event.relative.x * LOOK_SENSITIVITY)
        pitch = clamp(pitch - event.relative.y * 0.15, -35.0, 25.0)
        _update_camera()

func _move_joystick_visual() -> void:
    if joystick_base == null or joystick_knob == null:
        return

    joystick_base.position = joystick_center - joystick_base.size * 0.5
    joystick_knob.position = joystick_center + move_input * 45.0 - joystick_knob.size * 0.5
