GraphicItem
{	
    id = "main",

    Image {
	    id = "image",
        source = "images/Qt/toolbutton.png",
    },
    BorderImage {
	    id = "borderImage",
        source = "images/border-image.png",
        x = 200,
        y = 200,
        width = 400,
        height = 100,
        borderLeft = 30,
        borderRight = 30,
        borderTop = 30,
        borderBottom = 30,
		scale = 2,
		orientation = 45,
--        horizontalTileMode = BorderImage.Stretch,
--        verticalTileMode = BorderImage.Stretch,

		Text {
			id = "text",
			text = "Iñtërnâtiônàlizætiøn",
            font = "fonts/Vera.ttf",
            fontSize = 36,
            family = Text.Regular,
		},
    },
    Image {
	    id = "image2",
        source = "images/Qt/toolbutton.png",
	    x = function()
            return image.width
        end,
	    y = function()
            return image.height
        end,
        scale = 2,
        orientation = 45,

        MouseArea {
            id = "mouse",
--            width = function()
--                return image2.width
--            end,
--            height = function()
--                return image2.height
--            end,
            width = 64,
            height = 42,
            onPressedChanged = function()
				print(image2.id)
			end,
        },
    },
}
