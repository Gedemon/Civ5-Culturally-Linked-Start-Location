-- Lua BalanceAndAssign
-- Author: Gedemon
-- DateCreated: 6/10/2012 7:10:49 PM
--------------------------------------------------------------

print ("- Replacing Common functions...")

function Round(num)
    under = math.floor(num)
    upper = math.floor(num) + 1
    underV = -(under - num)
    upperV = upper - num
    if (upperV > underV) then
        return under
    else
        return upper
    end
end

BRUTE_FORCE_TRIES = 3 -- raise this number for better placement but longer initialization. From tests, 3 passes should be more than enough.
OVERSEA_PENALTY = 50 -- distance penalty for starting plot separated by sea
SAME_GROUP_WEIGHT = 2 -- factor to use for distance in same cultural group

g_CultureRelativeDistance = {
	["ARTSTYLE_EUROPEAN"] = 0, -- center of the world (yes, that's a cliché)
	["ARTSTYLE_MIDDLE_EAST"] = 5,
	["ARTSTYLE_SOUTH_AMERICA"] = 20,
	["ARTSTYLE_ASIAN"] = 10,
	["ARTSTYLE_GRECO_ROMAN"] = 1,
	["ARTSTYLE_POLYNESIAN"] = 15,
}

function AssignStartingPlots:CalculateDistanceScore(cultureList, bOutput)
	if bOutput then print ("------------------------------------------------------- ") end
	if bOutput then  print ("Calculating distance score...") end
	local globalDistanceScore = 0
	local cultureDistanceScore = {}
	for civCulture, playerList in pairs(cultureList) do
		if bOutput then  print (" - culture = " .. tostring(civCulture)) end
		local distanceScore = 0
		for i, playerID in pairs(playerList) do
			local player = Players[playerID]
			if bOutput then  print ("    - player = " .. tostring(player:GetName())) end
			for loop = 1, self.iNumCivs do				
				local player_ID2 = self.player_ID_list[loop]
				local player2 = Players[player_ID2]
				local civCulture2 = GameInfo.Civilizations[player2:GetCivilizationType()].ArtStyleType
				if  civCulture2 == civCulture then
					local startPlot1 = player:GetStartingPlot()
					local startPlot2 = player2:GetStartingPlot()
					local distance = Map.PlotDistance(startPlot1:GetX(), startPlot1:GetY(), startPlot2:GetX(), startPlot2:GetY())
					if startPlot1:GetArea() ~= startPlot2:GetArea() then
						distance = distance + OVERSEA_PENALTY
					end
					distanceScore = distanceScore + Round(distance*SAME_GROUP_WEIGHT)
					if bOutput then print ("      - Distance to same culture (" .. tostring(player2:GetName()) .. ") = " .. tostring(distance) .. " (x".. tostring(SAME_GROUP_WEIGHT) .."), total distance score = " .. tostring(distanceScore) ) end
				else
					local interGroupMinimizer = 1
					if g_CultureRelativeDistance[civCulture] and g_CultureRelativeDistance[civCulture2] then
						interGroupMinimizer = math.abs(g_CultureRelativeDistance[civCulture] - g_CultureRelativeDistance[civCulture2])
					else
						interGroupMinimizer = 8 -- unknown culture group (new DLC ?), average distance
					end
					local startPlot1 = player:GetStartingPlot()
					local startPlot2 = player2:GetStartingPlot()
					local distance = Map.PlotDistance(startPlot1:GetX(), startPlot1:GetY(), startPlot2:GetX(), startPlot2:GetY())
					distanceScore = distanceScore + Round(distance/interGroupMinimizer)
					if bOutput then print ("      - Distance to different culture (" .. tostring(player2:GetName()) .. ") = " .. tostring(distance) .. " (/".. tostring(interGroupMinimizer) .." from intergroup relative distance), total distance score = " .. tostring(distanceScore) ) end
				end
			end
		end
		cultureDistanceScore[civCulture] = distanceScore
		globalDistanceScore = globalDistanceScore + distanceScore
	end		
	if bOutput then print ("Global distance score = " .. tostring(globalDistanceScore)) end
	if bOutput then print ("------------------------------------------------------- ") end
	return globalDistanceScore
end

function AssignStartingPlots:BalanceAndAssign()
	-- This function determines what level of Bonus Resource support a location
	-- may need, identifies compatibility with civ-specific biases, and places starts.

	-- Normalize each start plot location.
	local iNumStarts = table.maxn(self.startingPlots);
	for region_number = 1, iNumStarts do
		self:NormalizeStartLocation(region_number)
	end

	local playerList = {}

	local cultureList = {}
	local cultureCount = {}

	local areaList = {}
	local areaCount= {}

	local bestList = {}
	local bestDistanceScore = 99999
	
	print ("------------------------------------------------------- ")
	print ("Creating list for Culturally linked startingposition... ")
	for loop = 1, self.iNumCivs do

		-- creating player lists
		local player_ID = self.player_ID_list[loop]
		local player = Players[player_ID]
		local civCulture = GameInfo.Civilizations[player:GetCivilizationType()].ArtStyleType
		table.insert(playerList, player_ID)
		if cultureList[civCulture] then
			table.insert(cultureList[civCulture], player_ID)
			cultureCount[civCulture] = cultureCount[civCulture] + 1
		else
			cultureList[civCulture] = {}
			table.insert(cultureList[civCulture], player_ID)
			cultureCount[civCulture] = 1
		end
		print (" - Adding player " .. tostring(player:GetName()) .. " to culture " .. tostring(civCulture))

		-- creating start plot area list
		local x = self.startingPlots[loop][1]
		local y = self.startingPlots[loop][2]
		local plot = Map.GetPlot(x, y)
		local area = plot:GetArea()
		if areaList[area] then
			table.insert(areaList[area], {X = x, Y = y})
			areaCount[area] = areaCount[area] + 1
		else
			areaList[area] = {}
			areaCount[area] = 1
			table.insert(areaList[area], {X = x, Y = y})
		end

	end
	print ("------------------------------------------------------- ")

	-- Sort culture table by number of civs...
	local cultureTable = {}
	for civCulture, num in pairs(cultureCount) do	
		table.insert(cultureTable, {Culture = civCulture, Num = num})
	end
	table.sort(cultureTable, function(a,b) return a.Num > b.Num end)
	for i, data in ipairs(cultureTable) do	
		print ("Culture " .. tostring(data.Culture) .. " represented by " .. tostring(data.Num) .. " civs")
	end
	print ("------------------------------------------------------- ")

	-- Sort area table by number of starting plots...
	local areaTable = {}
	for id, num in pairs(areaCount) do	
		table.insert(areaTable, {ID = id, Num = num})
	end
	table.sort(areaTable, function(a,b) return a.Num > b.Num end)
	for i, data in ipairs(areaTable) do	
		print ("Area ID = " .. tostring(data.ID) .. " has " .. tostring(data.Num) .. " starting plots")
	end
	print ("------------------------------------------------------- ")


	local playerListShuffled = GetShuffledCopyOfTable(playerList)
	for region_number, player_ID in ipairs(playerListShuffled) do
		local x = self.startingPlots[region_number][1]
		local y = self.startingPlots[region_number][2]
		local start_plot = Map.GetPlot(x, y)
		local player = Players[player_ID]
		player:SetStartingPlot(start_plot)
	end
	
	local initialDistanceScore = self:CalculateDistanceScore(cultureList, true)
	if  initialDistanceScore < bestDistanceScore then
		bestDistanceScore = initialDistanceScore
	end

	-- todo : do and lock initial placement of the biggest cultural group in game
	-- on the area with most starting plots, then use brute force for the remaining civs

	-- todo : add cultural relative distance (ie Mediterannean should be closer from European than American or Asian culture)

	-- very brute force
	for try = 1, BRUTE_FORCE_TRIES do 
		print ("------------------------------------------------------- ")
		print ("Brute Force Pass num = " .. tostring(try) )
		for loop = 1, self.iNumCivs do				
			local player_ID = self.player_ID_list[loop]
			local player = Players[player_ID]
			--print ("------------------------------------------------------- ")
			--print ("Testing " .. tostring(player:GetName()) )
			local culture = GameInfo.Civilizations[player:GetCivilizationType()].ArtStyleType
			for loop2 = 1, self.iNumCivs do	
				--print ("in loop 2")
				if loop ~= loop2 then
					--print ("loop ~= loop2")
					local player_ID2 = self.player_ID_list[loop2]
					local player2 = Players[player_ID2]
					local culture2 = GameInfo.Civilizations[player2:GetCivilizationType()].ArtStyleType
					if culture ~= culture2 then -- don't try to swith civs from same culture style, we can gain better score from different culture only...
						--print ("culture ~= culture2")
						local startPlot1 = player:GetStartingPlot()
						local startPlot2 = player2:GetStartingPlot()
						--print ("------------------------------------------------------- ")
						--print ("trying to switch " .. tostring(player:GetName()) .. " with " .. tostring(player2:GetName()) )
						player:SetStartingPlot(startPlot2)
						player2:SetStartingPlot(startPlot1)
						local actualdistanceScore = self:CalculateDistanceScore(cultureList)
						if  actualdistanceScore < bestDistanceScore then
							bestDistanceScore = actualdistanceScore
							--print ("------------------------------------------------------- ")
							--print ("Better score, confirming switching position of " .. tostring(player:GetName()) .. " with " .. tostring(player2:GetName()) )
						else
							--print ("------------------------------------------------------- ")
							--print ("No gain, restoring position of " .. tostring(player:GetName()) .. " and " .. tostring(player2:GetName()) )								
							player:SetStartingPlot(startPlot1)
							player2:SetStartingPlot(startPlot2)
						end
					end
				end
			end
		end

		--print ("------------------------------------------------------- ")
		--print ("Brute Force Pass num " .. tostring(try) )
		print ("New global distance = " .. tostring(self:CalculateDistanceScore(cultureList)))
	end
	self:CalculateDistanceScore(cultureList, true)
	print ("------------------------------------------------------- ")
	print ("INITIAL DISTANCE SCORE = " .. tostring(initialDistanceScore))
	print ("------------------------------------------------------- ")
	print ("FINAL DISTANCE SCORE: " .. tostring(self:CalculateDistanceScore(cultureList)) )
	print ("------------------------------------------------------- ")
end

function AssignStartingPlots:CalculateDistanceScoreCityStates(bOutput)
	if bOutput then print ("------------------------------------------------------- ") end
	if bOutput then  print ("Calculating distance score for City States...") end
	local globalDistanceScore = 0
	
	for playerID = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1 do		
		local player = Players[playerID]		
		local distanceScore = 0
		if player:IsEverAlive() then
			local startPlot1 = player:GetStartingPlot()
			local civCulture = GameInfo.MinorCivilizations[player:GetMinorCivType()].ArtStyleType
			if startPlot1 ~= nil then

				if bOutput then  print ("    - player = " .. tostring(player:GetName())) end

				for loop = 1, self.iNumCivs do				
					local player_ID2 = self.player_ID_list[loop]
					local player2 = Players[player_ID2]
					local civCulture2 = GameInfo.Civilizations[player2:GetCivilizationType()].ArtStyleType
					if  civCulture2 == civCulture then
						local startPlot2 = player2:GetStartingPlot()
						local distance = Map.PlotDistance(startPlot1:GetX(), startPlot1:GetY(), startPlot2:GetX(), startPlot2:GetY())
						if startPlot1:GetArea() ~= startPlot2:GetArea() then
							distance = distance + OVERSEA_PENALTY
						end
						distanceScore = distanceScore + Round(distance*SAME_GROUP_WEIGHT)
						if bOutput then print ("      - Distance to same culture (" .. tostring(player2:GetName()) .. ") = " .. tostring(distance) .. " (x".. tostring(SAME_GROUP_WEIGHT) .."), total distance score = " .. tostring(distanceScore) ) end
					else
						local interGroupMinimizer = 1
						if g_CultureRelativeDistance[civCulture] and g_CultureRelativeDistance[civCulture2] then
							interGroupMinimizer = math.abs(g_CultureRelativeDistance[civCulture] - g_CultureRelativeDistance[civCulture2])
						else
							interGroupMinimizer = 8 -- unknown culture group, average distance
						end
						local startPlot2 = player2:GetStartingPlot()
						local distance = Map.PlotDistance(startPlot1:GetX(), startPlot1:GetY(), startPlot2:GetX(), startPlot2:GetY())
						distanceScore = distanceScore + Round(distance/interGroupMinimizer)
						if bOutput then print ("      - Distance to different culture (" .. tostring(player2:GetName()) .. ") = " .. tostring(distance) .. " (/".. tostring(interGroupMinimizer) .." from intergroup relative distance), total distance score = " .. tostring(distanceScore) ) end
					end
				end
			end
		end
		globalDistanceScore = globalDistanceScore + distanceScore
	end		
	if bOutput then print ("Global distance score = " .. tostring(globalDistanceScore)) end
	if bOutput then print ("------------------------------------------------------- ") end
	return globalDistanceScore
end

-- try to place city states closes to corresponding culture civs
function AssignStartingPlots:CulturallyLinkedCityStates()

	local bestDistanceScore = 99999
	
	print ("------------------------------------------------------- ")
	print ("Set Culturally linked starting positions for City States... ")

	local initialDistanceScore = self:CalculateDistanceScoreCityStates()
	if  initialDistanceScore < bestDistanceScore then
		bestDistanceScore = initialDistanceScore
	end

	-- very brute force again
	for try = 1, BRUTE_FORCE_TRIES do 
		print ("------------------------------------------------------- ")
		print ("Brute Force Pass num = " .. tostring(try) )
		for i = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1 do
			local player = Players[i]
			if player:IsEverAlive() then
				local culture = GameInfo.MinorCivilizations[player:GetMinorCivType()].ArtStyleType

				for i2 = GameDefines.MAX_MAJOR_CIVS, GameDefines.MAX_CIV_PLAYERS - 1 do
					local player2 = Players[i2]
					if i ~= i2 and player2:IsEverAlive() then
						local startPlot1 = player:GetStartingPlot()
						local startPlot2 = player2:GetStartingPlot()
						--print ("  - Player = " .. tostring(player:GetName()) .. ", Start Plot = " .. tostring(startPlot1) )
						--print ("  - Player = " .. tostring(player2:GetName()) .. ", Start Plot = " .. tostring(startPlot2) )
						local culture2 = GameInfo.MinorCivilizations[player2:GetMinorCivType()].ArtStyleType
						if (startPlot1 ~= nil) and (startPlot2 ~= nil) then
							if culture ~= culture2 then -- don't try to swith civs from same culture style, we can gain better score from different culture only...
								--print ("culture ~= culture2")
								--print ("------------------------------------------------------- ")
								--print ("trying to switch " .. tostring(player:GetName()) .. " with " .. tostring(player2:GetName()) )
								player:SetStartingPlot(startPlot2)
								player2:SetStartingPlot(startPlot1)
								local actualdistanceScore = self:CalculateDistanceScoreCityStates()
								if  actualdistanceScore < bestDistanceScore then
									bestDistanceScore = actualdistanceScore
									--print ("------------------------------------------------------- ")
									--print ("Better score, conforming switching position of " .. tostring(player:GetName()) .. " with " .. tostring(player2:GetName()) )
								else
									--print ("------------------------------------------------------- ")
									--print ("No gain, restoring position of " .. tostring(player:GetName()) .. " and " .. tostring(player2:GetName()) )								
									player:SetStartingPlot(startPlot1)
									player2:SetStartingPlot(startPlot2)
								end
							end
						end						
					end
				end			
			end
		end
		print ("New global distance = " .. tostring(self:CalculateDistanceScoreCityStates()))
	end
	print ("------------------------------------------------------- ")
	print ("CS INITIAL DISTANCE SCORE = " .. tostring(initialDistanceScore))
	print ("------------------------------------------------------- ")
	print ("CS FINAL DISTANCE SCORE = " .. tostring(self:CalculateDistanceScoreCityStates()))
	print ("------------------------------------------------------- ")
end

function AssignStartingPlots:PlaceResourcesAndCityStates()
	-- This function controls nearly all resource placement. Only resources
	-- placed during Normalization operations are handled elsewhere.
	--
	-- Luxury resources are placed in relationship to Regions, adapting to the
	-- details of the given map instance, including number of civs and city 
	-- states present. At Jon's direction, Luxuries have been implemented to
	-- be diplomatic widgets for trading, in addition to sources of Happiness.
	--
	-- Strategic and Bonus resources are terrain-adjusted. They will customize
	-- to each map instance. Each terrain type has been measured and has certain 
	-- resource types assigned to it. You can customize resource placement to 
	-- any degree desired by controlling generation of plot groups to feed in
	-- to the process. The default plot groups are terrain-based, but any
	-- criteria you desire could be used to determine plot group membership.
	-- 
	-- If any default methods fail to meet a specific need, don't hesitate to 
	-- replace them with custom methods. I have labored to make this new 
	-- system as accessible and powerful as any ever before offered.

	print("Map Generation - Assigning Luxury Resource Distribution");
	self:AssignLuxuryRoles()

	print("Map Generation - Placing City States");
	self:PlaceCityStates()

	-- Generate global plot lists for resource distribution.
	self:GenerateGlobalResourcePlotLists()
	
	print("Map Generation - Placing Luxuries");
	self:PlaceLuxuries()

	-- Place Strategic and Bonus resources.
	self:PlaceStrategicAndBonusResources()

	print("Map Generation - Normalize City State Locations");
	self:NormalizeCityStateLocations()
	
	-- Fix Sugar graphics
	self:FixSugarJungles()
	
	
	-- Culturally Linked Start Locations
	self:CulturallyLinkedCityStates()		
	-- /Culturally Linked Start Locations

	-- Necessary to implement placement of Natural Wonders, and possibly other plot-type changes.
	-- This operation must be saved for last, as it invalidates all regional data by resetting Area IDs.
	Map.RecalculateAreas();

	-- Activate for debug only
	--self:PrintFinalResourceTotalsToLog()
	--
end