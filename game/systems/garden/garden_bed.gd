class_name GardenBed
extends Node2D
## 정원 칸 10개를 그린다 (docs/gdd/garden.md §2, §4-1). 칸마다 Interactable(id = plot_xx)을 둔다.
## 배치: 하늘 줄 y = rows_y[0], 별 줄 y = rows_y[1], x = x0 + (col-1)*dx. 성장 3 이상이면 ColorRestoreLayer 에 색을 되돌린다.

const SOIL := Color("#52443c")
const SOIL_LIGHT := Color("#7a6858")
const STEM := Color("#6e6c73")

@export var rows_y: Vector2 = Vector2(160, 214)
@export var x0: float = 140.0
@export var dx: float = 50.0

var restore_layer: ColorRestoreLayer = null
var _restored: Dictionary = {}   # plot_id → growth 단계 (중복 복원 방지)


func _ready() -> void:
	for id in GardenModel.plot_ids():
		var target := Interactable.new()
		target.name = "Plot_" + id
		target.interact_id = id
		target.radius = 18.0
		target.position = plot_position(id)
		add_child(target)
	refresh()


func plot_position(plot_id: String) -> Vector2:
	var row := 0 if GardenModel.owner_of(plot_id) == "haneul" else 1
	return Vector2(x0 + (GardenModel.col_of(plot_id) - 1) * dx, rows_y[row])


func refresh() -> void:
	if restore_layer != null:
		for d: Dictionary in GardenModel.planted().values():
			var id := str(d["id"])
			var growth := int(d["growth"])
			if growth >= 3 and int(_restored.get(id, 0)) < growth:
				restore_layer.restore(str(d["emotion"]), plot_position(id) + Vector2(0, -8), 24.0 if growth >= 5 else 14.0, false)
				_restored[id] = growth
	queue_redraw()


func _draw() -> void:
	var planted := GardenModel.planted()
	for id in GardenModel.plot_ids():
		var p := plot_position(id)
		draw_rect(Rect2(p + Vector2(-14, -4), Vector2(28, 8)), SOIL)
		draw_rect(Rect2(p + Vector2(-14, -4), Vector2(28, 2)), SOIL_LIGHT)
		if planted.has(id):
			_draw_plant(p, planted[id] as Dictionary)
	_draw_heart_bed()


func _draw_plant(p: Vector2, d: Dictionary) -> void:
	var emotion := str(d["emotion"])
	var growth := int(d["growth"])
	var ramp := EmotionBands.ramp(emotion)
	var symbol := EmotionSymbols.symbol_of(emotion)
	match growth:
		0:
			draw_circle(p + Vector2(0, -4), 3.0, SOIL_LIGHT)
			draw_line(p + Vector2(8, -2), p + Vector2(8, -12), STEM, 1.0)
			draw_rect(Rect2(p + Vector2(4, -18), Vector2(9, 7)), Color("#edebf0"))
			EmotionSymbols.draw(self, symbol, p + Vector2(8.5, -14.5), Color("#4a494f"), 2.6)
		1:
			draw_line(p + Vector2(0, -4), p + Vector2(0, -10), STEM, 1.0)
			draw_circle(p + Vector2(-2, -11), 2.0, ramp[0])
			draw_circle(p + Vector2(2, -11), 2.0, ramp[0])
		2:
			draw_line(p + Vector2(0, -4), p + Vector2(0, -16), STEM, 1.0)
			for k in 3:
				var y := -8.0 - k * 3.0
				draw_circle(p + Vector2(-3 if k % 2 == 0 else 3, y), 2.0, ramp[1] if k == 2 else ramp[0])
		_:
			draw_line(p + Vector2(0, -4), p + Vector2(0, -18), STEM, 1.0)
			draw_circle(p + Vector2(-3, -10), 2.0, ramp[0])
			draw_circle(p + Vector2(3, -13), 2.0, ramp[0])
			if growth == 3:
				draw_circle(p + Vector2(0, -20), 3.0, ramp[1])
			else:
				for k in 5:
					draw_circle(p + Vector2(0, -21) + Vector2.from_angle(TAU * k / 5.0) * 4.0, 2.5, ramp[2])
				draw_circle(p + Vector2(0, -21), 2.0, ramp[3])
				if growth >= 5:
					EmotionSymbols.draw(self, symbol, p + Vector2(9, -26), ramp[3], 2.5)


## 마음 화단 (ch2_garden 부터): 위쪽 가장자리 12칸, 파랑은 왼쪽부터 초록은 오른쪽부터
func _draw_heart_bed() -> void:
	var bed: Dictionary = GardenModel.rules().get("heart_bed", {})
	var first := str(bed.get("first_scene", "ch2_garden"))
	var chapter_order: Array[String] = ["prologue", "ch1", "ch2", "ch3", "ch4", "ch5"]
	if chapter_order.find(GameState.chapter) < chapter_order.find(first.get_slice("_", 0)):
		return
	var counts := GardenModel.heart_bed()
	var cells := int(bed.get("cells", 12))
	var y := rows_y.x - 34.0
	for i in cells:
		var pos := Vector2(x0 - 20.0 + i * ((dx * 4.0 + 40.0) / float(cells - 1)), y)
		var c := Color("#99969e")
		var sym := ""
		if i < int(counts["blue"]):
			c = EmotionBands.main_color("longing")
			sym = "wave"
		elif i >= cells - int(counts["green"]):
			c = EmotionBands.main_color("healing")
			sym = "leaf"
		draw_circle(pos, 2.5, c)
		if not sym.is_empty():
			EmotionSymbols.draw(self, sym, pos + Vector2(0, -6), c, 2.0)
