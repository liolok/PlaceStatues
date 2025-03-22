-- This information tells other players more about the mod
name = "Place Statues"


description = "Client mod allow you to drop statues on the right point in other people server and do art with statues.\n Press R to enable Walking.\n Press  to walk to chosen point (Accuracy is 0.01 size of the statue).\n Press Z to drop statue to current place you standing.\n Press Ctr+P to change type of drop.\n Press Ctr+O to tweak drop by 0.5 grid."
author = "Tranoze"
version = "1.1.0"

api_version = 10

local opt_Empty = {{description = "", data = 0}}
local function Title(title,hover)
	return {
		name=title,
		--label=title,
		hover=hover,
		options=opt_Empty,
		default=0,
	}
end
local SEPARATOR = Title("")

local KEY_A = 65
local keyslist = {}
local string = "" -- can't believe I have to copy this... -____-
for i = 1, 26 do
	local ch = string.char(KEY_A + i - 1)
	keyslist[i] = {description = ch, data = ch}
end

configuration_options =
{
	Title("Control setting"),
    {
        name = "CENTERBUTTON",
        label = "Center Button ",
        options = keyslist,
        default = "P",
		hover = "A key to set center point of most of the Statues placement.\n(Ctr + key to change placement type)",
    }, 
	{
        name = "SECONDPOINTDO",
        label = "Second Point Button",
        options = keyslist,
        default = "O",
		hover = "A key to set second point for line or some of the Statues placement.\n (Ctr + key to tweak placement by a bit)",
    }, 
	{
        name = "DROPDEBUTT",
        label = "Drop Button",
        options = keyslist,
        default = "Z",
		hover = "A key to drop statue down the ground",
    }, 
	{
        name = "WALKINGTOGGLE",
        label = "Walking toggle Button",
        options = keyslist,
        default = "R",
		hover = "A key to show you where you going to drop the statue",
    }, 
}
all_clients_require_mod = false
client_only_mod = true
dont_starve_compatible = false
dst_compatible = true
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- Can specify a custom icon for this mod!
icon_atlas = "modicon.xml"
icon = "modicon.tex"
