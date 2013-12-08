Image {
	id = "comproot",
	x = function()
		local	totalWidth = total * (width + 5)
		return (grid.width - totalWidth) / 2 + col * (width + 5)
	end,
	y = function()
		return row * (height + 5)
	end,	
	width = function()
		return height * implicitWidth/implicitHeight
	end,
	height = function()
		return (grid.height - total * 5) / total
	end,
	source = "images/Minesweeper/front.png",
	
	Image {
		id = "mine",
		width = function()
			return comproot.width
		end,
		height = function()
			return comproot.height
		end,
	},
	
	MouseArea {
		id = "mouseArea",
		width = function()
			return comproot.width
		end,
		height = function()
			return comproot.height
		end,
		onPressedChanged = function()
			print(pressed)
			-- if pressed == false then
				-- comproot.source = "images/Minesweeper/back.png"
				-- if comproot.hasMine == true then
					-- mine.source = "images/Minesweeper/bomb-color.png"
				-- end
			-- end
		end
	}
}