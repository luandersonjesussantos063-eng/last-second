extends Node3D

# =========================================================
# LAST SECOND
# HANGAR DO ZERO v0.1
#
# ETAPA 1:
# - somente piso
# - colisao real
# - linha central para mostrar a orientacao
#
# NAO adicionar paredes/salas ainda.
# =========================================================

@export var p01_spawn_local: Vector3 = Vector3(0.0, 5.0, -35.0)

var mat_piso: StandardMaterial3D
var mat_linha: StandardMaterial3D


func _ready() -> void:
	criar_materiais()
	criar_piso()
	criar_linha_central()

	print("==============================")
	print("HANGAR v0.1 // PISO ONLINE")
	print("P01 SPAWN: ", p01_spawn_local)
	print("==============================")


func criar_materiais() -> void:
	mat_piso = StandardMaterial3D.new()
	mat_piso.albedo_color = Color(0.08, 0.09, 0.11)
	mat_piso.metallic = 0.65
	mat_piso.roughness = 0.45

	mat_linha = StandardMaterial3D.new()
	mat_linha.albedo_color = Color(0.10, 0.90, 1.0)

	mat_linha.emission_enabled = true
	mat_linha.emission = Color(0.05, 0.75, 1.0)
	mat_linha.emission_energy_multiplier = 4.0


func criar_piso() -> void:
	var piso := StaticBody3D.new()
	piso.name = "PisoHangar"
	piso.position = Vector3(0.0, -0.5, 0.0)
	piso.collision_layer = 1
	piso.collision_mask = 1
	add_child(piso)

	var mesh := MeshInstance3D.new()

	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(
		120.0,
		1.0,
		160.0
	)

	mesh.mesh = box_mesh
	mesh.material_override = mat_piso
	piso.add_child(mesh)

	var collision := CollisionShape3D.new()

	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(
		120.0,
		1.0,
		160.0
	)

	collision.shape = box_shape
	piso.add_child(collision)


func criar_linha_central() -> void:
	var linha := MeshInstance3D.new()
	linha.name = "LinhaCentral"
	linha.position = Vector3(
		0.0,
		0.03,
		0.0
	)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(
		0.5,
		0.05,
		150.0
	)

	linha.mesh = mesh
	linha.material_override = mat_linha

	add_child(linha)
