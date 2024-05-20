class_name  HS extends  HSlider

func _init(): tooltip_text = "jstn"

func _make_custom_tooltip(for_text):
	var label := Label.new()
	label.text = name+": "+str(value)
	return label
