extends Node3D


func _ready() -> void:

	criar_ceu()
	criar_sol()
	criar_chao()
	criar_pista()
	criar_camera()

	print("### CENA DA TERRA FUNCIONANDO ###")


# =========================================================
# CEU
# =========================================================

func criar_ceu() -> void:

	var world_environment := WorldEnvironment.new()
	world_environment.name = "EarthEnvironment"

	var ambiente := Environment.new()

	ambiente.background_mode = Environment.BG_COLOR

	ambiente.background_color = Color(
		0.30,
		0.65,
		0.95,
		1.0
	)

	ambiente.ambient_light_source = (
		Environment.AMBIENT_SOURCE_COLOR
	)

	ambiente.ambient_light_color = Color(
		0.80,
		0.87,
		1.0,
		1.0
	)

	ambiente.ambient_light_energy = 1.1

	ambiente.fog_enabled = false


	world_environment.environment = ambiente


	add_child(
		world_environment
	)


# =========================================================
# SOL
# =========================================================

func criar_sol() -> void:

	var sol := DirectionalLight3D.new()

	sol.name = "Sun"

	sol.rotation_degrees = Vector3(
		-55.0,
		-30.0,
		0.0
	)

	sol.light_energy = 1.4

	sol.shadow_enabled = true


	add_child(
		sol
	)


# =========================================================
# CHAO VERDE
# =========================================================

func criar_chao() -> void:

	var chao := MeshInstance3D.new()

	chao.name = "GreenGround"


	var mesh := PlaneMesh.new()

	mesh.size = Vector2(
		12000.0,
		12000.0
	)


	chao.mesh = mesh


	var material := StandardMaterial3D.new()

	material.albedo_color = Color(
		0.07,
		0.38,
		0.06,
		1.0
	)

	material.roughness = 1.0


	chao.material_override = material


	add_child(
		chao
	)


# =========================================================
# PISTA
# =========================================================

func criar_pista() -> void:

	var pista := MeshInstance3D.new()

	pista.name = "Runway"


	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		70.0,
		0.4,
		4000.0
	)


	pista.mesh = mesh


	pista.position = Vector3(
		0.0,
		0.2,
		-600.0
	)


	var material := StandardMaterial3D.new()

	material.albedo_color = Color(
		0.055,
		0.060,
		0.065,
		1.0
	)

	material.roughness = 0.95


	pista.material_override = material


	add_child(
		pista
	)


	criar_linhas_pista()


# =========================================================
# LINHAS
# =========================================================

func criar_linhas_pista() -> void:

	for i in range(50):

		var linha := MeshInstance3D.new()


		var mesh := BoxMesh.new()

		mesh.size = Vector3(
			1.5,
			0.08,
			20.0
		)


		linha.mesh = mesh


		linha.position = Vector3(
			0.0,
			0.43,
			1200.0 - float(i) * 75.0
		)


		var material := StandardMaterial3D.new()

		material.albedo_color = Color.WHITE


		linha.material_override = material


		add_child(
			linha
		)


# =========================================================
# CAMERA
# =========================================================

func criar_camera() -> void:

	var camera := Camera3D.new()

	camera.name = "EarthCamera"


	camera.position = Vector3(
		0.0,
		8.0,
		1400.0
	)


	camera.fov = 75.0

	camera.near = 0.1

	camera.far = 20000.0


	add_child(
		camera
	)


	camera.look_at(
		Vector3(
			0.0,
			2.0,
			-1000.0
		),
		Vector3.UP
	)


	camera.make_current()
