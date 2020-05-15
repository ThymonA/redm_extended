RDX.Trace = function(msg)
	if Config.EnableDebug then
		print(('[redm_extended] [^2TRACE^7] %s^7'):format(msg))
	end
end

RDX.SetTimeout = function(msec, cb)
	local id = RDX.TimeoutCount + 1

	SetTimeout(msec, function()
		if RDX.CancelledTimeouts[id] then
			RDX.CancelledTimeouts[id] = nil
		else
			cb()
		end
	end)

	RDX.TimeoutCount = id

	return id
end

RDX.RegisterCommand = function(name, group, cb, allowConsole, suggestion)
	if type(name) == 'table' then
		for i = 1, #name do
			local _name = name[i]

			RDX.RegisterCommand(_name, group, cb, allowConsole, suggestion)
		end

		return
	end

	if RDX.RegisteredCommands[name] then
		print(('[redm_extended] [^3WARNING^7] An command "%s" is already registered, overriding command'):format(name))

		if RDX.RegisteredCommands[name].suggestion then
			TriggerClientEvent('chat:removeSuggestion', -1, ('/%s'):format(name))
		end
	end

	if suggestion then
		if not suggestion.arguments then suggestion.arguments = {} end
		if not suggestion.help then suggestion.help = '' end

		TriggerClientEvent('chat:addSuggestion', -1, ('/%s'):format(name), suggestion.help, suggestion.arguments)
	end

	RDX.RegisteredCommands[name] = {group = group, cb = cb, allowConsole = allowConsole, suggestion = suggestion}

	RegisterCommand(name, function(playerId, args, rawCommand)
		local command = RDX.RegisteredCommands[name]

		if not command.allowConsole and playerId == 0 then
			print(('[redm_extended] [^3WARNING^7] %s'):format(_U('commanderror_console')))
		else
			local xPlayer, error = RDX.GetPlayerFromId(playerId), nil

			if command.suggestion then
				if command.suggestion.validate then
					if #args ~= #command.suggestion.arguments then
						error = _U('commanderror_argumentmismatch', #args, #command.suggestion.arguments)
					end
				end

				if not error and command.suggestion.arguments then
					local newArgs = {}

					for i = 1, #command.suggestion.arguments do
						local _suggestion = command.suggestion.arguments[i]

						if _suggestion.type then
							if _suggestion.type == 'number' then
								local newArg = tonumber(args[i])

								if newArg then
									newArgs[_suggestion.name] = newArg
								else
									error = _U('commanderror_argumentmismatch_number', i)
								end
							elseif _suggestion.type == 'player' or _suggestion.type == 'playerId' then
								local targetPlayer = tonumber(args[i])

								if args[i] == 'me' then targetPlayer = playerId end

								if targetPlayer then
									local xTargetPlayer = RDX.GetPlayerFromId(targetPlayer)

									if xTargetPlayer then
										if _suggestion.type == 'player' then
											newArgs[_suggestion.name] = xTargetPlayer
										else
											newArgs[_suggestion.name] = targetPlayer
										end
									else
										error = _U('commanderror_invalidplayerid')
									end
								else
									error = _U('commanderror_argumentmismatch_number', i)
								end
							elseif _suggestion.type == 'string' then
								newArgs[_suggestion.name] = args[i]
							elseif _suggestion.type == 'item' then
								if RDX.Items[args[i]] then
									newArgs[_suggestion.name] = args[i]
								else
									error = _U('commanderror_invaliditem')
								end
							elseif _suggestion.type == 'weapon' then
								if RDX.GetWeapon(args[i]) then
									newArgs[_suggestion.name] = string.upper(args[i])
								else
									error = _U('commanderror_invalidweapon')
								end
							elseif _suggestion.type == 'any' then
								newArgs[_suggestion.name] = args[i]
							end
						end

						if error then break end
					end

					args = newArgs
				end
			end

			if error then
				if playerId == 0 then
					print(('[redm_extended] [^3WARNING^7] %s^7'):format(error))
				else
					xPlayer.triggerEvent('chat:addMessage', {args = {'^1SYSTEM', error}})
				end
			else
				cb(xPlayer or false, args, function(msg)
					if playerId == 0 then
						print(('[redm_extended] [^3WARNING^7] %s^7'):format(msg))
					else
						xPlayer.triggerEvent('chat:addMessage', {args = {'^1SYSTEM', msg}})
					end
				end)
			end
		end
	end, true)

	if type(group) == 'table' then
		for i = 1, #group do
			ExecuteCommand(('add_ace group.%s command.%s allow'):format(group[i], name))
		end
	else
		ExecuteCommand(('add_ace group.%s command.%s allow'):format(group, name))
	end
end

RDX.ClearTimeout = function(id)
	RDX.CancelledTimeouts[id] = true
end

RDX.RegisterServerCallback = function(name, cb)
	RDX.ServerCallbacks[name] = cb
end

RDX.TriggerServerCallback = function(name, requestId, source, cb, ...)
	if RDX.ServerCallbacks[name] then
		RDX.ServerCallbacks[name](source, cb, ...)
	else
		print(('[redm_extended] [^3WARNING^7] Server callback "%s" does not exist. Make sure that the server sided file really is loading, an error in that file might cause it to not load.'):format(name))
	end
end

RDX.SavePlayer = function(xPlayer, cb)
	local asyncPool = Async.CreatePool()

	asyncPool.add(function(cb2)
		MySQL.Async.execute('UPDATE users SET accounts = @accounts, job = @job, job_grade = @job_grade, `group` = @group, loadout = @loadout, position = @position, inventory = @inventory WHERE identifier = @identifier', {
			['@accounts'] = json.encode(xPlayer.getAccounts(true)),
			['@job'] = xPlayer.job.name,
			['@job_grade'] = xPlayer.job.grade,
			['@group'] = xPlayer.getGroup(),
			['@loadout'] = json.encode(xPlayer.getLoadout(true)),
			['@position'] = json.encode(xPlayer.getCoords()),
			['@identifier'] = xPlayer.getIdentifier(),
			['@inventory'] = json.encode(xPlayer.getInventory(true))
		}, function(rowsChanged)
			cb2()
		end)
	end)

	asyncPool.startParallelAsync(function(results)
		print(('[redm_extended] [^2INFO^7] Saved player "%s^7"'):format(xPlayer.getName()))

		if cb then
			cb()
		end
	end)
end

RDX.SavePlayers = function(cb)
	local xPlayers, asyncPool = RDX.GetPlayers(), Async.CreatePool()

	for i=1, #xPlayers, 1 do
		asyncPool.add(function(cb2)
			local xPlayer = RDX.GetPlayerFromId(xPlayers[i])
			RDX.SavePlayer(xPlayer, cb2)
		end)
	end

	asyncPool.startParallelLimitAsync(8, function(results)
		print(('[redm_extended] [^2INFO^7] Saved %s player(s)'):format(#xPlayers))

		if cb then cb() end
	end)
end

RDX.StartDBSync = function()
	function saveData()
		RDX.SavePlayers()
		SetTimeout(10 * 60 * 1000, saveData)
	end

	SetTimeout(10 * 60 * 1000, saveData)
end

RDX.GetPlayers = function()
	local sources = {}

	for k,v in pairs(RDX.Players) do
		table.insert(sources, k)
	end

	return sources
end

RDX.GetPlayerFromId = function(source)
	return RDX.Players[tonumber(source)]
end

RDX.GetPlayerFromIdentifier = function(identifier)
	for k,v in pairs(RDX.Players) do
		if v.identifier == identifier then
			return v
		end
	end
end

RDX.RegisterUsableItem = function(item, cb)
	RDX.UsableItemsCallbacks[item] = cb
end

RDX.UseItem = function(source, item)
	RDX.UsableItemsCallbacks[item](source)
end

RDX.GetItemLabel = function(item)
	if RDX.Items[item] then
		return RDX.Items[item].label
	end
end

RDX.CreatePickup = function(type, name, count, label, playerId, components)
	local pickupId = (RDX.PickupId == 65635 and 0 or RDX.PickupId + 1)
	local xPlayer = RDX.GetPlayerFromId(playerId)
	local coords = xPlayer.getCoords()

	RDX.Pickups[pickupId] = {
		type = type, name = name,
		count = count, label = label,
		coords = coords
	}

	if type == 'item_weapon' then
		RDX.Pickups[pickupId].components = components
	end

	TriggerClientEvent('rdx:createPickup', -1, pickupId, label, coords, type, name, components)
	RDX.PickupId = pickupId
end

RDX.DoesJobExist = function(job, grade)
	grade = tostring(grade)

	if job and grade then
		if RDX.Jobs[job] and RDX.Jobs[job].grades[grade] then
			return true
		end
	end

	return false
end

RDX.GetPlayerIdentifier = function(playerId)
	local identifiers = GetPlayerIdentifiers(playerId)

	for i = 1, #identifiers do
		local identifier = identifiers[i]

		if string.match(identifier, 'steam:') then
			return string.sub(identifier, 9)
		end
	end
end
