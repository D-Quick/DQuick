
Image {
	id = "comproot",
---	fillMode = Image.FillMode.PreserveAspectFit,
    width = function()
		return height * implicitWidth / implicitHeight
	end,
	height = function()
		return (grid.height - grid.spacing * (model.columns - 1)) / model.columns
	end,
	source = "images/Minesweeper/back.png",
	containsMouse = function()
		return mouseArea.containsMouse
	end,
	
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
			if (comproot.model.flipped or root.status == "lost") and comproot.model.hasMine == false and comproot.model.nearbyMineCount > 0 then
				return comproot.model.nearbyMineCount
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
			if (comproot.model.flipped or root.status == "lost") and comproot.model.hasMine == true then
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
			if comproot.model.flipped or root.status == "lost" then	
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
			if	comproot.model.hasMine and
				(getTileModel(comproot.model.row-1, comproot.model.col-1) == nil or getTileModel(comproot.model.row-1, comproot.model.col-1).hasMine == true or getTileModel(comproot.model.row-1, comproot.model.col-1).flipped) and 
				(getTileModel(comproot.model.row-1, comproot.model.col) == nil or getTileModel(comproot.model.row-1, comproot.model.col).hasMine == true or getTileModel(comproot.model.row-1, comproot.model.col).flipped) and
				(getTileModel(comproot.model.row-1, comproot.model.col+1) == nil or getTileModel(comproot.model.row-1, comproot.model.col+1).hasMine == true or getTileModel(comproot.model.row-1, comproot.model.col+1).flipped) and					
				(getTileModel(comproot.model.row, comproot.model.col-1) == nil or getTileModel(comproot.model.row, comproot.model.col-1).hasMine == true or getTileModel(comproot.model.row, comproot.model.col-1).flipped) and					
				(getTileModel(comproot.model.row, comproot.model.col+1) == nil or getTileModel(comproot.model.row, comproot.model.col+1).hasMine == true or getTileModel(comproot.model.row, comproot.model.col+1).flipped) and
				(getTileModel(comproot.model.row+1, comproot.model.col-1) == nil or getTileModel(comproot.model.row+1, comproot.model.col-1).hasMine == true or getTileModel(comproot.model.row+1, comproot.model.col-1).flipped) and 
				(getTileModel(comproot.model.row+1, comproot.model.col) == nil or getTileModel(comproot.model.row+1, comproot.model.col).hasMine == true or getTileModel(comproot.model.row+1, comproot.model.col).flipped) and
				(getTileModel(comproot.model.row+1, comproot.model.col+1) == nil or getTileModel(comproot.model.row+1, comproot.model.col+1).hasMine == true or getTileModel(comproot.model.row+1, comproot.model.col+1).flipped) then
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
				comproot.model.flipped = true
			end
		end,
	}
}