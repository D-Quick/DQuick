ImportComponent("dml/TileComponent.lua")

function	getTile(row, col)
	return _ENV[string.format("tile_%d_%d", row, col)]
end

function calculateNearbyCount(row, col)
	local totalNearby = 0;
	totalNearby = totalNearby + ((getTile(row-1, col-1) and getTile(row-1, 	col-1).hasMine) and 1 or 0)
	totalNearby = totalNearby + ((getTile(row-1, col) 	and getTile(row-1, 	col).hasMine) 	and 1 or 0)
	totalNearby = totalNearby + ((getTile(row-1, col+1) and getTile(row-1, 	col+1).hasMine) and 1 or 0)
	totalNearby = totalNearby + ((getTile(row, 	col-1) 	and getTile(row, 	col-1).hasMine) and 1 or 0)
	totalNearby = totalNearby + ((getTile(row, 	col) 	and getTile(row, 	col	).hasMine) and 1 or 0)	
	totalNearby = totalNearby + ((getTile(row, 	col+1) 	and getTile(row, 	col+1).hasMine) and 1 or 0)
	totalNearby = totalNearby + ((getTile(row+1, col-1) and getTile(row+1, 	col-1).hasMine) and 1 or 0)
	totalNearby = totalNearby + ((getTile(row+1, col) 	and getTile(row+1, 	col).hasMine) 	and 1 or 0)
	totalNearby = totalNearby + ((getTile(row+1, col+1) and getTile(row+1, 	col+1).hasMine) and 1 or 0)
	return totalNearby
end

function calculateStatus()
	local allFlipped = true
	local row = 0	
	while getTile(row, 0) do	
		local col = 0
		while getTile(row, col) do
			if getTile(row, col).flipped and getTile(row, col).hasMine then
				return "lost"
			end
			if getTile(row, col).flipped == false and getTile(row, col).hasMine == false then
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
	local allFlipped = true
	local row = 0	
	while getTile(row, 0) do	
		local col = 0
		while getTile(row, col) do
			if getTile(row, col).containsMouse and getTile(row, col).hasMine then
				
				return true
			end
			col = col + 1
		end
		row = row + 1
	end	
	return false
end

function init()
	local allFlipped = true
	local row = 0	
	while getTile(row, 0) do	
		local col = 0
		while getTile(row, col) do
			getTile(row, col).hasMine = randomBool()
			getTile(row, col).flipped = false
			col = col + 1
		end
		row = row + 1
	end	
	return false
end

function createGrid()
	t = {}
	t.id = "grid"
	t.width = function()
		return root.width
	end
	t.height = function()
		return root.height - face.height
	end
	
	local total = 6
	
	local sum = 0
	local row = 0	
	while row < total do	
		local col = 0
		while col < total do
			t[sum] = TileComponent{	
				id = string.format("tile_%d_%d", row, col),
				col = col,
				row = row,
				total = total,
			}
			col = col + 1
			sum = sum + 1
		end
		row = row + 1
	end

	init()
	
	return t
end


Image {
	id = "root",
	source = "images/Minesweeper/background.png",
	status = function()
		return calculateStatus()
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
	
	GraphicItem(createGrid())
}

