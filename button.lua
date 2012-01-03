local btn = {}

	btn.createButton = function(btnText,x,y,width,height,callback)

		-- AUDIO
		local tapSound = audio.loadSound( "tapsound.wav" )
				
	 	local button = display.newRect(x, y, width, height)
		button.strokeWidth = 2
		button:setFillColor(255, 255, 255)
		button:setStrokeColor(180, 180, 180)

		local myText = display.newText(btnText, x, y, native.systemFont, 16)
		myText:setTextColor(0, 0, 0)
	
		local function buttonPressed(event)
			if event.phase == "began" then
				button:setFillColor(196, 226, 255)
				audio.play( tapSound )
			end
			
			if event.phase == "ended" then
				button:setFillColor(255, 255, 255)
				callback()
			end
		end
		
		button:addEventListener ("touch", buttonPressed)
	end

return btn