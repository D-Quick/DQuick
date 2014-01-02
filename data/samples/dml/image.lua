GraphicItem {
	id = "root",
	
	Image {
		id = "stretch",

		fillMode = Image.FillMode.Stretch,
		source = "samples/images/Qt/qt-logo.png",
		width = 150,
		height = 110,

		Text {
			wrapMode = Text.WrapMode.WordWrap,
		
			x = function()
				return (stretch.width - implicitWidth) / 2
			end,
			y = function()
				return (stretch.height - implicitHeight) / 2
			end,
		
			width = function()
				return stretch.width
			end,
			height = function()
				return stretch.height
			end,

			text = "Stretch",
			family = "Arial",
			fontSize = 24,
			fontStyle = Text.FontStyle.Regular,
		},
	},

	Image {
		id = "preserveAspectFit",

		fillMode = Image.FillMode.PreserveAspectFit,
		source = "samples/images/Qt/qt-logo.png",
		width = function()
			return stretch.width
		end,
		height = function()
			return stretch.height
		end,

		x = function()
			return stretch.x + stretch.width + 20
		end,
		
		Text {
			wrapMode = Text.WrapMode.WordWrap,
		
			x = function()
				return (stretch.width - implicitWidth) / 2
			end,
			y = function()
				return (stretch.height - implicitHeight) / 2
			end,
		
			width = function()
				return stretch.width
			end,
			height = function()
				return stretch.height
			end,

			text = "PreserveAspectFit",
			family = "Arial",
			fontSize = 24,
			fontStyle = Text.FontStyle.Regular,
		},
	},
}
