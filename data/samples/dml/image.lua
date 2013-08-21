require "dml/button"

Button {
	width = function()
		return image.width
	end,
	height = function()
		return image.height
	end,
}
