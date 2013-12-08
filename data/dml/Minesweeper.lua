ImportComponent("dml/TileComponent.lua")

function createGrid()
	t = {}
	t.id = "grid"
	t.width = function()
		return background.width
	end
	t.height = function()
		return background.height
	end
	
	local total = 9
	
	local sum = 0
	local row = 0
	while row < total do	
		local col = 0
		while col < total do
			t[sum] = TileComponent{	
				myId = sum,
				id = sum,
				col = col,
				row = row,
				total = total,
				hasMine = true
			}
			col = col + 1
			sum = sum + 1
		end
		row = row + 1
	end
	

	return t
end

GraphicItem {
	id = "root",
	
	Image {
		id = "background",
		source = "images/Minesweeper/background.png",
		width = function()
			return root.width
		end,
		height = function()
			return root.height
		end,
		
		GraphicItem(createGrid())
	},
}
