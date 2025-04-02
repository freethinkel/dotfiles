function change_workspace(direction)
	hs.task.new("/opt/homebrew/bin/aerospace", function() end, { "workspace", direction }):start()
end

local current_id, threshold
Swipe = hs.loadSpoon("Swipe")
Swipe:start(3, function(direction, distance, id)
	if id == current_id then
		if distance > threshold then
			threshold = math.huge -- only trigger once per swipe

			print(hs.inspect(direction))
			-- use "natural" scrolling
			if direction == "left" then
				change_workspace("next")
			elseif direction == "right" then
				change_workspace("prev")
			end
		end
	else
		current_id = id
		threshold = 0.1 -- swipe distance > 10% of trackpad
	end
end)
