local resourcesStopped = {}

async:foreach(Config.IncompatibleResourcesToStop, function(reason, resourceName)
	local status = GetResourceState(resourceName)

	if status == 'started' or status == 'starting' then
		while GetResourceState(resourceName) == 'starting' do
			Citizen.Wait(100)
		end

		ExecuteCommand(('stop %s'):format(resourceName))

		resourcesStopped[resourceName] = reason
	end
end, function()
	if RDX.Table.SizeOf(resourcesStopped) > 0 then
		local allStoppedResources = ''

		foreach(resourcesStopped, function(reason, resourceName)
			allStoppedResources = ('%s\n- ^3%s^7, %s'):format(allStoppedResources, resourceName, reason)
		end)

		print(('[redm_extended] [^3WARNING^7] Stopped %s incompatible resource(s) that can cause issues when used with RDX. They are not needed and can safely be removed from your server, remove these resource(s) from your resource directory and your configuration file:%s'):format(RDX.Table.SizeOf(resourcesStopped), allStoppedResources))
	end
end)

RegisterNetEvent('rdx:onPlayerJoined')
AddEventHandler('rdx:onPlayerJoined', function()
	if not RDX.Players[source] then
		RDX.Player.LoadRDXPlayer(source)
	end
end)

AddEventHandler('onResourceStop', function(resourceName)
	if (resourceName ~= GetCurrentResourceName()) then
		return
	end

	local playersSaved = false

	RDX.SavePlayers(function()
		playersSaved = true
	end)

	while not playersSaved do
		Citizen.Wait(0)
	end
end)

AddEventHandler('playerConnecting', function(name, setCallback, deferrals)
	deferrals.defer()
	local playerId, identifier = source, RDX.GetPlayerIdentifier(source)
	Citizen.Wait(100)

	if identifier then
		if RDX.GetPlayerFromIdentifier(identifier) then
			deferrals.done(('There was an error loading your character!\nError code: identifier-active\n\nThis error is caused by a player on this server who has the same identifier as you have. Make sure you are not playing on the same Rockstar account.\n\nYour Rockstar identifier: %s'):format(identifier))
		else
			RDX.Player.CreatePlayerIfNotExists(playerId)

			deferrals.done()
		end
	else
		deferrals.done('There was an error loading your character!\nError code: identifier-missing\n\nThe cause of this error is not known, your identifier could not be found. Please come back later or report this problem to the server administration team.')
	end
end)

RDX.Player.CreatePlayerIfNotExists = function(playerId)
	local identifier = RDX.GetPlayerIdentifier(playerId)

	if identifier then
		MySQL.Async.fetchScalar('SELECT COUNT(*) AS `count` FROM `users` WHERE `identifier` = @identifier', {
			['@identifier'] = identifier
		}, function(result)
			if result == nil or result == 0 or (type(result) == 'table' and (result[1] == nil or result[1].count <= 0)) then
				local accounts = {}

				for account,money in pairs(Config.StartingAccountMoney) do
					accounts[account] = money
				end

				MySQL.Async.execute('INSERT INTO users (accounts, identifier) VALUES (@accounts, @identifier)', {
					['@accounts'] = json.encode(accounts),
					['@identifier'] = identifier
				}, function(rowsChanged)
					print(('[redm_extended] [^2INFO^7] A player with name "%s^7" has been created'):format(GetPlayerName(playerId)))
				end)
			end
		end)
	end
end

RDX.Player.LoadRDXPlayer = function(playerId)
	local identifier = RDX.GetPlayerIdentifier(playerId)
	local userData = {
		accounts = {},
		inventory = {},
		job = {},
		loadout = {},
		playerName = GetPlayerName(playerId),
		weight = 0
	}

	if (Config.EnableDebug) then
		userData.startTimer = GetGameTimer()
	end

	MySQL.Async.fetchAll('SELECT accounts, job, job_grade, `group`, loadout, position, inventory FROM users WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		async:foreach(result, function(user)
			local job, grade, jobObject, gradeObject = user.job, tostring(user.job_grade)
			local foundAccounts, foundItems = {}, {}

			-- Accounts
			if user.accounts and user.accounts ~= '' then
				local accounts = json.decode(user.accounts)

				foreach(accounts, function(money, account)
					foundAccounts[account] = money
				end)
			end

			table.sort(Config.Accounts, function(account1, account2)
				return account1.priority < account2.priority
			end)

			foreach(Config.Accounts, function(account, index)
				userData.accounts[index] = {
					name = account.name,
					money = foundAccounts[account.name] or Config.StartingAccountMoney[account.name] or 0,
					label = account.label
				}
			end)

			-- Job
			if RDX.DoesJobExist(job, grade) then
				jobObject, gradeObject = RDX.Jobs[job], RDX.Jobs[job].grades[grade]
			else
				print(('[redm_extended] [^3WARNING^7] Ignoring invalid job for %s [job: %s, grade: %s]'):format(identifier, job, grade))
				job, grade = 'unemployed', '0'
				jobObject, gradeObject = RDX.Jobs[job], RDX.Jobs[job].grades[grade]
			end

			userData.job.id = jobObject.id
			userData.job.name = jobObject.name
			userData.job.label = jobObject.label

			userData.job.grade = tonumber(grade)
			userData.job.grade_name = gradeObject.name
			userData.job.grade_label = gradeObject.label
			userData.job.grade_salary = gradeObject.salary

			userData.job.skin_male = {}
			userData.job.skin_female = {}

			if gradeObject.skin_male then userData.job.skin_male = json.decode(gradeObject.skin_male) end
			if gradeObject.skin_female then userData.job.skin_female = json.decode(gradeObject.skin_female) end

			-- Inventory
			if user.inventory and user.inventory ~= '' then
				local inventory = json.decode(user.inventory)

				foreach(inventory, function(count, name)
					local item = RDX.Items[name]

					if item then
						foundItems[name] = count
					else
						print(('[redm_extended] [^3WARNING^7] Ignoring invalid item "%s" for "%s"'):format(name, identifier))
					end
				end)
			end

			foreach(RDX.Items, function(item, name)
				local count = foundItems[name] or 0
				if count > 0 then userData.weight = userData.weight + (item.weight * count) end

				table.insert(userData.inventory, {
					name = name,
					count = count,
					label = item.label,
					weight = item.weight,
					usable = RDX.UsableItemsCallbacks[name] ~= nil,
					rare = item.rare,
					canRemove = item.canRemove
				})
			end)

			table.sort(userData.inventory, function(a, b)
				return a.label < b.label
			end)

			-- Group
			if user.group then
				userData.group = user.group
			else
				userData.group = 'user'
			end

			-- Loadout
			if user.loadout and user.loadout ~= '' then
				local loadout = json.decode(user.loadout)

				foreach(loadout, function(weapon, name)
					local label = RDX.GetWeaponLabel(name)

					if label then
						if not weapon.components then weapon.components = {} end

						table.insert(userData.loadout, {
							name = name,
							ammo = weapon.ammo,
							label = label,
							components = weapon.components
						})
					end
				end)
			end

			-- Position
			if user.position and user.position ~= '' then
				userData.coords = json.decode(user.position)
			else
				print('[redm_extended] [^3WARNING^7] Column "position" in "users" table is missing required default value. Using backup coords, fix your database.')
				userData.coords = {x = -269.4, y = -955.3, z = 31.2, heading = 205.8}
			end
		end, function()
			RDX.Player.Initialize(playerId, identifier, userData, function(xPlayer)
				TriggerEvent('rdx:playerLoaded', playerId, xPlayer)

				xPlayer.triggerEvent('rdx:playerLoaded', {
					playerId = xPlayer.source,
					accounts = xPlayer.getAccounts(),
					coords = xPlayer.getCoords(),
					identifier = xPlayer.getIdentifier(),
					inventory = xPlayer.getInventory(),
					job = xPlayer.getJob(),
					loadout = xPlayer.getLoadout(),
					maxWeight = xPlayer.getMaxWeight(),
					money = xPlayer.getMoney()
				})

				xPlayer.triggerEvent('rdx:createMissingPickups', RDX.Pickups)
				xPlayer.triggerEvent('rdx:registerSuggestions', RDX.RegisteredCommands)

				print(('[redm_extended] [^2INFO^7] A player with name "%s^7" has connected to the server with assigned player id %s'):format(xPlayer.getName(), playerId))

				if (Config.EnableDebug) then
					print(('[redm_extended] [DEBUG] RDX.Player.LoadRDXPlayer took %sms for creating player id %s'):format((GetGameTimer() - userData.startTimer), playerId))
				end
			end)
		end)
	end)
end

AddEventHandler('chatMessage', function(playerId, author, message)
	if message:sub(1, 1) == '/' and playerId > 0 then
		CancelEvent()
		local commandName = message:sub(1):gmatch("%w+")()
		TriggerClientEvent('chat:addMessage', playerId, {args = {'^1SYSTEM', _U('commanderror_invalidcommand', commandName)}})
	end
end)

AddEventHandler('playerDropped', function(reason)
	local playerId = source
	local xPlayer = RDX.GetPlayerFromId(playerId)

	if xPlayer then
		TriggerEvent('rdx:playerDropped', playerId, reason)

		RDX.SavePlayer(xPlayer, function()
			RDX.Players[playerId] = nil
		end)
	end
end)

RegisterNetEvent('rdx:updateCoords')
AddEventHandler('rdx:updateCoords', function(coords)
	local xPlayer = RDX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.updateCoords(coords)
	end
end)

RegisterNetEvent('rdx:updateWeaponAmmo')
AddEventHandler('rdx:updateWeaponAmmo', function(weaponName, ammoCount)
	local xPlayer = RDX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.updateWeaponAmmo(weaponName, ammoCount)
	end
end)

RegisterNetEvent('rdx:giveInventoryItem')
AddEventHandler('rdx:giveInventoryItem', function(target, type, itemName, itemCount)
	local playerId = source
	local sourceXPlayer = RDX.GetPlayerFromId(playerId)
	local targetXPlayer = RDX.GetPlayerFromId(target)

	if type == 'item_standard' then
		local sourceItem = sourceXPlayer.getInventoryItem(itemName)

		if itemCount > 0 and sourceItem.count >= itemCount then
			if targetXPlayer.canCarryItem(itemName, itemCount) then
				sourceXPlayer.removeInventoryItem(itemName, itemCount)
				targetXPlayer.addInventoryItem   (itemName, itemCount)

				sourceXPlayer.showNotification(_U('gave_item', itemCount, sourceItem.label, targetXPlayer.name))
				targetXPlayer.showNotification(_U('received_item', itemCount, sourceItem.label, sourceXPlayer.name))
			else
				sourceXPlayer.showNotification(_U('ex_inv_lim', targetXPlayer.name))
			end
		else
			sourceXPlayer.showNotification(_U('imp_invalid_quantity'))
		end
	elseif type == 'item_account' then
		if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
			sourceXPlayer.removeAccountMoney(itemName, itemCount)
			targetXPlayer.addAccountMoney   (itemName, itemCount)

			sourceXPlayer.showNotification(_U('gave_account_money', RDX.Math.GroupDigits(itemCount), RDX.GetAccountLabel(itemName), targetXPlayer.name))
			targetXPlayer.showNotification(_U('received_account_money', RDX.Math.GroupDigits(itemCount), RDX.GetAccountLabel(itemName), sourceXPlayer.name))
		else
			sourceXPlayer.showNotification(_U('imp_invalid_amount'))
		end
	elseif type == 'item_weapon' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponLabel = RDX.GetWeaponLabel(itemName)

			if not targetXPlayer.hasWeapon(itemName) then
				local _, weapon = sourceXPlayer.getWeapon(itemName)
				local _, weaponObject = RDX.GetWeapon(itemName)
				itemCount = weapon.ammo

				sourceXPlayer.removeWeapon(itemName)
				targetXPlayer.addWeapon(itemName, itemCount)

				if weaponObject.ammo and itemCount > 0 then
					local ammoLabel = weaponObject.ammo.label
					sourceXPlayer.showNotification(_U('gave_weapon_withammo', weaponLabel, itemCount, ammoLabel, targetXPlayer.name))
					targetXPlayer.showNotification(_U('received_weapon_withammo', weaponLabel, itemCount, ammoLabel, sourceXPlayer.name))
				else
					sourceXPlayer.showNotification(_U('gave_weapon', weaponLabel, targetXPlayer.name))
					targetXPlayer.showNotification(_U('received_weapon', weaponLabel, sourceXPlayer.name))
				end
			else
				sourceXPlayer.showNotification(_U('gave_weapon_hasalready', targetXPlayer.name, weaponLabel))
				targetXPlayer.showNotification(_U('received_weapon_hasalready', sourceXPlayer.name, weaponLabel))
			end
		end
	elseif type == 'item_ammo' then
		if sourceXPlayer.hasWeapon(itemName) then
			local weaponNum, weapon = sourceXPlayer.getWeapon(itemName)

			if targetXPlayer.hasWeapon(itemName) then
				local _, weaponObject = RDX.GetWeapon(itemName)

				if weaponObject.ammo then
					local ammoLabel = weaponObject.ammo.label

					if weapon.ammo >= itemCount then
						sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
						targetXPlayer.addWeaponAmmo(itemName, itemCount)

						sourceXPlayer.showNotification(_U('gave_weapon_ammo', itemCount, ammoLabel, weapon.label, targetXPlayer.name))
						targetXPlayer.showNotification(_U('received_weapon_ammo', itemCount, ammoLabel, weapon.label, sourceXPlayer.name))
					end
				end
			else
				sourceXPlayer.showNotification(_U('gave_weapon_noweapon', targetXPlayer.name))
				targetXPlayer.showNotification(_U('received_weapon_noweapon', sourceXPlayer.name, weapon.label))
			end
		end
	end
end)

RegisterNetEvent('rdx:removeInventoryItem')
AddEventHandler('rdx:removeInventoryItem', function(type, itemName, itemCount)
	local playerId = source
	local xPlayer = RDX.GetPlayerFromId(source)

	if type == 'item_standard' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification(_U('imp_invalid_quantity'))
		else
			local xItem = xPlayer.getInventoryItem(itemName)

			if (itemCount > xItem.count or xItem.count < 1) then
				xPlayer.showNotification(_U('imp_invalid_quantity'))
			else
				xPlayer.removeInventoryItem(itemName, itemCount)
				local pickupLabel = ('~y~%s~s~ [~b~%s~s~]'):format(xItem.label, itemCount)
				RDX.CreatePickup('item_standard', itemName, itemCount, pickupLabel, playerId)
				xPlayer.showNotification(_U('threw_standard', itemCount, xItem.label))
			end
		end
	elseif type == 'item_account' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showNotification(_U('imp_invalid_amount'))
		else
			local account = xPlayer.getAccount(itemName)

			if (itemCount > account.money or account.money < 1) then
				xPlayer.showNotification(_U('imp_invalid_amount'))
			else
				xPlayer.removeAccountMoney(itemName, itemCount)
				local pickupLabel = ('~y~%s~s~ [~g~%s~s~]'):format(account.label, _U('locale_currency', RDX.Math.GroupDigits(itemCount)))
				RDX.CreatePickup('item_account', itemName, itemCount, pickupLabel, playerId)
				xPlayer.showNotification(_U('threw_account', RDX.Math.GroupDigits(itemCount), string.lower(account.label)))
			end
		end
	elseif type == 'item_weapon' then
		itemName = string.upper(itemName)

		if xPlayer.hasWeapon(itemName) then
			local _, weapon = xPlayer.getWeapon(itemName)
			local _, weaponObject = RDX.GetWeapon(itemName)
			local components, pickupLabel = RDX.Table.Clone(weapon.components)
			xPlayer.removeWeapon(itemName)

			if weaponObject.ammo and weapon.ammo > 0 then
				local ammoLabel = weaponObject.ammo.label
				pickupLabel = ('~y~%s~s~ [~g~%s~s~ %s]'):format(weapon.label, weapon.ammo, ammoLabel)
				xPlayer.showNotification(_U('threw_weapon_ammo', weapon.label, weapon.ammo, ammoLabel))
			else
				pickupLabel = ('~y~%s~s~'):format(weapon.label)
				xPlayer.showNotification(_U('threw_weapon', weapon.label))
			end

			RDX.CreatePickup('item_weapon', itemName, weapon.ammo, pickupLabel, playerId, components)
		end
	end
end)

RegisterNetEvent('rdx:useItem')
AddEventHandler('rdx:useItem', function(itemName)
	local xPlayer = RDX.GetPlayerFromId(source)
	local count = xPlayer.getInventoryItem(itemName).count

	if count > 0 then
		RDX.UseItem(source, itemName)
	else
		xPlayer.showNotification(_U('act_imp'))
	end
end)

RegisterNetEvent('rdx:onPickup')
AddEventHandler('rdx:onPickup', function(pickupId)
	local pickup, xPlayer, success = RDX.Pickups[pickupId], RDX.GetPlayerFromId(source)

	if pickup then
		if pickup.type == 'item_standard' then
			if xPlayer.canCarryItem(pickup.name, pickup.count) then
				xPlayer.addInventoryItem(pickup.name, pickup.count)
				success = true
			else
				xPlayer.showNotification(_U('threw_cannot_pickup'))
			end
		elseif pickup.type == 'item_account' then
			success = true
			xPlayer.addAccountMoney(pickup.name, pickup.count)
		elseif pickup.type == 'item_weapon' then
			if xPlayer.hasWeapon(pickup.name) then
				xPlayer.showNotification(_U('threw_weapon_already'))
			else
				success = true
				xPlayer.addWeapon(pickup.name, pickup.count)

				for i = 1, #pickup.components do
					xPlayer.addWeaponComponent(pickup.name, pickup.components[i])
				end
			end
		end

		if success then
			RDX.Pickups[pickupId] = nil
			TriggerClientEvent('rdx:removePickup', -1, pickupId)
		end
	end
end)

RDX.RegisterServerCallback('rdx:getPlayerData', function(source, cb)
	local xPlayer = RDX.GetPlayerFromId(source)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		loadout      = xPlayer.getLoadout(),
		money        = xPlayer.getMoney()
	})
end)

RDX.RegisterServerCallback('rdx:getOtherPlayerData', function(source, cb, target)
	local xPlayer = RDX.GetPlayerFromId(target)

	cb({
		identifier   = xPlayer.identifier,
		accounts     = xPlayer.getAccounts(),
		inventory    = xPlayer.getInventory(),
		job          = xPlayer.getJob(),
		loadout      = xPlayer.getLoadout(),
		money        = xPlayer.getMoney()
	})
end)

RDX.RegisterServerCallback('rdx:getPlayerNames', function(source, cb, players)
	players[source] = nil

	for playerId,v in pairs(players) do
		local xPlayer = RDX.GetPlayerFromId(playerId)

		if xPlayer then
			players[playerId] = xPlayer.getName()
		else
			players[playerId] = nil
		end
	end

	cb(players)
end)

RDX.StartDBSync()
RDX.StartPayCheck()
