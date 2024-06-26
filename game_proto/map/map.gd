extends Node2D

@onready var light = $DirectionalLight2D
@onready var time_label = $CanvasLayer/time
@onready var day_text = $CanvasLayer/daytext
@onready var animdaytext = $CanvasLayer/AnimationPlayer
@onready var healthbar = $CanvasLayer/Panel/HealthProgressBar
@onready var player = $Player/Player

enum {
	MORNING,
	DAY,
	EVENING,
	NIGHT
}

var state = MORNING
var time_in_minutes = 360  # Время начинается с 6:00 утра
var last_time_update = 0.0
var time_speed_coefficient = float(1440) / 480  # 1440 игровых минут в 480 секунд реального времени
var current_time_duration = 120.0  # Длительность текущего периода времени в секундах (2 минуты)
var time_since_last_state_change = 0.0  # Время с последнего изменения состояния
var day_count: int


func _ready():
	light.enabled = true
	day_count = 1
	_process_state()
	update_time_label()
	set_day_text()
	day_text_fade()

func _process(delta):
	advance_time_if_needed(delta)

func _process_state():
	match state:
		MORNING:
			morning_state()
		DAY:
			day_state()
		EVENING:
			evening_state()
		NIGHT:
			night_state()

func morning_state():
	var tween = get_tree().create_tween()
	tween.tween_property(light, "energy", 0.0, current_time_duration)
	tween.tween_callback(Callable(self, "_on_tween_completed"))
	time_speed_coefficient = float(1440) / 480  # Утро: 1 игровая минута = 0.3333 секунды реального времени
	time_since_last_state_change = 0.0

func day_state():
	var tween = get_tree().create_tween()
	tween.tween_property(light, "energy", 0.0, current_time_duration)
	tween.tween_callback(Callable(self, "_on_tween_completed"))
	time_speed_coefficient = float(1440) / 480  # День: 1 игровая минута = 0.3333 секунды реального времени
	time_since_last_state_change = 0.0

func evening_state():
	var tween = get_tree().create_tween()
	tween.tween_property(light, "energy", 0.7, current_time_duration)
	tween.tween_callback(Callable(self, "_on_tween_completed"))
	time_speed_coefficient = float(1440) / 480  # Вечер: 1 игровая минута = 0.3333 секунды реального времени
	time_since_last_state_change = 0.0

func night_state():
	var tween = get_tree().create_tween()
	tween.tween_property(light, "energy", 0.8, current_time_duration)
	tween.tween_callback(Callable(self, "_on_tween_completed"))
	time_speed_coefficient = float(1440) / 480  # Ночь: 1 игровая минута = 0.3333 секунды реального времени
	time_since_last_state_change = 0.0

func _on_tween_completed():
	_on_day_night_timeout()

func _on_day_night_timeout():
	if state < NIGHT:
		state += 1
	else:
		state = MORNING
		day_count += 1
		set_day_text()
		day_text_fade()
	_process_state()
	
func day_text_fade():
	animdaytext.play("daytext")
	await get_tree().create_timer(3).timeout
	animdaytext.play("daytext_fadeout")

func advance_time_if_needed(delta):
	time_in_minutes += delta * time_speed_coefficient
	if time_in_minutes >= 1440:
		time_in_minutes = 0
	update_time_label()

func update_time_label():
	var hours = int(floor(time_in_minutes / 60))
	var minutes = int(floor(fmod(time_in_minutes, 60)))
	var formatted_hours = ("%02d" % hours)
	var formatted_minutes = ("%02d" % minutes)
	time_label.text = formatted_hours + ":" + formatted_minutes
	
func set_day_text():
	day_text.text = "DAY  " + str(day_count)


