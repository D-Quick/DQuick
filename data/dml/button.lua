function Button(t)
	print(t.width)
	local Buttonimage3 = Image {
		id = "Buttonimage",
		width = 100,	-- property binding, when image change width is automatically updated
		height = 50,
		-- opGet = function(propertyName)
			-- return ButtonmouseArea[propertyName]
		-- end,
		-- opSet = function(propertyName, value)
			-- ButtonmouseArea[propertyName] = value
		-- end,
		

		source = function ()
			if ButtonmouseArea.pressed then	-- property binding, when mouseArea state change this condition is updated directly
				return "images/Alpha-blue-trans.png"
			else
				return "images/pngtest.png"
			end
		end,

		MouseArea {					-- parent/child object encapsulation
			id = "ButtonmouseArea",
			width = function ()
				return Buttonimage.width
			end,
			height = function ()
				return Buttonimage.height
			end,
		},
	}
	for key, value in pairs(t) do
		print(value)
		Buttonimage3[key] = value
	end
	return Buttonimage3
end