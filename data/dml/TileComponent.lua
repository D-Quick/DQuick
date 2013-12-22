
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
	source = "images/Minesweeper/back.png",
	flipped = false,
	onFlippedChanged = function()
		if flipped == true and nearbyMineCount == 0 then
			if getTile(row-1, col-1) and getTile(row-1, col-1).hasMine == false then
				getTile(row-1, col-1).flipped = true
			end
			if getTile(row-1, col) and getTile(row-1, col).hasMine == false then
				getTile(row-1, col).flipped = true
			end
			if getTile(row-1, col+1) and getTile(row-1, col+1).hasMine == false then
				getTile(row-1, col+1).flipped = true
			end
			if getTile(row, col-1) and getTile(row, col-1).hasMine == false then
				getTile(row, col-1).flipped = true
			end
			if getTile(row, col+1) and getTile(row, col+1).hasMine == false then
				getTile(row, col+1).flipped = true
			end
			if getTile(row+1, col-1) and getTile(row+1, col-1).hasMine == false then
				getTile(row+1, col-1).flipped = true
			end
			if getTile(row+1, col) and getTile(row+1, col).hasMine == false then
				getTile(row+1, col).flipped = true
			end
			if getTile(row+1, col+1) and getTile(row+1, col+1).hasMine == false then
				getTile(row+1, col+1).flipped = true
			end	
		end
	end,
	nearbyMineCount = function()
		return calculateNearbyCount(row, col)
	end,
	containsMouse = function()
		return mouseArea.containsMouse
	end,
	hasMine = false,
	
	Text {
		id = "text",
		x = function()
			return (comproot.width - implicitWidth) / 2
		end,
		y = function()
			return (comproot.height - implicitHeight) / 2
		end,	
		y = 0,
		text = function()
			if (comproot.flipped or root.status == "lost") and comproot.hasMine == false and comproot.nearbyMineCount > 0 then
				return comproot.nearbyMineCount
			else
				return ""
			end
		end,
		family = "Arial",
		fontSize = function()
			return math.floor(comproot.width / 2)
		end,
		fontStyle = Text.FontStyle.Regular,
	},
	
	Image {
		id = "bomb",
		x = function()
			return (comproot.width - width) / 2
		end,
		y = function()
			return (comproot.height - height) / 2
		end,		
		width = function()
			return height * implicitWidth/implicitHeight
		end,
		height = function()
			return comproot.height / 1.5
		end,
		source = function()
			if (comproot.flipped or root.status == "lost") and comproot.hasMine == true then
				return "images/Minesweeper/bomb-color.png"
			else
				return ""
			end
		end
	},	
	
	Image {
		id = "top",
		width = function()
			return comproot.width
		end,
		height = function()
			return comproot.height
		end,
		source = function()
			if comproot.flipped or root.status == "lost" then	
				return ""
			else
				return "images/Minesweeper/front.png"
			end
		end
	},			
	
	Image {
		id = "flag",
		x = function()
			return (comproot.width - width) / 2
		end,
		y = function()
			return (comproot.height - height) / 2
		end,		
		width = function()
			return height * implicitWidth/implicitHeight
		end,
		height = function()
			return comproot.height / 1.5
		end,
		source = function()
			if	comproot.hasMine and
				(getTile(comproot.row-1, comproot.col-1) == nil or getTile(comproot.row-1, comproot.col-1).hasMine == true or getTile(comproot.row-1, comproot.col-1).flipped) and 
				(getTile(comproot.row-1, comproot.col) == nil or getTile(comproot.row-1, comproot.col).hasMine == true or getTile(comproot.row-1, comproot.col).flipped) and
				(getTile(comproot.row-1, comproot.col+1) == nil or getTile(comproot.row-1, comproot.col+1).hasMine == true or getTile(comproot.row-1, comproot.col+1).flipped) and					
				(getTile(comproot.row, comproot.col-1) == nil or getTile(comproot.row, comproot.col-1).hasMine == true or getTile(comproot.row, comproot.col-1).flipped) and					
				(getTile(comproot.row, comproot.col+1) == nil or getTile(comproot.row, comproot.col+1).hasMine == true or getTile(comproot.row, comproot.col+1).flipped) and
				(getTile(comproot.row+1, comproot.col-1) == nil or getTile(comproot.row+1, comproot.col-1).hasMine == true or getTile(comproot.row+1, comproot.col-1).flipped) and 
				(getTile(comproot.row+1, comproot.col) == nil or getTile(comproot.row+1, comproot.col).hasMine == true or getTile(comproot.row+1, comproot.col).flipped) and
				(getTile(comproot.row+1, comproot.col+1) == nil or getTile(comproot.row+1, comproot.col+1).hasMine == true or getTile(comproot.row+1, comproot.col+1).flipped) then
				return "images/Minesweeper/flag-color.png"			
			else
				return ""
			end
		end
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
			if pressed == false then
				comproot.flipped = true
			end
		end,
	}
}