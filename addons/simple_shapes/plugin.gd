tool
extends EditorPlugin

var is_godot21
var edited_object = null
var editor        = null
var toolbar       = null
var shape_data

const SHAPE_NONE      = 0
const SHAPE_RECTANGLE = 1
const SHAPE_ELLIPSE   = 2
const SHAPE_STAR      = 3

var handles       = []
var handle_mode   = HANDLE_NONE

const HANDLE_NONE  = 0
const HANDLE_WIDTH  = 1
const HANDLE_HEIGHT = 2
const HANDLE_POINT1 = 3
const HANDLE_POINT2 = 4

const handle_tex = preload("res://addons/simple_shapes/handle.png")
const editor_script = preload("res://addons/simple_shapes/editor.gd")

func _enter_tree():
	var godot_version = OS.get_engine_version()
	is_godot21 = godot_version.major == "2" && godot_version.minor == "1"
	handle_tex.set_flags(0)

func _exit_tree():
	make_visible(false)

func handles(o):
	if o.get_type() == "Polygon2D":
		return true
	else:
		return false

func edit(o):
	edited_object = o
	if edited_object.has_meta("simple_shape"):
		shape_data = edited_object.get_meta("simple_shape")
	else:
		shape_data = { shape = SHAPE_NONE }

func make_visible(b):
	if b:
		if is_godot21:
			if editor == null:
				var viewport = edited_object.get_viewport()
				editor = editor_script.new()
				editor.plugin = self
				viewport.add_child(editor)
				viewport.connect("size_changed", editor, "update")
		else:
			update()
		if toolbar == null:
			toolbar = preload("res://addons/simple_shapes/toolbar.tscn").instance()
			toolbar.plugin = self
			add_control_to_container(CONTAINER_CANVAS_EDITOR_MENU, toolbar)
	else:
		if editor != null:
			editor.queue_free()
			editor = null
		if toolbar != null:
			toolbar.queue_free()
			toolbar = null

func update():
	if is_godot21:
		editor.update()
	else:
		update_canvas()

func set_shape(id):
	if shape_data.shape != id:
		shape_data.shape = id
		update_shape()
		update()

func set_count(c):
	if shape_data.count != c:
		shape_data.count = c
		update_shape()
		update()

func shape_param(n, d):
	if !shape_data.has(n):
		shape_data[n] = d
	return shape_data[n]

func update_shape():
	edited_object.set_meta("simple_shape", shape_data)
	if !shape_data.has("shape"):
		shape_data.shape = SHAPE_NONE
	elif shape_data.shape == SHAPE_RECTANGLE:
		var w = shape_param("width", 50)
		var h = shape_param("height", 50)
		var polygon = Vector2Array()
		polygon.append(Vector2(-w, -h))
		polygon.append(Vector2(-w, h))
		polygon.append(Vector2(w, h))
		polygon.append(Vector2(w, -h))
		edited_object.set_polygon(polygon)
	elif shape_data.shape == SHAPE_ELLIPSE:
		var w = shape_param("width", 50)
		var h = shape_param("height", 50)
		var polygon = Vector2Array()
		var point_count = 32
		for i in range(point_count):
			polygon.append(Vector2(w*cos(2*PI*(i+0.5)/point_count), h*sin(2*PI*(i+0.5)/point_count)))
		edited_object.set_polygon(polygon)
	elif shape_data.shape == SHAPE_STAR:
		var n = shape_param("count", 3)
		var p1 = shape_param("point1", Vector2(50, 20))
		var p2 = shape_param("point2", Vector2(70, 0))
		var polygon = Vector2Array()
		for i in range(n):
			polygon.append(p1.rotated(i*2*PI/n))
			polygon.append(p2.rotated(i*2*PI/n))
		edited_object.set_polygon(polygon)

func int_coord(p):
	return Vector2(round(p.x), round(p.y))

func forward_draw_over_canvas(canvas_xform, canvas):
	var transform = canvas_xform*edited_object.get_global_transform()
	var p
	if shape_data.shape == SHAPE_RECTANGLE || shape_data.shape == SHAPE_ELLIPSE:
		handles = []
		p = transform.xform(Vector2(shape_data.width, 0))
		canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p)-Vector2(5, 5), Vector2(11, 11)), false)
		handles.append({ pos = p, mode = HANDLE_WIDTH })
		p = transform.xform(Vector2(0, shape_data.height))
		canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p)-Vector2(5, 5), Vector2(11, 11)), false)
		handles.append({ pos = p, mode = HANDLE_HEIGHT })
	elif shape_data.shape == SHAPE_STAR:
		p = transform.xform(shape_data.point1)
		canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p)-Vector2(5, 5), Vector2(11, 11)), false)
		handles.append({ pos = p, mode = HANDLE_POINT1 })
		p = transform.xform(shape_data.point2)
		canvas.draw_texture_rect(handle_tex, Rect2(int_coord(p)-Vector2(5, 5), Vector2(11, 11)), false)
		handles.append({ pos = p, mode = HANDLE_POINT2 })

func forward_canvas_input_event(canvas_xform, event):
	if event.type == InputEvent.MOUSE_BUTTON:
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				for h in handles:
					if (event.pos - h.pos).length() < 6:
						# Activate handle
						handle_mode = h.mode
						return true
			elif handle_mode != HANDLE_NONE:
				handle_mode = HANDLE_NONE
				return true
	elif event.type == InputEvent.MOUSE_MOTION && handle_mode != HANDLE_NONE:
		var transform_inv = edited_object.get_global_transform().affine_inverse()
		var viewport_transform_inv = edited_object.get_viewport().get_global_canvas_transform().affine_inverse()
		var p = transform_inv.xform(viewport_transform_inv.xform(event.pos))
		if handle_mode == HANDLE_WIDTH:
			shape_data.width = p.x
		elif handle_mode == HANDLE_HEIGHT:
			shape_data.height = p.y
		elif handle_mode == HANDLE_POINT1:
			shape_data.point1 = p
		elif handle_mode == HANDLE_POINT2:
			shape_data.point2 = p
		update_shape()
		update()
		return true
	update()
	return false

# Godot 2.1
func forward_input_event(event):
	if editor == null:
		return false
	return forward_canvas_input_event(editor.get_viewport().get_global_canvas_transform(), event)
