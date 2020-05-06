RDX                           = {}
RDX.PlayerData                = {}
RDX.PlayerLoaded              = false
RDX.CurrentRequestId          = 0
RDX.ServerCallbacks           = {}
RDX.TimeoutCallbacks          = {}

RDX.UI                        = {}
RDX.UI.HUD                    = {}
RDX.UI.HUD.RegisteredElements = {}
RDX.UI.Menu                   = {}
RDX.UI.Menu.RegisteredTypes   = {}
RDX.UI.Menu.Opened            = {}

RDX.Game                      = {}
RDX.Game.Utils                = {}

RDX.Scaleform                 = {}
RDX.Scaleform.Utils           = {}

RDX.Streaming                 = {}

RDX.SetTimeout = function(msec, cb)
	table.insert(RDX.TimeoutCallbacks, {
		time = GetGameTimer() + msec,
		cb   = cb
	})
	return #RDX.TimeoutCallbacks
end

RDX.ClearTimeout = function(i)
	RDX.TimeoutCallbacks[i] = nil
end

RDX.IsPlayerLoaded = function()
	return RDX.PlayerLoaded
end

RDX.GetPlayerData = function()
	return RDX.PlayerData
end

RDX.SetPlayerData = function(key, val)
	RDX.PlayerData[key] = val
end

RDX.ShowNotification = function(msg, flash, saveToBrief, hudColorIndex)
end

RDX.ShowAdvancedNotification = function(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
end

RDX.ShowHelpNotification = function(msg, thisFrame, beep, duration)
end

RDX.ShowFloatingHelpNotification = function(msg, coords)
end

RDX.ShowTopLeftNotification = function(title, subTitle, iconDict, icon, duration)
	TriggerEvent('rdx:displayLeftNotification', title, subTitle, iconDict, icon, duration)
end

RDX.ShowTopCenterNotification = function(text, duration, town)
	TriggerEvent('rdx:displayTopCenterNotification', text, duration, town)
end

RDX.TriggerServerCallback = function(name, cb, ...)
	RDX.ServerCallbacks[RDX.CurrentRequestId] = cb

	TriggerServerEvent('rdx:triggerServerCallback', name, RDX.CurrentRequestId, ...)

	if RDX.CurrentRequestId < 65535 then
		RDX.CurrentRequestId = RDX.CurrentRequestId + 1
	else
		RDX.CurrentRequestId = 0
	end
end

RDX.UI.HUD.SetDisplay = function(opacity)
	SendNUIMessage({
		action  = 'setHUDDisplay',
		opacity = opacity
	})
end

RDX.UI.HUD.RegisterElement = function(name, index, priority, html, data)
	local found = false

	for i=1, #RDX.UI.HUD.RegisteredElements, 1 do
		if RDX.UI.HUD.RegisteredElements[i] == name then
			found = true
			break
		end
	end

	if found then
		return
	end

	table.insert(RDX.UI.HUD.RegisteredElements, name)

	SendNUIMessage({
		action    = 'insertHUDElement',
		name      = name,
		index     = index,
		priority  = priority,
		html      = html,
		data      = data
	})

	RDX.UI.HUD.UpdateElement(name, data)
end

RDX.UI.HUD.RemoveElement = function(name)
	for i=1, #RDX.UI.HUD.RegisteredElements, 1 do
		if RDX.UI.HUD.RegisteredElements[i] == name then
			table.remove(RDX.UI.HUD.RegisteredElements, i)
			break
		end
	end

	SendNUIMessage({
		action    = 'deleteHUDElement',
		name      = name
	})
end

RDX.UI.HUD.UpdateElement = function(name, data)
	SendNUIMessage({
		action = 'updateHUDElement',
		name   = name,
		data   = data
	})
end

RDX.UI.Menu.RegisterType = function(type, open, close)
	RDX.UI.Menu.RegisteredTypes[type] = {
		open   = open,
		close  = close
	}
end

RDX.UI.Menu.Open = function(type, namespace, name, data, submit, cancel, change, close)
	local menu = {}

	menu.type      = type
	menu.namespace = namespace
	menu.name      = name
	menu.data      = data
	menu.submit    = submit
	menu.cancel    = cancel
	menu.change    = change

	menu.close = function()

		RDX.UI.Menu.RegisteredTypes[type].close(namespace, name)

		for i=1, #RDX.UI.Menu.Opened, 1 do
			if RDX.UI.Menu.Opened[i] then
				if RDX.UI.Menu.Opened[i].type == type and RDX.UI.Menu.Opened[i].namespace == namespace and RDX.UI.Menu.Opened[i].name == name then
					RDX.UI.Menu.Opened[i] = nil
				end
			end
		end

		if close then
			close()
		end

	end

	menu.update = function(query, newData)

		for i=1, #menu.data.elements, 1 do
			local match = true

			for k,v in pairs(query) do
				if menu.data.elements[i][k] ~= v then
					match = false
				end
			end

			if match then
				for k,v in pairs(newData) do
					menu.data.elements[i][k] = v
				end
			end
		end

	end

	menu.refresh = function()
		RDX.UI.Menu.RegisteredTypes[type].open(namespace, name, menu.data)
	end

	menu.setElement = function(i, key, val)
		menu.data.elements[i][key] = val
	end

	menu.setElements = function(newElements)
		menu.data.elements = newElements
	end

	menu.setTitle = function(val)
		menu.data.title = val
	end

	menu.removeElement = function(query)
		for i=1, #menu.data.elements, 1 do
			for k,v in pairs(query) do
				if menu.data.elements[i] then
					if menu.data.elements[i][k] == v then
						table.remove(menu.data.elements, i)
						break
					end
				end

			end
		end
	end

	table.insert(RDX.UI.Menu.Opened, menu)
	RDX.UI.Menu.RegisteredTypes[type].open(namespace, name, data)

	return menu
end

RDX.UI.Menu.Close = function(type, namespace, name)
	for i=1, #RDX.UI.Menu.Opened, 1 do
		if RDX.UI.Menu.Opened[i] then
			if RDX.UI.Menu.Opened[i].type == type and RDX.UI.Menu.Opened[i].namespace == namespace and RDX.UI.Menu.Opened[i].name == name then
				RDX.UI.Menu.Opened[i].close()
				RDX.UI.Menu.Opened[i] = nil
			end
		end
	end
end

RDX.UI.Menu.CloseAll = function()
	for i=1, #RDX.UI.Menu.Opened, 1 do
		if RDX.UI.Menu.Opened[i] then
			RDX.UI.Menu.Opened[i].close()
			RDX.UI.Menu.Opened[i] = nil
		end
	end
end

RDX.UI.Menu.GetOpened = function(type, namespace, name)
	for i=1, #RDX.UI.Menu.Opened, 1 do
		if RDX.UI.Menu.Opened[i] then
			if RDX.UI.Menu.Opened[i].type == type and RDX.UI.Menu.Opened[i].namespace == namespace and RDX.UI.Menu.Opened[i].name == name then
				return RDX.UI.Menu.Opened[i]
			end
		end
	end
end

RDX.UI.Menu.GetOpenedMenus = function()
	return RDX.UI.Menu.Opened
end

RDX.UI.Menu.IsOpen = function(type, namespace, name)
	return RDX.UI.Menu.GetOpened(type, namespace, name) ~= nil
end

RDX.UI.ShowInventoryItemNotification = function(add, item, count)
	SendNUIMessage({
		action = 'inventoryNotification',
		add    = add,
		item   = item,
		count  = count
	})
end

RDX.Game.GetPedMugshot = function(ped, transparent)
	if DoesEntityExist(ped) then
		local mugshot

		if transparent then
			mugshot = RegisterPedheadshotTransparent(ped)
		else
			mugshot = RegisterPedheadshot(ped)
		end

		while not IsPedheadshotReady(mugshot) do
			Citizen.Wait(0)
		end

		return mugshot, GetPedheadshotTxdString(mugshot)
	else
		return
	end
end

RDX.Game.Teleport = function(entity, coords, cb)
	if DoesEntityExist(entity) then
		RequestCollisionAtCoord(coords.x, coords.y, coords.z)
		SetEntityCoords(entity, coords.x, coords.y, coords.z, false, false, false, false)

		if type(coords) == 'table' and coords.heading then
			SetEntityHeading(entity, coords.heading)
		end
	end

	if cb then
		cb()
	end
end

RDX.Game.SpawnObject = function(model, coords, cb)
	model = (type(model) == 'number' and model or GetHashKey(model))

	Citizen.CreateThread(function()
		RDX.Streaming.RequestModel(model)
		local obj = CreateObject(model, coords.x, coords.y, coords.z, true, false, true)
		SetModelAsNoLongerNeeded(model)

		if cb then
			cb(obj)
		end
	end)
end

RDX.Game.SpawnLocalObject = function(model, coords, cb)
	model = (type(model) == 'number' and model or GetHashKey(model))

	Citizen.CreateThread(function()
		RDX.Streaming.RequestModel(model)
		local obj = CreateObject(model, coords.x, coords.y, coords.z, false, false, true)
		SetModelAsNoLongerNeeded(model)

		if cb then
			cb(obj)
		end
	end)
end

RDX.Game.SpawnPed = function(model, coords, heading, cb)
	model = (type(model) == 'number' and model or GetHashKey(model))

	Citizen.CreateThread(function()
		RDX.Streaming.RequestModel(model, function()
			local ped = CreatePed(model, coords.x, coords.y, coords.z, heading)
			local timeout = 0

			SetPedOutfitPreset(ped, true, false)
			Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
			SetEntityAsMissionEntity(ped, true, false)
			RequestCollisionAtCoord(coords.x, coords.y, coords.z)

			-- we can get stuck here if any of the axies are "invalid"
			while not HasCollisionLoadedAroundEntity(ped) and timeout < 2000 do
				Citizen.Wait(0)
				timeout = timeout + 1
			end

			if cb then
				cb(ped)
			end
		end)
	end)
end

RDX.Game.DeleteVehicle = function(vehicle)
	SetEntityAsMissionEntity(vehicle, false, true)
	DeleteVehicle(vehicle)
end

RDX.Game.DeleteObject = function(object)
	SetEntityAsMissionEntity(object, false, true)
	DeleteObject(object)
end

RDX.Game.DeleteHorse = function(horse)
	SetEntityAsMissionEntity(horse, false, true)
	DeletePed(horse)
end

RDX.Game.SpawnVehicle = function(model, coords, heading, cb)
	model = (type(model) == 'number' and model or GetHashKey(model))

	Citizen.CreateThread(function()
		RDX.Streaming.RequestModel(model, function()
			local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
			local timeout = 0

			SetEntityAsMissionEntity(vehicle, true, false)
			SetVehicleHasBeenOwnedByPlayer(vehicle, true)
			SetModelAsNoLongerNeeded(model)
			RequestCollisionAtCoord(coords.x, coords.y, coords.z)

			-- we can get stuck here if any of the axies are "invalid"
			while not HasCollisionLoadedAroundEntity(vehicle) and timeout < 2000 do
				Citizen.Wait(0)
				timeout = timeout + 1
			end

			if cb then
				cb(vehicle)
			end
		end)
	end)
end

RDX.Game.SpawnLocalVehicle = function(model, coords, heading, cb)
	model = (type(model) == 'number' and model or GetHashKey(model))

	Citizen.CreateThread(function()
		RDX.Streaming.RequestModel(model, function()
			local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading, false, false)
			local timeout = 0

			SetEntityAsMissionEntity(vehicle, true, false)
			SetVehicleHasBeenOwnedByPlayer(vehicle, true)
			SetModelAsNoLongerNeeded(model)
			RequestCollisionAtCoord(coords.x, coords.y, coords.z)

			-- we can get stuck here if any of the axies are "invalid"
			while not HasCollisionLoadedAroundEntity(vehicle) and timeout < 2000 do
				Citizen.Wait(0)
				timeout = timeout + 1
			end

			if cb then
				cb(vehicle)
			end
		end)
	end)
end

RDX.Game.IsVehicleEmpty = function(vehicle)
	local passengers = GetVehicleNumberOfPassengers(vehicle)
	local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

	return passengers == 0 and driverSeatFree
end

RDX.Game.GetObjects = function()
	local objects = {}

	for object in EnumerateObjects() do
		table.insert(objects, object)
	end

	return objects
end

RDX.Game.GetPeds = function(onlyOtherPeds)
	local peds, myPed = {}, PlayerPedId()

	for ped in EnumeratePeds() do
		if ((onlyOtherPeds and ped ~= myPed) or not onlyOtherPeds) then
			table.insert(peds, ped)
		end
	end

	return peds
end

RDX.Game.GetVehicles = function()
	local vehicles = {}

	for vehicle in EnumerateVehicles() do
		table.insert(vehicles, vehicle)
	end

	return vehicles
end

RDX.Game.GetPlayers = function(onlyOtherPlayers, returnKeyValue, returnPeds)
	local players, myPlayer = {}, PlayerId()
	local activePlayers = GetActivePlayers()

	for i = 1, #activePlayers do
		local player = activePlayers[i]
		local ped = GetPlayerPed(player)

		if DoesEntityExist(ped) and ((onlyOtherPlayers and player ~= myPlayer) or not onlyOtherPlayers) then
			if returnKeyValue then
				players[player] = ped
			else
				table.insert(players, returnPeds and ped or player)
			end
		end
	end

	return players
end

RDX.Game.GetClosestObject = function(coords, modelFilter) return RDX.Game.GetClosestEntity(RDX.Game.GetObjects(), false, coords, modelFilter) end
RDX.Game.GetClosestPed = function(coords, modelFilter) return RDX.Game.GetClosestEntity(RDX.Game.GetPeds(true), false, coords, modelFilter) end
RDX.Game.GetClosestPlayer = function(coords) return RDX.Game.GetClosestEntity(RDX.Game.GetPlayers(true, true), true, coords, nil) end
RDX.Game.GetClosestVehicle = function(coords, modelFilter) return RDX.Game.GetClosestEntity(RDX.Game.GetVehicles(), false, coords, modelFilter) end
RDX.Game.GetPlayersInArea = function(coords, maxDistance) return EnumerateEntitiesWithinDistance(RDX.Game.GetPlayers(true, true), true, coords, maxDistance) end
RDX.Game.GetVehiclesInArea = function(coords, maxDistance) return EnumerateEntitiesWithinDistance(RDX.Game.GetVehicles(), false, coords, maxDistance) end
RDX.Game.IsSpawnPointClear = function(coords, maxDistance) return #RDX.Game.GetVehiclesInArea(coords, maxDistance) == 0 end

RDX.Game.GetClosestEntity = function(entities, isPlayerEntities, coords, modelFilter)
	local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil

	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end

	if modelFilter then
		filteredEntities = {}

		for k,entity in pairs(entities) do
			if modelFilter[GetEntityModel(entity)] then
				table.insert(filteredEntities, entity)
			end
		end
	end

	for k,entity in pairs(filteredEntities or entities) do
		local distance = #(coords - GetEntityCoords(entity))

		if closestEntityDistance == -1 or distance < closestEntityDistance then
			closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
		end
	end

	return closestEntity, closestEntityDistance
end

RDX.Game.GetVehicleInDirection = function()
	local playerPed    = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local inDirection  = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
	local rayHandle    = StartShapeTestRay(playerCoords, inDirection, 10, playerPed, 0)
	local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

	if hit == 1 and GetEntityType(entityHit) == 2 then
		return entityHit
	end

	return nil
end

RDX.Game.GetHorseInDirection = function()
	local playerPed    = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed)
	local inDirection  = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
	local rayHandle    = StartShapeTestRay(playerCoords, inDirection, 10, playerPed, 0)
	local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

	if hit == 1 and IsEntityAPed(entityHit) and GetPedType(entityHit) == 28 then
		return entityHit
	end

	return nil
end

RDX.Game.Utils.DrawText3D = function(coords, text, size, font)
	coords = vector3(coords.x, coords.y, coords.z)

	local camCoords = Citizen.InvokeNative(0x595320200B98596E, Citizen.ReturnResultAnyway(), Citizen.ResultAsVector())
	local distance = #(camCoords - coords)

	if not size then size = 1 end
	if not font then font = 0 end

	local scale = (size / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	scale = scale * fov

	local onScreen, x, y = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

	if (onScreen) then
		SetTextScale(0.0 * scale, 0.55 * scale)
		SetTextColor(255, 255, 255, 255)

		if (font ~= nil) then
			SetTextFontForCurrentCommand(font)
		end

		SetTextDropshadow(0, 0, 0, 255)
		SetTextCentre(true)
		DisplayText(CreateVarString(10, 'LITERAL_STRING', text), x, y)
	end
end

RDX.Game.DrawMarker = function(markerInfo)
	markerInfo = markerInfo or {}

	local markerType = markerInfo.markerType or 0
	local coords = markerInfo.coords or nil
	local directions = markerInfo.directions or vector3(0.0, 0.0, 0.0)
	local rotations = markerInfo.rotations or vector3(0.0, 0.0, 0.0)
	local scales = markerInfo.scales or vector3(1.5, 1.5, 1.5)
	local colors = markerInfo.colors or vector4(255, 255, 255, 100)
	local bobUpAndDown = markerInfo.bobUpAndDown or false
	local faceCamera = markerInfo.faceCamera or false
	local p19 = markerInfo.p19 or 2
	local rotate = markerInfo.rotate or false
	local textureDict = markerInfo.textureDict or false
	local textureName = markerInfo.textureName or false
	local drawOnEnts = markerInfo.drawOnEnts or false

	if (markerType == nil or type(markerType) ~= 'number' or coords == nil or type(coords) ~= 'vector3') then
		return
	end

	local markerTypes = { [0] = 0x94FDAE17, [1] = 0x6EB7D3BB, [2] = 0x50638AB9, [3] = 0xEC032ADD, [4] = 0x6903B113, [5] = 0x7DCE236, [6] = 0xD6445746, [7] = 0x29FE305A, [8] = 0xE3C923F1, [9] = 0xD57F875E, [10] = 0x40675D1C, [11] = 0x4E94F977, [12] = 0x234BA2E5, [13] = 0xF9B24FB3, [14] = 0x75FEB0E, [15] = 0xDD839756, [16] = 0xE9F6303B }

	if (markerType > 0 and markerType < 17) then
		markerType = markerTypes[markerType]
	end

	if (type(directions) ~= 'vector3') then directions = vector3(0.0, 0.0, 0.0) end
	if (type(rotations) ~= 'vector3') then rotations = vector3(0.0, 0.0, 0.0) end
	if (type(scales) ~= 'vector3') then scales = vector3(1.5, 1.5, 1.5) end
	if (type(colors) ~= 'vector4') then colors = vector4(255, 255, 255, 100) end
	if (type(bobUpAndDown) ~= 'boolean' and type(bobUpAndDown) ~= 'number') then bobUpAndDown = false end
	if (type(faceCamera) ~= 'boolean' and type(faceCamera) ~= 'number') then faceCamera = false end
	if (type(p19) ~= 'number') then p19 = 2 end
	if (type(rotate) ~= 'boolean' and type(rotate) ~= 'number') then rotate = false end
	if (type(textureDict) ~= 'string') then textureDict = false end
	if (type(textureName) ~= 'string') then textureName = false end
	if (type(drawOnEnts) ~= 'boolean' and type(drawOnEnts) ~= 'number') then drawOnEnts = false end

	local posX, posY, posZ = table.unpack(coords)
	local dirX, dirY, dirZ = table.unpack(directions)
	local rotX, rotY, rotZ = table.unpack(rotations)
	local scaleX, scaleY, scaleZ = table.unpack(scales)
	local red, green, blue, alpha = table.unpack(colors)

	Citizen.InvokeNative(0x2A32FAA57B937173, markerType, posX, posY, posZ, dirX, dirY, dirZ, rotX, rotY, rotZ, scaleX, scaleY, scaleZ, red, green, blue, alpha, bobUpAndDown, faceCamera, p19, rotate, textureDict, textureName, drawOnEnts)
end

RDX.ShowInventory = function()
	local playerPed = PlayerPedId()
	local elements, currentWeight = {}, 0

	for k,v in pairs(RDX.PlayerData.accounts) do
		if v.money > 0 then
			local formattedMoney = _U('locale_currency', RDX.Math.GroupDigits(v.money))
			local canDrop = v.name ~= 'bank'

			table.insert(elements, {
				label = ('%s: %s'):format(v.label, formattedMoney),
				count = v.money,
				type = 'item_account',
				value = v.name,
				usable = false,
				rare = false,
				canRemove = canDrop,
				submenu = true,
				description = _U('account_description', v.label)
			})
		end
	end

	for i = 1, #RDX.PlayerData.inventory do
		local item = RDX.PlayerData.inventory[i]

		if item.count > 0 then
			currentWeight = currentWeight + (item.weight * item.count)

			table.insert(elements, {
				label = ('%s x%s'):format(item.label, item.count),
				count = item.count,
				type = 'item_standard',
				value = item.name,
				usable = item.usable,
				rare = item.rare,
				canRemove = item.canRemove,
				submenu = true
			})
		end
	end

	for i = 1, #Config.Weapons do
		local weapon = Config.Weapons[i]
		local weaponHash = GetHashKey(weapon.name)

		if HasPedGotWeapon(playerPed, weaponHash, false) then
			local ammo, label = GetAmmoInPedWeapon(playerPed, weaponHash)

			if weapon.ammo then
				label = ('%s - %s %s'):format(weapon.label, ammo, weapon.ammo.label)
			else
				label = weapon.label
			end

			table.insert(elements, {
				label = label,
				count = 1,
				type = 'item_weapon',
				value = weapon.name,
				usable = false,
				rare = false,
				ammo = ammo,
				canGiveAmmo = (weapon.ammo ~= nil),
				canRemove = true,
				submenu = true
			})
		end
	end

	RDX.UI.Menu.CloseAll()

	RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'inventory', {
		title    = _U('inventory'),
		subtitle = ('%s / %s'):format(currentWeight, RDX.PlayerData.maxWeight),
		align    = 'bottom-right',
		elements = elements
	}, function(data, menu)
		menu.close()
		local player, distance = RDX.Game.GetClosestPlayer()
		elements = {}

		if data.current.usable then
			table.insert(elements, {label = _U('use'), action = 'use', type = data.current.type, value = data.current.value})
		end

		if data.current.canRemove then
			if player ~= -1 and distance <= 3.0 then
				table.insert(elements, {label = _U('give'), action = 'give', type = data.current.type, value = data.current.value})
			end

			table.insert(elements, {label = _U('remove'), action = 'remove', type = data.current.type, value = data.current.value})
		end

		if data.current.type == 'item_weapon' and data.current.canGiveAmmo and data.current.ammo > 0 and player ~= -1 and distance <= 3.0 then
			table.insert(elements, {label = _U('giveammo'), action = 'give_ammo', type = data.current.type, value = data.current.value})
		end

		table.insert(elements, {label = _U('return'), action = 'return'})

		RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'inventory_item', {
			title    = data.current.label,
			align    = 'bottom-right',
			elements = elements,
		}, function(data1, menu1)
			local item, type = data1.current.value, data1.current.type

			if data1.current.action == 'give' then
				local playersNearby = RDX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

				if #playersNearby > 0 then
					local players = {}
					elements = {}

					for i = 1, #playersNearby do
						players[GetPlayerServerId(playersNearby[i])] = true
					end

					RDX.TriggerServerCallback('rdx:getPlayerNames', function(returnedPlayers)
						for playerId,playerName in pairs(returnedPlayers) do
							table.insert(elements, {
								label = playerName,
								playerId = playerId
							})
						end

						RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'give_item_to', {
							title    = _U('give_to'),
							align    = 'bottom-right',
							elements = elements
						}, function(data2, menu2)
							local selectedPlayer, selectedPlayerId = GetPlayerFromServerId(data2.current.playerId), data2.current.playerId
							playersNearby = RDX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
							playersNearby = RDX.Table.Set(playersNearby)

							if playersNearby[selectedPlayer] then
								local selectedPlayerPed = GetPlayerPed(selectedPlayer)

								if IsPedOnFoot(selectedPlayerPed) and not IsPedFalling(selectedPlayerPed) then
									if type == 'item_weapon' then
										TriggerServerEvent('rdx:giveInventoryItem', selectedPlayerId, type, item, nil)
										menu2.close()
										menu1.close()
									else
										RDX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_give', {
											title = _U('amount')
										}, function(data3, menu3)
											local quantity = tonumber(data3.value)

											if quantity and quantity > 0 and data.current.count >= quantity then
												TriggerServerEvent('rdx:giveInventoryItem', selectedPlayerId, type, item, quantity)
												menu3.close()
												menu2.close()
												menu1.close()
											else
												RDX.ShowNotification(_U('amount_invalid'))
											end
										end, function(data3, menu3)
											menu3.close()
										end)
									end
								else
									RDX.ShowNotification(_U('in_vehicle'))
								end
							else
								RDX.ShowNotification(_U('players_nearby'))
								menu2.close()
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					end, players)
				else
					RDX.ShowNotification(_U('players_nearby'))
				end
			elseif data1.current.action == 'remove' then
				if IsPedOnFoot(playerPed) and not IsPedFalling(playerPed) then
					if type == 'item_weapon' then
						menu1.close()
						TriggerServerEvent('rdx:removeInventoryItem', type, item)
					else
						RDX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_remove', {
							title = _U('amount')
						}, function(data2, menu2)
							local quantity = tonumber(data2.value)

							if quantity and quantity > 0 and data.current.count >= quantity then
								menu2.close()
								menu1.close()
								TriggerServerEvent('rdx:removeInventoryItem', type, item, quantity)
							else
								RDX.ShowNotification(_U('amount_invalid'))
							end
						end, function(data2, menu2)
							menu2.close()
						end)
					end
				end
			elseif data1.current.action == 'use' then
				TriggerServerEvent('rdx:useItem', item)
			elseif data1.current.action == 'return' then
				RDX.UI.Menu.CloseAll()
				RDX.ShowInventory()
			elseif data1.current.action == 'give_ammo' then
				local closestPlayer, closestDistance = RDX.Game.GetClosestPlayer()
				local pedAmmo = GetAmmoInPedWeapon(playerPed, GetHashKey(item))

				if IsPedOnFoot(closestPed) and not IsPedFalling(closestPed) then
					if closestPlayer ~= -1 and closestDistance < 3.0 then
						if pedAmmo > 0 then
							RDX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'inventory_item_count_give', {
								title = _U('amountammo')
							}, function(data2, menu2)
								local quantity = tonumber(data2.value)

								if quantity and quantity > 0 then
									if pedAmmo >= quantity then
										TriggerServerEvent('rdx:giveInventoryItem', GetPlayerServerId(closestPlayer), 'item_ammo', item, quantity)
										menu2.close()
										menu1.close()
									else
										RDX.ShowNotification(_U('noammo'))
									end
								else
									RDX.ShowNotification(_U('amount_invalid'))
								end
							end, function(data2, menu2)
								menu2.close()
							end)
						else
							RDX.ShowNotification(_U('noammo'))
						end
					else
						RDX.ShowNotification(_U('players_nearby'))
					end
				else
					RDX.ShowNotification(_U('in_vehicle'))
				end
			end
		end, function(data1, menu1)
			RDX.UI.Menu.CloseAll()
			RDX.ShowInventory()
		end)
	end, function(data, menu)
		menu.close()
	end)
end

RegisterNetEvent('rdx:serverCallback')
AddEventHandler('rdx:serverCallback', function(requestId, ...)
	RDX.ServerCallbacks[requestId](...)
	RDX.ServerCallbacks[requestId] = nil
end)

RegisterNetEvent('rdx:showNotification')
AddEventHandler('rdx:showNotification', function(msg, flash, saveToBrief, hudColorIndex)
	RDX.ShowNotification(msg, flash, saveToBrief, hudColorIndex)
end)

RegisterNetEvent('rdx:showAdvancedNotification')
AddEventHandler('rdx:showAdvancedNotification', function(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
	RDX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
end)

RegisterNetEvent('rdx:showHelpNotification')
AddEventHandler('rdx:showHelpNotification', function(msg, thisFrame, beep, duration)
	RDX.ShowHelpNotification(msg, thisFrame, beep, duration)
end)

-- SetTimeout
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local currTime = GetGameTimer()

		for i=1, #RDX.TimeoutCallbacks, 1 do
			if RDX.TimeoutCallbacks[i] then
				if currTime >= RDX.TimeoutCallbacks[i].time then
					RDX.TimeoutCallbacks[i].cb()
					RDX.TimeoutCallbacks[i] = nil
				end
			end
		end
	end
end)
