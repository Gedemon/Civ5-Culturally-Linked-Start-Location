-- Lua AssignStartingPlot create function for G&K
-- Author: Gedemon
-- DateCreated: 6/20/2012 8:59:25 PM
--------------------------------------------------------------

print ("- Replacing Create() for G&K or BNW...")
function AssignStartingPlots.Create()
	-- There are three methods of dividing the map in to regions.
	-- OneLandmass, Continents, Oceanic. Default method is Continents.
	--
	-- Standard start plot finding uses a regional division method, then
	-- assigns one civ per region. Regions with lowest average fertility
	-- get their assignment first, to avoid the poor getting poorer.
	--
	-- Default methods for civ and city state placement both rely on having
	-- regional division data. If the desired process for a given map script
	-- would not define regions of this type, replace the start finder
	-- with your custom method.
	--
	-- Note that this operation relies on inclusion of the Mapmaker Utilities.
	local iW, iH = Map.GetGridSize();
	local feature_atoll;
	for thisFeature in GameInfo.Features() do
		if thisFeature.Type == "FEATURE_ATOLL" then
			feature_atoll = thisFeature.ID;
		end
	end

	-- Main data table ("self dot" table).
	--
	-- Scripters have the opportunity to replace member methods without
	-- having to replace the entire process.
	local findStarts = {

		-- Core Process member methods
		__Init = AssignStartingPlots.__Init,
		__InitLuxuryWeights = AssignStartingPlots.__InitLuxuryWeights,
		__CustomInit = AssignStartingPlots.__CustomInit,
		ApplyHexAdjustment = AssignStartingPlots.ApplyHexAdjustment,
		GenerateRegions = AssignStartingPlots.GenerateRegions,
		ChooseLocations = AssignStartingPlots.ChooseLocations,
		BalanceAndAssign = AssignStartingPlots.BalanceAndAssign,

		-- Culturally Linked Start Locations
		CalculateDistanceScore = AssignStartingPlots.CalculateDistanceScore,
		CalculateDistanceScoreCityStates = AssignStartingPlots.CalculateDistanceScoreCityStates,
		CulturallyLinkedCityStates = AssignStartingPlots.CulturallyLinkedCityStates,
		 -- / Culturally Linked Start Locations

		PlaceNaturalWonders = AssignStartingPlots.PlaceNaturalWonders,
		PlaceResourcesAndCityStates = AssignStartingPlots.PlaceResourcesAndCityStates,
		
		-- Generate Regions member methods
		MeasureStartPlacementFertilityOfPlot = AssignStartingPlots.MeasureStartPlacementFertilityOfPlot,
		MeasureStartPlacementFertilityInRectangle = AssignStartingPlots.MeasureStartPlacementFertilityInRectangle,
		MeasureStartPlacementFertilityOfLandmass = AssignStartingPlots.MeasureStartPlacementFertilityOfLandmass,
		RemoveDeadRows = AssignStartingPlots.RemoveDeadRows,
		DivideIntoRegions = AssignStartingPlots.DivideIntoRegions,
		ChopIntoThreeRegions = AssignStartingPlots.ChopIntoThreeRegions,
		ChopIntoTwoRegions = AssignStartingPlots.ChopIntoTwoRegions,
		CustomOverride = AssignStartingPlots.CustomOverride,

		-- Choose Locations member methods
		MeasureTerrainInRegions = AssignStartingPlots.MeasureTerrainInRegions,
		DetermineRegionTypes = AssignStartingPlots.DetermineRegionTypes,
		PlaceImpactAndRipples = AssignStartingPlots.PlaceImpactAndRipples,
		MeasureSinglePlot = AssignStartingPlots.MeasureSinglePlot,
		EvaluateCandidatePlot = AssignStartingPlots.EvaluateCandidatePlot,
		IterateThroughCandidatePlotList = AssignStartingPlots.IterateThroughCandidatePlotList,
		FindStart = AssignStartingPlots.FindStart,
		FindCoastalStart = AssignStartingPlots.FindCoastalStart,
		FindStartWithoutRegardToAreaID = AssignStartingPlots.FindStartWithoutRegardToAreaID,
		
		-- Balance and Assign member methods
		AttemptToPlaceBonusResourceAtPlot = AssignStartingPlots.AttemptToPlaceBonusResourceAtPlot,
		AttemptToPlaceHillsAtPlot = AssignStartingPlots.AttemptToPlaceHillsAtPlot,
		AttemptToPlaceSmallStrategicAtPlot = AssignStartingPlots.AttemptToPlaceSmallStrategicAtPlot,
		FindFallbackForUnmatchedRegionPriority = AssignStartingPlots.FindFallbackForUnmatchedRegionPriority,
		AddStrategicBalanceResources = AssignStartingPlots.AddStrategicBalanceResources,
		AttemptToPlaceStoneAtGrassPlot = AssignStartingPlots.AttemptToPlaceStoneAtGrassPlot,
		NormalizeStartLocation = AssignStartingPlots.NormalizeStartLocation,
		NormalizeTeamLocations = AssignStartingPlots.NormalizeTeamLocations,
		
		-- Natural Wonders member methods
		ExaminePlotForNaturalWondersEligibility = AssignStartingPlots.ExaminePlotForNaturalWondersEligibility,
		ExamineCandidatePlotForNaturalWondersEligibility = AssignStartingPlots.ExamineCandidatePlotForNaturalWondersEligibility,
		CanBeThisNaturalWonderType = AssignStartingPlots.CanBeThisNaturalWonderType,
		GenerateLocalVersionsOfDataFromXML = AssignStartingPlots.GenerateLocalVersionsOfDataFromXML,
		GenerateNaturalWondersCandidatePlotLists = AssignStartingPlots.GenerateNaturalWondersCandidatePlotLists,
		AttemptToPlaceNaturalWonder = AssignStartingPlots.AttemptToPlaceNaturalWonder,

		-- City States member methods
		AssignCityStatesToRegionsOrToUninhabited = AssignStartingPlots.AssignCityStatesToRegionsOrToUninhabited,
		CanPlaceCityStateAt = AssignStartingPlots.CanPlaceCityStateAt,
		ObtainNextSectionInRegion = AssignStartingPlots.ObtainNextSectionInRegion,
		PlaceCityState = AssignStartingPlots.PlaceCityState,
		PlaceCityStateInRegion = AssignStartingPlots.PlaceCityStateInRegion,
		PlaceCityStates = AssignStartingPlots.PlaceCityStates,	-- Dependent on AssignLuxuryRoles being executed first, so beware.
		NormalizeCityState = AssignStartingPlots.NormalizeCityState,
		NormalizeCityStateLocations = AssignStartingPlots.NormalizeCityStateLocations, -- Dependent on PlaceLuxuries being executed first.

		-- Resources member methods
		GenerateGlobalResourcePlotLists = AssignStartingPlots.GenerateGlobalResourcePlotLists,
		PlaceResourceImpact = AssignStartingPlots.PlaceResourceImpact,		-- Note: called from PlaceImpactAndRipples
		ProcessResourceList = AssignStartingPlots.ProcessResourceList,
		PlaceSpecificNumberOfResources = AssignStartingPlots.PlaceSpecificNumberOfResources,
		IdentifyRegionsOfThisType = AssignStartingPlots.IdentifyRegionsOfThisType,
		SortRegionsByType = AssignStartingPlots.SortRegionsByType,
		AssignLuxuryToRegion = AssignStartingPlots.AssignLuxuryToRegion,
		GetLuxuriesSplitCap = AssignStartingPlots.GetLuxuriesSplitCap,		-- New for Expansion, because we have more luxuries now.
		GetCityStateLuxuriesTargetNumber = AssignStartingPlots.GetCityStateLuxuriesTargetNumber,	-- New for Expansion
		GetDisabledLuxuriesTargetNumber = AssignStartingPlots.GetDisabledLuxuriesTargetNumber,
		AssignLuxuryRoles = AssignStartingPlots.AssignLuxuryRoles,
		GetListOfAllowableLuxuriesAtCitySite = AssignStartingPlots.GetListOfAllowableLuxuriesAtCitySite,
		GenerateLuxuryPlotListsAtCitySite = AssignStartingPlots.GenerateLuxuryPlotListsAtCitySite, -- Also doubles as Ice Removal.
		GenerateLuxuryPlotListsInRegion = AssignStartingPlots.GenerateLuxuryPlotListsInRegion,
		GetIndicesForLuxuryType = AssignStartingPlots.GetIndicesForLuxuryType,
		GetRegionLuxuryTargetNumbers = AssignStartingPlots.GetRegionLuxuryTargetNumbers,
		GetWorldLuxuryTargetNumbers = AssignStartingPlots.GetWorldLuxuryTargetNumbers,
		PlaceMarble = AssignStartingPlots.PlaceMarble,
		PlaceLuxuries = AssignStartingPlots.PlaceLuxuries,
		PlaceSmallQuantitiesOfStrategics = AssignStartingPlots.PlaceSmallQuantitiesOfStrategics,
		PlaceFish = AssignStartingPlots.PlaceFish,
		PlaceSexyBonusAtCivStarts = AssignStartingPlots.PlaceSexyBonusAtCivStarts,
		AddExtraBonusesToHillsRegions = AssignStartingPlots.AddExtraBonusesToHillsRegions,
		AddModernMinorStrategicsToCityStates = AssignStartingPlots.AddModernMinorStrategicsToCityStates,
		PlaceOilInTheSea = AssignStartingPlots.PlaceOilInTheSea,
		FixSugarJungles = AssignStartingPlots.FixSugarJungles, -- Sugar could not be made visible enough in jungle, so turn any sugar jungle to marsh.
		PrintFinalResourceTotalsToLog = AssignStartingPlots.PrintFinalResourceTotalsToLog,
		GetMajorStrategicResourceQuantityValues = AssignStartingPlots.GetMajorStrategicResourceQuantityValues,
		GetSmallStrategicResourceQuantityValues = AssignStartingPlots.GetSmallStrategicResourceQuantityValues,
		PlaceStrategicAndBonusResources = AssignStartingPlots.PlaceStrategicAndBonusResources,
		
		-- Civ start position variables
		startingPlots = {},				-- Stores x and y coordinates (and "score") of starting plots for civs, indexed by region number
		method = 2,						-- Method of regional division, default is 2
		iNumCivs = 0,					-- Number of civs at game start
		player_ID_list = {},			-- Correct list of player IDs (includes handling of any 'gaps' that occur in MP games)
		plotDataIsCoastal = {},			-- Stores table of NextToSaltWater plots to reduce redundant calculations
		plotDataIsNextToCoast = {},		-- Stores table of TwoAwayFromSaltWater plots to reduce redundant calculations
		regionData = {},				-- Stores data returned from regional division algorithm
		regionTerrainCounts = {},		-- Stores counts of terrain elements for all regions
		regionTypes = {},				-- Stores region types
		distanceData = table.fill(0, iW * iH), -- Stores "impact and ripple" data of start points as each is placed
		playerCollisionData = table.fill(false, iW * iH), -- Stores "impact" data only, of start points, to avoid player collisions
		startLocationConditions = {},   -- Stores info regarding conditions at each start location
		
		-- Team info variables (not used in the core process, but necessary to many Multiplayer map scripts)
		bTeamGame,
		iNumTeamsOfCivs,
		teams_with_major_civs,
		number_civs_per_team,
		
		-- Rectangular Division, dimensions within which all regions reside. (Unused by the other methods)
		inhabited_WestX,
		inhabited_SouthY,
		inhabited_Width,
		inhabited_Height,

		-- Natural Wonders variables
		naturalWondersData = table.fill(0, iW * iH), -- Stores "impact and ripple" data in the natural wonders layer
		bWorldHasOceans,
		iBiggestLandmassID,
		iNumNW = 0,
		wonder_list = {},
		eligibility_lists = {},
		xml_row_numbers = {},
		placed_natural_wonder = {},
		feature_atoll,
		
		-- City States variables
		cityStatePlots = {},			-- Stores x and y coordinates, and region number, of city state sites
		iNumCityStates = 0,				-- Number of city states at game start
		iNumCityStatesUnassigned = 0,	-- Number of City States still in need of placement method assignment
		iNumCityStatesPerRegion = 0,	-- Number of City States to be placed in each civ's region
		iNumCityStatesUninhabited = 0,	-- Number of City States to be placed on landmasses uninhabited by civs
		iNumCityStatesSharedLux = 0,	-- Number of City States to be placed in regions whose luxury type is shared with other regions
		iNumCityStatesLowFertility = 0,	-- Number of extra City States to be placed in regions with low fertility per land plot
		cityStateData = table.fill(0, iW * iH), -- Stores "impact and ripple" data in the city state layer
		city_state_region_assignments = table.fill(-1, 41), -- Stores region number of each city state (-1 if not in a region)
		uninhabited_areas_coastal_plots = {}, -- For use in placing city states outside of Regions
		uninhabited_areas_inland_plots = {},
		iNumCityStatesDiscarded = 0,	-- If a city state cannot be placed without being too close to another start, it will be discarded
		city_state_validity_table = table.fill(false, 41), -- Value set to true when a given city state is successfully assigned a start plot
		
		-- Resources variables
		resources = {},                 -- Stores all resource data, pulled from the XML
		resource_setting,				-- User selection for Resource Setting, chosen on game launch (when applicable)
		amounts_of_resources_placed = table.fill(0, 45), -- Stores amounts of each resource ID placed. WARNING: This table uses adjusted resource ID (+1) to account for Lua indexing. Add 1 to all IDs to index this table.
		luxury_assignment_count = table.fill(0, 45), -- Stores amount of each luxury type assigned to regions. WARNING: current implementation will crash if a Luxury is attached to resource ID 0 (default = iron), because this table uses unadjusted resource ID as table index.
		luxury_low_fert_compensation = table.fill(0, 45), -- Stores number of times each resource ID had extras handed out at civ starts. WARNING: Indexed by resource ID.
		region_low_fert_compensation = table.fill(0, 22); -- Stores number of luxury compensation each region received
		luxury_region_weights = {},		-- Stores weighted assignments for the types of regions
		luxury_fallback_weights = {},	-- In case all options for a given region type got assigned or disabled, also used for Undefined regions
		luxury_city_state_weights = {},	-- Stores weighted assignments for city state exclusive luxuries
		strategicData = table.fill(0, iW * iH), -- Stores "impact and ripple" data in the strategic resources layer
		luxuryData = table.fill(0, iW * iH), -- Stores "impact and ripple" data in the luxury resources layer
		bonusData = table.fill(0, iW * iH), -- Stores "impact and ripple" data in the bonus resources layer
		fishData = table.fill(0, iW * iH), -- Stores "impact and ripple" data in the fish layer
		marbleData = table.fill(0, iW * iH), -- Stores "impact and ripple" data in the marble layer
		sheepData = table.fill(0, iW * iH), -- Stores "impact and ripple" data in the sheep layer -- Sheep use regular bonus layer PLUS this one
		regions_sorted_by_type = {},	-- Stores table that includes region number and Luxury ID (this is where the two are first matched)
		region_luxury_assignment = {},	-- Stores luxury assignments, keyed by region number.
		iNumTypesUnassigned = 20,		-- Total number of luxuries. Adjust if modifying number of luxury resources.
		iNumMaxAllowedForRegions = 8,	-- Maximum luxury types allowed to be assigned to regional distribution. CANNOT be reduced below 8!
		iNumTypesAssignedToRegions = 0,
		resourceIDs_assigned_to_regions = {},
		iNumTypesAssignedToCS = 3,		-- Luxury types that will be placed only near city states
		resourceIDs_assigned_to_cs = {},
		iNumTypesSpecialCase = 1,		-- Marble affects Wonder construction, so requires special-case handling
		resourceIDs_assigned_to_special_case = {},
		iNumTypesRandom = 0,
		resourceIDs_assigned_to_random = {},
		iNumTypesDisabled = 0,
		resourceIDs_not_being_used = {},
		totalLuxPlacedSoFar = 0,

		-- Plot lists for use with global distribution of Luxuries.
		--
		-- NOTE: These lists are best synchronized with the equivalent plot list generations
		-- for regions and individual city sites, to keep Luxury behavior globally consistent.
		-- All three list sets are acted upon by a single set of indices, which apply only to 
		-- Luxury resources. These are controlled in the function GetIndicesForLuxuryType.
		-- 
		global_luxury_plot_lists = {},
		coast_next_to_land_list = {},
		marsh_list = {},
		flood_plains_list = {},
		hills_open_list = {},
		hills_covered_list = {},
		hills_jungle_list = {},
		hills_forest_list = {},
		jungle_flat_list = {},
		forest_flat_list = {},
		desert_flat_no_feature = {},
		plains_flat_no_feature = {},
		dry_grass_flat_no_feature = {},
		fresh_water_grass_flat_no_feature = {},
		tundra_flat_including_forests = {},
		forest_flat_that_are_not_tundra = {},
		feature_atoll = feature_atoll,
		
		-- Additional Plot lists for use with global distribution of Strategics and Bonus.
		--
		-- Unlike Luxuries, which have sophisticated handling to foster supply and demand
		-- in support of Trade and Diplomacy, the Strategic and Bonus resources are 
		-- allowed to conform to the terrain of a given map, with their quantities 
		-- available in any given game only loosely controlled. Thanks to the new method
		-- of quantifying strategic resources, the controls on their distribution no
		-- longer need to be as strenuous. Likewise with Bonus no longer affecting trade.
		grass_flat_no_feature = {},
		tundra_flat_no_feature = {},
		snow_flat_list = {},
		hills_list = {},
		land_list = {},
		coast_list = {},
		marble_list = {},
		extra_deer_list = {},
		desert_wheat_list = {},
		banana_list = {},
		barren_plots = 0,
		
		-- Positioner defaults. These are the controls for the "Center Bias" placement method for civ starts in regions.
		centerBias = 34, -- % of radius from region center to examine first
		middleBias = 67, -- % of radius from region center to check second
		minFoodInner = 1,
		minProdInner = 0,
		minGoodInner = 3,
		minFoodMiddle = 4,
		minProdMiddle = 0,
		minGoodMiddle = 6,
		minFoodOuter = 4,
		minProdOuter = 2,
		minGoodOuter = 8,
		maxJunk = 9,

		-- Hex Adjustment tables. These tables direct plot by plot scans in a radius 
		-- around a center hex, starting to Northeast, moving clockwise.
		firstRingYIsEven = {{0, 1}, {1, 0}, {0, -1}, {-1, -1}, {-1, 0}, {-1, 1}},
		secondRingYIsEven = {
		{1, 2}, {1, 1}, {2, 0}, {1, -1}, {1, -2}, {0, -2},
		{-1, -2}, {-2, -1}, {-2, 0}, {-2, 1}, {-1, 2}, {0, 2}
		},
		thirdRingYIsEven = {
		{1, 3}, {2, 2}, {2, 1}, {3, 0}, {2, -1}, {2, -2},
		{1, -3}, {0, -3}, {-1, -3}, {-2, -3}, {-2, -2}, {-3, -1},
		{-3, 0}, {-3, 1}, {-2, 2}, {-2, 3}, {-1, 3}, {0, 3}
		},
		firstRingYIsOdd = {{1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, 0}, {0, 1}},
		secondRingYIsOdd = {		
		{1, 2}, {2, 1}, {2, 0}, {2, -1}, {1, -2}, {0, -2},
		{-1, -2}, {-1, -1}, {-2, 0}, {-1, 1}, {-1, 2}, {0, 2}
		},
		thirdRingYIsOdd = {		
		{2, 3}, {2, 2}, {3, 1}, {3, 0}, {3, -1}, {2, -2},
		{2, -3}, {1, -3}, {0, -3}, {-1, -3}, {-2, -2}, {-2, -1},
		{-3, 0}, {-2, 1}, {-2, 2}, {-1, 3}, {0, 3}, {1, 3}
		},
		-- Direction types table, another method of handling hex adjustments, in combination with Map.PlotDirection()
		direction_types = {
			DirectionTypes.DIRECTION_NORTHEAST,
			DirectionTypes.DIRECTION_EAST,
			DirectionTypes.DIRECTION_SOUTHEAST,
			DirectionTypes.DIRECTION_SOUTHWEST,
			DirectionTypes.DIRECTION_WEST,
			DirectionTypes.DIRECTION_NORTHWEST
			},
		
		-- Handy resource ID shortcuts
		wheat_ID, cow_ID, deer_ID, banana_ID, fish_ID, sheep_ID, stone_ID,
		iron_ID, horse_ID, coal_ID, oil_ID, aluminum_ID, uranium_ID,
		whale_ID, pearls_ID, ivory_ID, fur_ID, silk_ID,
		dye_ID, spices_ID, sugar_ID, cotton_ID, wine_ID, incense_ID,
		gold_ID, silver_ID, gems_ID, marble_ID,
		-- Expansion luxuries
		copper_ID, salt_ID, citrus_ID, truffles_ID, crab_ID,
		
		-- Local arrays for storing Natural Wonder Placement XML data
		EligibilityMethodNumber = {},
		OccurrenceFrequency = {},
		RequireBiggestLandmass = {},
		AvoidBiggestLandmass = {},
		RequireFreshWater = {},
		AvoidFreshWater = {},
		LandBased = {},
		RequireLandAdjacentToOcean = {},
		AvoidLandAdjacentToOcean = {},
		RequireLandOnePlotInland = {},
		AvoidLandOnePlotInland = {},
		RequireLandTwoOrMorePlotsInland = {},
		AvoidLandTwoOrMorePlotsInland = {},
		CoreTileCanBeAnyPlotType = {},
		CoreTileCanBeFlatland = {},
		CoreTileCanBeHills = {},
		CoreTileCanBeMountain = {},
		CoreTileCanBeOcean = {},
		CoreTileCanBeAnyTerrainType = {},
		CoreTileCanBeGrass = {},
		CoreTileCanBePlains = {},
		CoreTileCanBeDesert = {},
		CoreTileCanBeTundra = {},
		CoreTileCanBeSnow = {},
		CoreTileCanBeShallowWater = {},
		CoreTileCanBeDeepWater = {},
		CoreTileCanBeAnyFeatureType = {},
		CoreTileCanBeNoFeature = {},
		CoreTileCanBeForest = {},
		CoreTileCanBeJungle = {},
		CoreTileCanBeOasis = {},
		CoreTileCanBeFloodPlains = {},
		CoreTileCanBeMarsh = {},
		CoreTileCanBeIce = {},
		CoreTileCanBeAtoll = {},
		AdjacentTilesCareAboutPlotTypes = {},
		AdjacentTilesAvoidAnyland = {},
		AdjacentTilesRequireFlatland = {},
		RequiredNumberOfAdjacentFlatland = {},
		AdjacentTilesRequireHills = {},
		RequiredNumberOfAdjacentHills = {},
		AdjacentTilesRequireMountain = {},
		RequiredNumberOfAdjacentMountain = {},
		AdjacentTilesRequireHillsPlusMountains = {},
		RequiredNumberOfAdjacentHillsPlusMountains = {},
		AdjacentTilesRequireOcean = {},
		RequiredNumberOfAdjacentOcean = {},
		AdjacentTilesAvoidFlatland = {},
		MaximumAllowedAdjacentFlatland = {},
		AdjacentTilesAvoidHills = {},
		MaximumAllowedAdjacentHills = {},
		AdjacentTilesAvoidMountain = {},
		MaximumAllowedAdjacentMountain = {},
		AdjacentTilesAvoidHillsPlusMountains = {},
		MaximumAllowedAdjacentHillsPlusMountains = {},
		AdjacentTilesAvoidOcean = {},
		MaximumAllowedAdjacentOcean = {},
		AdjacentTilesCareAboutTerrainTypes = {},
		AdjacentTilesRequireGrass = {},
		RequiredNumberOfAdjacentGrass = {},
		AdjacentTilesRequirePlains = {},
		RequiredNumberOfAdjacentPlains = {},
		AdjacentTilesRequireDesert = {},
		RequiredNumberOfAdjacentDesert = {},
		AdjacentTilesRequireTundra = {},
		RequiredNumberOfAdjacentTundra = {},
		AdjacentTilesRequireSnow = {},
		RequiredNumberOfAdjacentSnow = {},
		AdjacentTilesRequireShallowWater = {},
		RequiredNumberOfAdjacentShallowWater = {},
		AdjacentTilesRequireDeepWater = {},
		RequiredNumberOfAdjacentDeepWater = {},
		AdjacentTilesAvoidGrass = {},
		MaximumAllowedAdjacentGrass = {},
		AdjacentTilesAvoidPlains = {},
		MaximumAllowedAdjacentPlains = {},
		AdjacentTilesAvoidDesert = {},
		MaximumAllowedAdjacentDesert = {},
		AdjacentTilesAvoidTundra = {},
		MaximumAllowedAdjacentTundra = {},
		AdjacentTilesAvoidSnow = {},
		MaximumAllowedAdjacentSnow = {},
		AdjacentTilesAvoidShallowWater = {},
		MaximumAllowedAdjacentShallowWater = {},
		AdjacentTilesAvoidDeepWater = {},
		MaximumAllowedAdjacentDeepWater = {},
		AdjacentTilesCareAboutFeatureTypes = {},
		AdjacentTilesRequireNoFeature = {},
		RequiredNumberOfAdjacentNoFeature = {},
		AdjacentTilesRequireForest = {},
		RequiredNumberOfAdjacentForest = {},
		AdjacentTilesRequireJungle = {},
		RequiredNumberOfAdjacentJungle = {},
		AdjacentTilesRequireOasis = {},
		RequiredNumberOfAdjacentOasis = {},
		AdjacentTilesRequireFloodPlains = {},
		RequiredNumberOfAdjacentFloodPlains = {},
		AdjacentTilesRequireMarsh = {},
		RequiredNumberOfAdjacentMarsh = {},
		AdjacentTilesRequireIce = {},
		RequiredNumberOfAdjacentIce = {},
		AdjacentTilesRequireAtoll = {},
		RequiredNumberOfAdjacentAtoll = {},
		AdjacentTilesAvoidNoFeature = {},
		MaximumAllowedAdjacentNoFeature = {},
		AdjacentTilesAvoidForest = {},
		MaximumAllowedAdjacentForest = {},
		AdjacentTilesAvoidJungle = {},
		MaximumAllowedAdjacentJungle = {},
		AdjacentTilesAvoidOasis = {},
		MaximumAllowedAdjacentOasis = {},
		AdjacentTilesAvoidFloodPlains = {},
		MaximumAllowedAdjacentFloodPlains = {},
		AdjacentTilesAvoidMarsh = {},
		MaximumAllowedAdjacentMarsh = {},
		AdjacentTilesAvoidIce = {},
		MaximumAllowedAdjacentIce = {},
		AdjacentTilesAvoidAtoll = {},
		MaximumAllowedAdjacentAtoll = {},
		TileChangesMethodNumber = {},
		ChangeCoreTileToMountain = {},
		ChangeCoreTileToFlatland = {},
		ChangeCoreTileTerrainToGrass = {},
		ChangeCoreTileTerrainToPlains = {},
		SetAdjacentTilesToShallowWater = {},
		
	}
	
	findStarts:__Init()
	
	findStarts:__InitLuxuryWeights()
	
	-- Entry point for easy overrides, for instance if only a couple things need to change.
	findStarts:__CustomInit()
	
	return findStarts
end