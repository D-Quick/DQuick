ImportComponent("dml/Image2Component.lua")

function createImages()
	t = {}
	t.id = "root"
	
	local total = 50
	
	local sum = 0
	local row = 0
	while row < total do	
		local col = 0
		while col < total do
			t[sum] = Image2Component{	
				myId = sum,
				id = sum,
				col = col,
				row = row,
				total = total
			}
			col = col + 1
			sum = sum + 1
		end
		row = row + 1
	end
	

	return t
end

GraphicItem(createImages())
