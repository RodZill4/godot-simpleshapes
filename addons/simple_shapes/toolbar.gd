tool
extends HBoxContainer

var plugin = null

func _ready():
	var select = get_node("SelectShape")
	select.clear()
	select.add_item("<Shape>")
	select.add_item("Rectangle")
	select.add_item("Ellipse")
	select.add_item("Star")
	select.select(plugin.shape_data.shape)
	update_ui()

func update_ui():
	var spinbox = get_node("SpinBox")
	if plugin.shape_data.shape != 3:
		spinbox.hide()
	else:
		spinbox.show()
		spinbox.set_val(plugin.shape_data.count)


func _on_SelectShape_item_selected(id):
	plugin.set_shape(id)
	update_ui()

func _on_SpinBox_value_changed(value):
	plugin.set_count(value)
