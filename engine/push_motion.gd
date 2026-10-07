extends RefCounted
class_name PushMotion

var pending := false
var moving := false
var generation := 0
var tween: Tween

func is_busy() -> bool:
	return pending or moving

func reserve(direction: Vector2) -> int:
	if is_busy() or direction not in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		return -1
	# Reserve before waiting for the ray. A second call must not change the
	# shared ray or start another tween during that wait.
	pending = true
	return generation

func resolve(ticket: int) -> bool:
	if ticket != generation or !pending:
		return false
	pending = false
	return true

func cancel() -> void:
	generation += 1
	pending = false
	moving = false
	if tween and tween.is_valid():
		tween.kill()

func animate(body: Node2D, start: Vector2, destination: Vector2, duration: float) -> Tween:
	cancel()
	moving = true
	tween = body.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(body, "position", destination, duration).from(start)
	tween.finished.connect(finish)
	return tween

func finish() -> void:
	moving = false
