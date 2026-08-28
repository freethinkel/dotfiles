local colors = require("colors")

-- External (bluetooth) keyboard battery: the first HID battery entry that isn't built-in.
-- Hidden entirely while no external keyboard is connected.
local kb_battery = sbar.add("item", {
	position = "right",
	drawing = false,
	icon = {
		string = "􀇳",
		font = {
			size = 15.0,
		},
	},
	label = {
		font = {
			size = 12,
		},
	},
	update_freq = 120,
})

local function update()
	sbar.exec(
		[[ioreg -r -l -n AppleDeviceManagementHIDEventService 2>/dev/null | awk '/"Built-In" = No/{ext=1} /"BatteryPercent"/{if(ext){print $NF; exit}}']],
		function(result)
			local charge = tonumber(trim(result or ""))
			if not charge then
				kb_battery:set({ drawing = false })
				return
			end

			kb_battery:set({
				drawing = true,
				label = { string = charge .. "%" },
				icon = { color = charge <= 20 and colors.red or colors.foreground },
			})
		end
	)
end

kb_battery:subscribe({ "routine", "system_woke", "power_source_change" }, update)

-- first paint right away — the routine tick only comes update_freq later
update()
