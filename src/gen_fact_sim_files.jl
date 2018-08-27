# for generating simulation objects based on a config file

type FactConfig
	outputPath::String
	factoryFilename::String
	mode::String

	numNodes::Int # total number of nodes
	maxConnectDist::Float # max connection distance of nodes

	genConfig::JEMSS.GenConfig

	FactConfig() = new(
	"","","",
		nullIndex, nullDist,
		JEMSS.GenConfig())
end

function readFactConfig(factConfigFilename::String)
	# read gen config xml file
	rootElt = xmlFileRoot(factConfigFilename)
	@assert(name(rootElt) == "factConfig", string("xml root has incorrect name: ", name(rootElt)))

	factConfig = FactConfig()
	genConfig = JEMSS.GenConfig()

	factConfig.outputPath = abspath(eltContentInterpVal(rootElt, "outputPath"))
	factConfig.mode = eltContent(rootElt, "mode")


	factFilesElt = findElt(rootElt, "factFiles")
	factConfig.factoryFilename = eltContent(factFilesElt, "factoryData")

	factElt = findElt(rootElt, "factory")
	factConfig.numNodes = eltContentVal(factElt, "numNodes")
	factConfig.maxConnectDist = eltContentVal(factElt, "maxConnectDist")

	factConfig.outputPath = abspath(eltContentInterpVal(rootElt, "outputPath"))

	genConfigElt = findElt(rootElt, "genConfig")






	# output filenames
	simFilesElt = findElt(genConfigElt, "simFiles")
	simFilePath(filename::String) = joinpath(factConfig.outputPath, JEMSS.eltContent(simFilesElt, filename))
	genConfig.ambsFilename = simFilePath("ambulances")
	genConfig.arcsFilename = simFilePath("arcs")
	genConfig.callsFilename = simFilePath("calls")
	genConfig.hospitalsFilename = simFilePath("hospitals")
	genConfig.mapFilename = simFilePath("map")
	genConfig.nodesFilename = simFilePath("nodes")
	genConfig.prioritiesFilename = simFilePath("priorities")
	genConfig.stationsFilename = simFilePath("stations")
	genConfig.travelFilename = simFilePath("travel")

	# read sim parameters
	simElt = findElt(genConfigElt, "sim")

	# create map
	# map is needed before generating random locations
	mapElt = findElt(simElt, "map")
	map = Map()
	map.xMin = eltContentVal(mapElt, "xMin")
	map.xMax = eltContentVal(mapElt, "xMax")
	map.xScale = eltContentVal(mapElt, "xScale")
	map.xRange = map.xMax - map.xMin
	map.yMin = eltContentVal(mapElt, "yMin")
	map.yMax = eltContentVal(mapElt, "yMax")
	map.yScale = eltContentVal(mapElt, "yScale")
	map.yRange = map.yMax - map.yMin
	assert(map.xRange > 0 && map.yRange > 0)
	genConfig.map = map

	# call distributions and random number generators
	callDistrsElt = findElt(simElt, "callDistributions")
	function callDistrsEltContent(distrName::String)
		distrElt = findElt(callDistrsElt, distrName)
		distr = eltContentVal(distrElt)
		seedAttr = attribute(distrElt, "seed")
		seed = (seedAttr == nothing ? nullIndex : eval(parse(seedAttr)))
		return DistrRng(distr; seed = seed)
	end
	genConfig.interarrivalTimeDistrRng = callDistrsEltContent("interarrivalTime")
	genConfig.priorityDistrRng = callDistrsEltContent("priority")
	genConfig.dispatchDelayDistrRng = callDistrsEltContent("dispatchDelay")
	genConfig.onSceneDurationDistrRng = callDistrsEltContent("onSceneDuration")
	genConfig.transferDistrRng = callDistrsEltContent("transfer")
	genConfig.transferDurationDistrRng = callDistrsEltContent("transferDuration")

	# number of ambulances, calls, hospitals, stations
	genConfig.numAmbs = eltContentVal(simElt, "numAmbs")
	genConfig.numCalls = eltContentVal(simElt, "numCalls")
	genConfig.numHospitals = eltContentVal(simElt, "numHospitals")
	genConfig.numStations = eltContentVal(simElt, "numStations")


	# misc values
	genConfig.startTime = eltContentVal(simElt, "startTime")
	assert(genConfig.startTime >= 0)
	genConfig.targetResponseTime = eltContentVal(simElt, "targetResponseTime")
	genConfig.offRoadSpeed = eltContentVal(simElt, "offRoadSpeed") # km / day
	genConfig.stationCapacity = eltContentVal(simElt, "stationCapacity")

	# call gen parameters
	# call density raster
	callDensityRasterElt = findElt(simElt, "callDensityRaster")
	genConfig.callDensityRasterFilename = abspath(eltContentInterpVal(callDensityRasterElt, "filename"))
	genConfig.cropRaster = eltContentVal(callDensityRasterElt, "cropRaster")
	# seeds
	function callRasterSeedVal(seedName::String)
		seedAttr = attribute(callDensityRasterElt, seedName)
		return seedAttr == nothing ? nullIndex : eval(parse(seedAttr))
	end
	genConfig.callRasterCellSeed = callRasterSeedVal("cellSeed")
	genConfig.callRasterCellLocSeed = callRasterSeedVal("cellLocSeed")

	# some defaults - should move to config file sometime
	genConfig.ambStationRng = MersenneTwister(0)
	genConfig.callLocRng = MersenneTwister(1)
	genConfig.hospitalLocRng = MersenneTwister(4)
	genConfig.stationLocRng = MersenneTwister(5)
	genConfig.travelTimeFactorDistrRng = DistrRng(Uniform(1.0, 1.1); seed = 99)

	factConfig.genConfig = genConfig

	return factConfig
end


function runFactConfig(factConfigFilename::String; overwriteOutputPath::Bool = false)
	factConfig = readFactConfig(factConfigFilename)

	if isdir(factConfig.outputPath) && !overwriteOutputPath
		println("Output path already exists: ", factConfig.outputPath)
		print("Delete folder contents and continue anyway? (y = yes): ")
		response = chomp(readline())
		if response != "y"
			println("stopping")
			return
		else
			overwriteOutputPath = true
		end
	end
	if isdir(factConfig.outputPath) && overwriteOutputPath
		println("Deleting folder contents: ", factConfig.outputPath)
		rm(factConfig.outputPath; recursive=true)
	end
	if !isdir(factConfig.outputPath)
		mkdir(factConfig.outputPath)
	end

	println("Generation mode: ", factConfig.mode)
	if factConfig.mode == "all"
		# make all
		ambulances = JEMSS.makeAmbs(factConfig.genConfig)
		calls = JEMSS.makeCalls(factConfig.genConfig)
		hospitals = JEMSS.makeHospitals(factConfig.genConfig)
		stations = JEMSS.makeStations(factConfig.genConfig)
		travel = JEMSS.makeTravel(factConfig.genConfig)

		graph = LightGraphs.SimpleGraph(factConfig.numNodes)
		#
		nodes = makeFactoryNodes(factConfig, graph)
		(arcs, travelTimes) = makeFactoryArcs(factConfig, graph, nodes)

		# save all
		println("Saving output to: ", factConfig.outputPath)
		writeAmbsFile(factConfig.genConfig.ambsFilename, ambulances)
		writeArcsFile(factConfig.genConfig.arcsFilename, arcs, travelTimes, "undirected")
		writeCallsFile(factConfig.genConfig.callsFilename, factConfig.genConfig.startTime, calls)
		writeHospitalsFile(factConfig.genConfig.hospitalsFilename, hospitals)
		writeMapFile(factConfig.genConfig.mapFilename, factConfig.genConfig.map)
		writeNodesFile(factConfig.genConfig.nodesFilename, nodes)
		writePrioritiesFile(factConfig.genConfig.prioritiesFilename, repmat([factConfig.genConfig.targetResponseTime],3))
		writeStationsFile(factConfig.genConfig.stationsFilename, stations)
		writeTravelFile(factConfig.genConfig.travelFilename, travel)
	else
		error("Unrecognised generation mode")
	end
end


function makeFactoryArcs(factConfig::FactConfig, graph::LightGraphs.Graph, nodes::Vector{Node})

	for i = 1:factConfig.numNodes-1
		for j = i+1:factConfig.numNodes
			dist = normDist(factConfig.genConfig.map, nodes[i].location, nodes[j].location)/factConfig.genConfig.map.xScale
			if (dist <=  factConfig.maxConnectDist)
				LightGraphs.add_edge!(graph,i,j)
			end

		end
	end
	arcs = Vector{Arc}(graph.ne)
	speed = 1.5 * factConfig.genConfig.offRoadSpeed
	travelTimes = Vector{Float}(length(arcs))

	i = 1
	for edge in LightGraphs.edges(graph)
		arcs[i] = Arc()
		arcs[i].index = i
		arcs[i].fromNodeIndex = edge.src
		arcs[i].toNodeIndex = edge.dst

		dist = normDist(factConfig.genConfig.map, nodes[edge.src].location, nodes[edge.dst].location)
		travelTimes[i] = dist / speed * rand(factConfig.genConfig.travelTimeFactorDistrRng)
		i = i + 1
	end

	return arcs, travelTimes
end


function makeFactoryNodes(factConfig::FactConfig, graph::LightGraphs.Graph)
	nodes = Vector{Node}(LightGraphs.nv(graph)) # should have length xNodes*yNodes
	map = factConfig.genConfig.map # shorthand
	nodes = readLocationsFile(normpath(joinpath(@__DIR__, "..\\example\\locations.csv")))

	return nodes
end

function readLocationsFile(filename::String)

	tables = readTablesFromFile(filename)

	table = tables["nodes"]
	n = size(table.data,1) # number of nodes
	assert(n >= 2)
	c = table.columns # shorthand
	(indexCol = c["index"]); (xCol = c["x"]); (yCol = c["y"]) # shorthand, to avoid repeated dict lookups

	# create nodes from data in table
	data = table.data # shorthand
	nodes = Vector{Node}(n)
	for i = 1:n
		nodes[i] = Node()
		nodes[i].index = indexCol[i]
		nodes[i].location.x = xCol[i]
		nodes[i].location.y = yCol[i]

		assert(nodes[i].index == i)
	end

	return nodes
end
