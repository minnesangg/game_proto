extends CharacterBody2D

signal health_changed(new_health)

var chase = false
var speed = 45
var attacking = false
var attack_cooldown = 2.0 # Задержка между атаками
var attack_duration = 1.0 # Длительность анимации атаки
var attack_range_player = 15 # Радиус атаки для нанесения урона игроку
var is_dead = false
var death_timer = 0.0

var health = 25 # Здоровье орка

var time_since_last_attack = 0
var attack_timer = 0

var player_attack_damage = 0

enum {
	DIRECTION_IDLE,
	DIRECTION_LEFT,
	DIRECTION_RIGHT,
	DIRECTION_UP,
	DIRECTION_DOWN,
	DEATH
}

func _ready():
	$CollisionShape2D.disabled = false # Включить коллайдер при старте

func set_animation(direction):
	match direction:
		DIRECTION_IDLE:
			$AnimatedSprite2D.animation = "idle"
		DIRECTION_LEFT:
			$AnimatedSprite2D.animation = "left"
		DIRECTION_RIGHT:
			$AnimatedSprite2D.animation = "right"
		DIRECTION_UP:
			$AnimatedSprite2D.animation = "left" # Заменил на "left" для симуляции атаки влево
		DIRECTION_DOWN:
			$AnimatedSprite2D.animation = "right"
		DEATH:
			$AnimatedSprite2D.animation = "death"
	$AnimatedSprite2D.play()

func set_attack_animation(direction):
	if direction == DIRECTION_LEFT:
		$AnimatedSprite2D.animation = "attack_left"
	else:
		$AnimatedSprite2D.animation = "attack_right"
	$AnimatedSprite2D.play()

func attack_player(player, direction):
	attacking = true
	attack_timer = 0 # Сброс таймера атаки
	velocity = Vector2.ZERO # Остановить орка перед атакой
	set_attack_animation(direction)
	$CollisionShape2D.disabled = true # Временно отключаем коллайдер в момент атаки

func _physics_process(delta):
	if is_dead:
		death_timer += delta
		if death_timer >= 0.6: # Время отображения анимации смерти
			queue_free() # Уничтожить орка после завершения анимации
		return

	time_since_last_attack += delta
	var player = get_node("/root/mapmain/Player/Player")
	var direction = (player.position - self.position).normalized()

	if attacking:
		attack_timer += delta
		velocity = Vector2.ZERO  # Остановить орка во время атаки

		if attack_timer >= attack_duration:
			attacking = false
			if global_position.distance_to(player.global_position) <= attack_range_player:
				player.receive_damage_from_orc(10)  # Нанести урон игроку
				chase = true  # Вернуться в режим преследования
			time_since_last_attack = 0  # Сброс времени после успешной атаки
			$CollisionShape2D.disabled = false # Включаем коллайдер обратно после завершения анимации атаки

		# Проверяем расстояние до игрока в момент атаки, чтобы не дать ему пройти сквозь орка
		if global_position.distance_to(player.global_position) <= attack_range_player:
			chase = true

		return

	if chase:
		velocity = direction * speed

		if abs(direction.x) > abs(direction.y):
			if direction.x < 0:
				set_animation(DIRECTION_LEFT)
			else:
				set_animation(DIRECTION_RIGHT)
		else:
			if direction.y < 0:
				set_animation(DIRECTION_UP)
			else:
				set_animation(DIRECTION_DOWN)

		if global_position.distance_to(player.global_position) < attack_range_player:  # Проверяем радиус атаки
			if time_since_last_attack >= attack_cooldown:
				attack_player(player, DIRECTION_LEFT if direction.x < 0 else DIRECTION_RIGHT)
	else:
		velocity = Vector2.ZERO
		set_animation(DIRECTION_IDLE)

	move_and_slide()

	# Проверка расстояния между орком и игроком
	var min_distance = 10  # Минимальное расстояние между орком и игроком, при котором орк не "приклеивается"
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player < min_distance:
		# Используем move_and_collide для более свободного перемещения орка, если игрок слишком близко
		var motion = (global_position - player.global_position).normalized() * speed * delta
		var collision = move_and_collide(motion)
		if collision:
			velocity = Vector2.ZERO  # Останавливаем орка при столкновении

func _on_detector_body_entered(body):
	if body.name == "Player":
		chase = true

func _on_detector_body_exited(body):
	if body.name == "Player":
		chase = false
		attacking = false # Остановить атаку при выходе из области действия

func _on_damage_body_entered(body):
	var player = get_node("/root/mapmain/Player/Player")
	if body.name == "Player" and attacking:
		if attack_timer >= attack_duration: # Наносить урон только по завершении анимации атаки
			player.receive_damage_from_orc(10)
			emit_signal("health_changed", player.health)

func take_damage_from_player(attack_damage):
	player_attack_damage = attack_damage
	health -= player_attack_damage / 2
	if health <= 0:
		health = 0
		set_animation(DEATH)
		is_dead = true # Установить флаг мертвым только после установки анимации смерти
		$CollisionShape2D.disabled = true # Отключить коллайдер только при смерти
	emit_signal("health_changed", health)
