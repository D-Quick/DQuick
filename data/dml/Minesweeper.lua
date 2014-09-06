ImportComponent("dml/TileComponent.lua")

function getTileModel(row, col)
	if row > grid.columns or col > grid.columns or row < 1 or col < 1 then
		return nil
	end
	return root.gridModel[((row - 1) * grid.columns + (col - 1)) + 1]
end

function getTileItem(row, col)
	if row > grid.columns or col > grid.columns or row < 1 or col < 1 then
		return nil
	end
	return grid.children[((row - 1) * grid.columns + (col - 1)) + 1]
end

function calculateStatus()
	local allFlipped = true
	local row = 1	
	while getTileModel(row, 1) do	
		local col = 1
		while getTileModel(row, col) do
			if getTileModel(row, col).flipped and getTileModel(row, col).hasMine then
				return "lost"
			end
			if getTileModel(row, col).flipped == false and getTileModel(row, col).hasMine == false then
				allFlipped = false
			end
			col = col + 1
		end
		row = row + 1
	end	
	if allFlipped then
		return "won"
	else
		return "inGame"
	end
end

function calculateCheat()
	local row = 1	
	while getTileModel(row, 1) do	
		local col = 1
		while getTileModel(row, col) and getTileItem(row, col) do	
			if getTileItem(row, col).containsMouse and getTileModel(row, col).hasMine then
				return true
			end
			col = col + 1
		end
		row = row + 1
	end	
	return false
end

function init()
	local row = 1	
	while getTileModel(row, 1) do	
		local col = 1
		while getTileModel(row, col) do
			getTileModel(row, col).hasMine = randomBool()
			getTileModel(row, col).flipped = false
			col = col + 1
		end
		row = row + 1
	end	
	return false
end

Image {
	id = "root",
	source = "images/Minesweeper/background.png",
	status = function()
		return calculateStatus()
	end,
	gridModel = function()
		t = {}
	
		local sum = 1
		local row = 1	
		while row <= grid.columns do	
			local col = 1
			while col <= grid.columns do
				t[sum] = Item {
					col = col,
					row = row,
					columns = grid.columns,
					hasMine = randomBool(),
					flipped = false,
					onFlippedChanged = function()
						if flipped == true and nearbyMineCount == 0 then
							if getTileModel(this.row-1, this.col-1) and getTileModel(this.row-1, this.col-1).hasMine == false then
								getTileModel(this.row-1, this.col-1).flipped = true
							end
							if getTileModel(this.row-1, this.col) and getTileModel(this.row-1, this.col).hasMine == false then
								getTileModel(this.row-1, this.col).flipped = true
							end
							if getTileModel(this.row-1, this.col+1) and getTileModel(this.row-1, this.col+1).hasMine == false then
								getTileModel(this.row-1, this.col+1).flipped = true
							end
							if getTileModel(this.row, this.col-1) and getTileModel(this.row, this.col-1).hasMine == false then
								getTileModel(this.row, this.col-1).flipped = true
							end
							if getTileModel(this.row, this.col+1) and getTileModel(this.row, this.col+1).hasMine == false then
								getTileModel(this.row, this.col+1).flipped = true
							end
							if getTileModel(this.row+1, this.col-1) and getTileModel(this.row+1, this.col-1).hasMine == false then
								getTileModel(this.row+1, this.col-1).flipped = true
							end
							if getTileModel(this.row+1, this.col) and getTileModel(this.row+1, this.col).hasMine == false then
								getTileModel(this.row+1, this.col).flipped = true
							end
							if getTileModel(this.row+1, this.col+1) and getTileModel(this.row+1, this.col+1).hasMine == false then
								getTileModel(this.row+1, this.col+1).flipped = true
							end	
						end
					end,
					nearbyMineCount = function()
						local totalNearby = 0;
						totalNearby = totalNearby + ((getTileModel(this.row-1, 	this.col-1) and getTileModel(this.row-1, 	this.col-1).hasMine) and 1 or 0)
						totalNearby = totalNearby + ((getTileModel(this.row-1, 	this.col) 	and getTileModel(this.row-1, 	this.col).hasMine) 	and 1 or 0)
						totalNearby = totalNearby + ((getTileModel(this.row-1, 	this.col+1) and getTileModel(this.row-1, 	this.col+1).hasMine) and 1 or 0)
						totalNearby = totalNearby + ((getTileModel(this.row, 	this.col-1) and getTileModel(this.row, 		this.col-1).hasMine) and 1 or 0)
						totalNearby = totalNearby + ((getTileModel(this.row, 	this.col) 	and getTileModel(this.row, 		this.col).hasMine) and 1 or 0)	
						totalNearby = totalNearby + ((getTileModel(this.row, 	this.col+1) and getTileModel(this.row, 		this.col+1).hasMine) and 1 or 0)
						totalNearby = totalNearby + ((getTileModel(this.row+1, 	this.col-1) and getTileModel(this.row+1, 	this.col-1).hasMine) and 1 or 0)
						totalNearby = totalNearby + ((getTileModel(this.row+1, 	this.col) 	and getTileModel(this.row+1, 	this.col).hasMine) 	and 1 or 0)
						totalNearby = totalNearby + ((getTileModel(this.row+1, 	this.col+1) and getTileModel(this.row+1, 	this.col+1).hasMine) and 1 or 0)				
						return totalNearby
					end,				
				}
				col = col + 1
				sum = sum + 1
			end
			row = row + 1
		end
		return t
	end,
	
	Image {
		id = "cheat",
		width = function()
			return root.width / 100
		end,
		height = function()
			return root.height / 100
		end,
		source = function()
			if calculateCheat() then
				return "images/Minesweeper/back.png"
			else
				return ""
			end		
		end,
	},
	
	GridRepeater {
		id = "grid",
		x = function()
			return (root.width - width) / 2
		end,
		width = function()
			return implicitWidth
		end,
		height = function()
			return root.height - face.height
		end,
		columns = 9,
		spacing = 6,
		model = function()
			return root.gridModel
		end,
		itemDelegate = function()
			return TileComponent {
			}
		end,
	},
	
	Image {
		id = "face",
		x = function()
			return (root.width - width) / 2
		end,
		y = function()
			return root.height - height
		end,
		width = function()
			return height * implicitWidth/implicitHeight
		end,
		height = function()
			return root.height / 10
		end,	
		source = function()
			if root.status == "inGame" then
				return "images/Minesweeper/face-smile.png"
			elseif root.status == "lost" then
				return "images/Minesweeper/face-sad.png"
			else
				return "images/Minesweeper/face-smile-big.png"
			end
		end,
		
		MouseArea {
			id = "mouseArea",
			width = function()
				return face.width
			end,
			height = function()
				return face.height
			end,
			onPressedChanged = function()
				if pressed == false then
					init()
				end
			end,
		},
	},		
}

