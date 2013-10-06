-- Lua AssignStartingPlot chooser
-- Author: Gedemon
-- DateCreated: 6/20/2012 8:40:31 PM
--------------------------------------------------------------

print ("---------------------------------------------")
print ("Build AssignStartingPlot for Culturally Linked Location...")
function Initialize()
	local bGodsAndKings = ContentManager.IsActive("0E3751A1-F840-4e1b-9706-519BF484E59D", ContentType.GAMEPLAY)
	local bBraveNewWorld= ContentManager.IsActive("6DA07636-4123-4018-B643-6575B4EC336B", ContentType.GAMEPLAY);
	  
	if (bGodsAndKings or bBraveNewWorld) then -- using Brave New World or Gods And Kings
		include("ASP_GodsAndKings")
		include("ASP_Create_GodsAndKings")
	else -- using vanilla civ5
		include("ASP_Vanilla")
		include("ASP_Create_Vanilla")
	end
	include("ASP_Common")
end
Initialize()