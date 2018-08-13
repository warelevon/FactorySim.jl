global animConnections = Dict{Int,WebSocket}() # store open connections
global animConfigFilenames = Vector{String}() # store filenames between animation request and start
global animPort = nullIndex # localhost port for animation, to be set

wsh = WebSocketHandler() do req::Request, client::WebSocket
	global animConnections, animConfigFilenames

	animConnections[client.id] = client
	println("Client ", client.id, " connected")

	# get oldest filename from animConfigFilenames, or select file now
	configFilename = (length(animConfigFilenames) > 0 ? shift!(animConfigFilenames) : selectXmlFile())
	println("Running from config: ", configFilename)

	println("Initialising simulation...")
	sim = initSimulation(configFilename; allowResim = true)
	println("...initialised")

	# set map
	messageDict = createMessageDict("set_map_view")
	messageDict["map"] = sim.map
	write(client, json(messageDict))

	# set sim start time
	messageDict = createMessageDict("set_start_time")
	messageDict["time"] = sim.startTime
	write(client, json(messageDict))

	animSetIcons(client) # set icons before adding items to map
	animAddNodes(client, sim.net.fGraph.nodes)
	animAddArcs(client, sim.net) # add first, should be underneath other objects
	animSetArcSpeeds(client, sim.map, sim.net)
	animAddBuildings(client, sim)
	animAddAmbs!(client, sim)

	messageDict = createMessageDict("")
	while true
		msg = read(client) # waits for message from client
		msgString = decodeMessage(msg)
		(msgType, msgData) = parseMessage(msgString)

		if msgType == "prepare_next_frame"
			simTime = Float(msgData[1])
			simulateToTime!(sim, simTime)
			messageDict["time"] = simTime
			writeClient!(client, messageDict, "prepared_next_frame")

		elseif msgType == "get_next_frame"
			simTime = Float(msgData[1])
			updateFrame!(client, sim, simTime) # show updated amb locations, etc
			if !sim.complete
				messageDict["time"] = simTime
				writeClient!(client, messageDict, "got_next_frame")
			else
				# no events left, finish animation
				writeClient!(client, messageDict, "got_last_frame")
			end

		elseif msgType == "pause"

		elseif msgType == "stop"
			# reset
			resetSim!(sim)
			animAddAmbs!(client, sim)

		elseif msgType == "update_icons"
			try
				animSetIcons(client)
			catch e
				warn("Could not update animation icons")
				warn(e)
			end

		elseif msgType == "disconnect"
			close(client)
			println("Client ", client.id, " disconnected")
			break
		else
			error("Unrecognised message: ", msgString)
		end
	end
end
