extends CharacterBody2D

const SPEED = 70.0
var health = 100
var max_health = 100
var is_dead = false
var death_animation_duration = 1.0
var death_timer = 0.0
var attack_damage = 20
var attacking = false
var attack_duration = 0.6
var attack_timer = 0.0
var attack_range_orc = 20  # Радиус атаки для нанесения урона орку

# Список анимаций для каждого направления
enum {
	DIRECTION_IDLE,
	DIRECTION_LEFT,
	DIRECTION_RIGHT,
	DIRECTION_UP,
	DIRECTION_DOWN,
	DEATH,
	ATTACK_FRONT,
	ATTACK_IDLE,
	ATTACK_LEFT,
	ATTACK_RIGHT
}

func set_animation(direction):
	match direction:
		DIRECTION_IDLE:
			$AnimatedSprite2D.animation = "idle"
		DIRECTION_LEFT:
			$AnimatedSprite2D.animation = "left"
		DIRECTION_RIGHT:
			$AnimatedSprite2D.animation = "right"
		DIRECTION_UP:
			$AnimatedSprite2D.animation = "up"
		DIRECTION_DOWN:
			$AnimatedSprite2D.animation = "down"
		DEATH:
			$AnimatedSprite2D.animation = "death"
		ATTACK_FRONT:
			$AnimatedSprite2D.animation = "front_attack"
		ATTACK_IDLE:
			$AnimatedSprite2D.animation = "idle_attack"
		ATTACK_LEFT:
			$AnimatedSprite2D.animation = "left_attack"
		ATTACK_RIGHT:
			$AnimatedSprite2D.animation = "right_attack"
	$AnimatedSprite2D.play()

func _ready():
	update_health_bar()

func _physics_process(delta):
	if health <= 0 and not is_dead:
		set_animation(DEATH)
		is_dead = true
		death_timer = 0.0
		return

	if is_dead:
		death_timer += delta
		if death_timer >= death_animation_duration:
			get_tree().change_scene("res://menu/menu.tscn")
		return

	if attacking:
		attack_timer += delta
		if attack_timer >= attack_duration:
			attacking = false
			attack_timer = 0.0
			var mobs = get_node("/root/mapmain/Mobs")
			for orc in mobs.get_children():
				if orc and global_position.distance_to(orc.global_position) <= attack_range_orc:
					orc.take_damage_from_player(attack_damage)
		return

	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED

	if Input.is_action_just_pressed("attack"):
		attack(direction)
	else:
		if direction.length() == 0:
			set_animation(DIRECTION_IDLE)
		else:
			if direction.x < 0:
				set_animation(DIRECTION_LEFT)
			elif direction.x > 0:
				set_animation(DIRECTION_RIGHT)
			elif direction.y < 0:
				set_animation(DIRECTION_UP)
			elif direction.y > 0:
				set_animation(DIRECTION_DOWN)

	move_and_slide()

func attack(direction):
	if attacking:
		return
	attacking = true
	attack_timer = 0.0

	var attack_animation = ATTACK_IDLE  # По умолчанию анимация атаки idle

	if direction.x < 0:
		attack_animation = ATTACK_LEFT
	elif direction.x > 0:
		attack_animation = ATTACK_RIGHT
	elif direction.y < 0:
		attack_animation = ATTACK_FRONT
	else:
		attack_animation = ATTACK_IDLE

	set_animation(attack_animation)

	var attack_area = null
	if direction.x < 0:
		attack_area = $"AttackLeft/attackleft"
	elif direction.x > 0:
		attack_area = $"AttackRight/attackright"
	elif direction.y < 0:
		attack_area = $"AttackUp/attackup"
	else:
		attack_area = $"AttackDown/attackdown"

	if attack_area and attack_area.is_in_group("AttackArea"):
		attack_area.set_monitoring(true)

	if direction != Vector2.ZERO:
		var mobs = get_node("/root/mapmain/Mobs")
		for orc in mobs.get_children():
			if orc and global_position.distance_to(orc.global_position) <= attack_range_orc:
				orc.take_damage_from_player(attack_damage)

func receive_damage_from_orc(damage):
	health -= damage
	if health < 0:
		health = 0
	update_health_bar()

func update_health_bar():
	var health_bar = $"../../CanvasLayer/Panel/HealthProgressBar"
	health_bar.value = health
