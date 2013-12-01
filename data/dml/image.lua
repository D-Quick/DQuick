require "dml/button"

total = 0

function createImage(par, name, num)
	if num < 40 then
		total = total + 1
		return 	Image {
			id = name,
			source = "images/pngtest.png",
			width = function()
				return _G[par].width * 0.9
			end,
			height = function()
				return _G[par].height * 0.9
			end,
			
			createImage(name, name.."0", num + 1),
			--createImage(name, name.."1", num + 1),
		}
	else
		return nil
	end
end

GraphicItem {
	id = "root",
	Image {
		id = "image",
		source = "images/pngtest.png",
	
		-- onWidthChanged = function()
			-- print("onWidthChanged " .. getItemProperty("image", "width") / (4/3) .. "\n")
		
			-- setItemProperty("image", "height", getItemProperty("image", "width") / (4/3))
			-- print(getItemProperty("image", "width").." "..getItemProperty("image", "height"))
		-- end,

		titi = 0,
		toto = function()
			return image.width + image.height
		end,
		onTotoChanged = function()
			image.titi = image.toto
	--		print("onTotoChanged = "..image.titi)		
		end,
	
		width = function()
			return root.width
		end,
		height = function()
			return root.height
		end,	
	
		Image {
			id = "image2",
			source = function()
				if image.titi > 1400 then
					return "images/Alpha-blue-trans.png"
				else
					return "images/pngtest.png"
				end
			end,
			width = function()
				return image.width / 0.9
			end,
			height = function()
				return image.height / 0.9
			end,

			createImage("image2", "image3", 0),
		
			MouseArea {
				id = "mArea2",
				width = function()
					return image2.width
				end,
				height = function()
					return image2.height
				end,

				onPressedChanged = function()
					print("onPressedChanged")
					print(mArea2.mouseX)
					--mArea2.mouseX = 1
				end,

				onMouseXChanged = function()
	--				print("onMouseXChanged mouseX = "..mArea2.mouseX)
				end,
			},
		},

		Button {
			width = function()
				return image.width
			end,
			height = function()
				return image.height
			end,
		},
		Text {
			id = "text",
			
			wrapMode = Text.WrapMode.WordWrap,
			width = 100,
			height = 50,
			x = function()
				return image.width - 100
			end,
			y = function()
				return image.height - 50
			end,			

			text = function() 
				return total
			end,
			family = "Arial",
			fontSize = 24,
			fontStyle = Text.FontStyle.Regular,
		},		
	},
}

image2.x = function()
			return 0
		end
		
--print(image.toto)
