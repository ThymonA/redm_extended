RDX.Player				= {}
RDX.Players 			= {}

-- Creating a player object
RDX.Player.Initialize = function(playerId, identifier, userData, cb)
	Citizen.CreateThread(function()
		local u = (playerId or 0)

		if (RDX.Players == nil) then
			RDX.Players = {}
		end

		if (RDX.Players[u] ~= nil) then
			print(('[redm_extended] [^3ERROR^7] Trying to initialize an existing player (%s)'):format(u))

			if (cb ~= nil) then cb(RDX.Players[u]) end

			return
		end

		RDX.Players[u] = {}
		RDX.Players[u].source = u
		RDX.Players[u].playerId = u
		RDX.Players[u].identifier = identifier or 'none'
		RDX.Players[u].group = userData.group or 'user'
		RDX.Players[u].accounts = userData.accounts or {}
		RDX.Players[u].coords = userData.coords or {}
		RDX.Players[u].inventory = userData.inventory or {}
		RDX.Players[u].weight = userData.weight or 0
		RDX.Players[u].job = userData.job or {}
		RDX.Players[u].loadout = userData.loadout or {}
		RDX.Players[u].name = userData.playerName or 'Unknown'
		RDX.Players[u].variables = {}
		RDX.Players[u].maxWeight = Config.maxWeight or 25
		RDX.Players[u].createdAt = os.time()

		ExecuteCommand(('add_principal identifier.license:%s group.%s'):format(RDX.Players[u].identifier, RDX.Players[u].group))

		RDX.Players[u].triggerEvent = function(eventName, ...)
			TriggerClientEvent(eventName, RDX.Players[u].source, ...)
		end

		RDX.Players[u].setCoords = function(coords)
			RDX.Players[u].updateCoords(coords)
			RDX.Players[u].triggerEvent('rdx:teleport', coords)
		end

		RDX.Players[u].updateCoords = function(coords)
			RDX.Players[u].coords = {x = RDX.Math.Round(coords.x, 1), y = RDX.Math.Round(coords.y, 1), z = RDX.Math.Round(coords.z, 1), heading = RDX.Math.Round(coords.heading or 0.0, 1)}
		end

		RDX.Players[u].getCoords = function(vector)
			if vector then
				return vector3(RDX.Players[u].coords.x, RDX.Players[u].coords.y, RDX.Players[u].coords.z)
			else
				return RDX.Players[u].coords
			end
		end

		RDX.Players[u].kick = function(reason)
			DropPlayer(RDX.Players[u].source, reason)
		end

		RDX.Players[u].setMoney = function(money)
			money = RDX.Math.Round(money)
			RDX.Players[u].setAccountMoney('money', money)
		end

		RDX.Players[u].getMoney = function()
			return RDX.Players[u].getAccount('money').money
		end

		RDX.Players[u].addMoney = function(money)
			money = RDX.Math.Round(money)
			RDX.Players[u].addAccountMoney('money', money)
		end

		RDX.Players[u].removeMoney = function(money)
			money = RDX.Math.Round(money)
			RDX.Players[u].removeAccountMoney('money', money)
		end

		RDX.Players[u].getIdentifier = function()
			return RDX.Players[u].identifier
		end

		RDX.Players[u].setGroup = function(newGroup)
			ExecuteCommand(('remove_principal identifier.license:%s group.%s'):format(RDX.Players[u].identifier, RDX.Players[u].group))
			RDX.Players[u].group = newGroup
			ExecuteCommand(('add_principal identifier.license:%s group.%s'):format(RDX.Players[u].identifier, RDX.Players[u].group))
		end

		RDX.Players[u].getGroup = function()
			return RDX.Players[u].group
		end

		RDX.Players[u].set = function(k, v)
			RDX.Players[u].variables[k] = v
		end

		RDX.Players[u].get = function(k)
			return RDX.Players[u].variables[k]
		end

		RDX.Players[u].getAccounts = function(minimal)
			if minimal then
				local minimalAccounts = {}

				foreach(RDX.Players[u].accounts, function(account)
					minimalAccounts[account.name] = account.money
				end)

				return minimalAccounts
			else
				return RDX.Players[u].accounts
			end
		end

		RDX.Players[u].getAccount = function(account)
			return foreach(RDX.Players[u].accounts, function(_account)
				if _account.name == account then
					return _account
				end
			end)
		end

		RDX.Players[u].getInventory = function(minimal)
			if minimal then
				local minimalInventory = {}

				foreach(RDX.Players[u].inventory, function(item)
					if item.count > 0 then
						minimalInventory[item.name] = item.count
					end
				end)

				return minimalInventory
			else
				return RDX.Players[u].inventory
			end
		end

		RDX.Players[u].getJob = function()
			return RDX.Players[u].job
		end

		RDX.Players[u].getLoadout = function(minimal)
			if minimal then
				local minimalLoadout = {}

				foreach(RDX.Players[u].loadout, function(_loadout)
					minimalLoadout[_loadout.name] = {ammo = _loadout.ammo}

					if #_loadout.components > 0 then
						local components = {}

						foreach(_loadout.components, function(component)
							if component ~= 'clip_default' then
								table.insert(components, component)
							end
						end)

						if #components > 0 then
							minimalLoadout[_loadout.name].components = components
						end
					end
				end)

				return minimalLoadout
			else
				return RDX.Players[u].loadout
			end
		end

		RDX.Players[u].getName = function()
			return RDX.Players[u].name
		end

		RDX.Players[u].setName = function(newName)
			RDX.Players[u].name = newName
		end

		RDX.Players[u].setAccountMoney = function(accountName, money)
			if money >= 0 then
				local account = RDX.Players[u].getAccount(accountName)

				if account then
					local newMoney = RDX.Math.Round(money)

					account.money = newMoney

					RDX.Players[u].triggerEvent('rdx:setAccountMoney', account)
				end
			end
		end

		RDX.Players[u].addAccountMoney = function(accountName, money)
			if money > 0 then
				local account = RDX.Players[u].getAccount(accountName)

				if account then
					local newMoney = account.money + RDX.Math.Round(money)
					account.money = newMoney

					RDX.Players[u].triggerEvent('rdx:setAccountMoney', account)
				end
			end
		end

		RDX.Players[u].removeAccountMoney = function(accountName, money)
			if money > 0 then
				local account = RDX.Players[u].getAccount(accountName)

				if account then
					local newMoney = account.money - RDX.Math.Round(money)
					account.money = newMoney

					RDX.Players[u].triggerEvent('rdx:setAccountMoney', account)
				end
			end
		end

		RDX.Players[u].getInventoryItem = function(name)
			return foreach(RDX.Players[u].inventory, function(item)
				if item.name == name then
					return item
				end
			end)
		end

		RDX.Players[u].addInventoryItem = function(name, count)
			local item = RDX.Players[u].getInventoryItem(name)

			if item then
				count = RDX.Math.Round(count)
				item.count = item.count + count
				RDX.Players[u].weight = RDX.Players[u].weight + (item.weight * count)

				TriggerEvent('rdx:onAddInventoryItem', RDX.Players[u].source, item.name, item.count)
				RDX.Players[u].triggerEvent('rdx:addInventoryItem', item.name, item.count)
			end
		end

		RDX.Players[u].removeInventoryItem = function(name, count)
			local item = RDX.Players[u].getInventoryItem(name)

			if item then
				count = RDX.Math.Round(count)
				local newCount = item.count - count

				if newCount >= 0 then
					item.count = newCount
					RDX.Players[u].weight = RDX.Players[u].weight - (item.weight * count)

					TriggerEvent('rdx:onRemoveInventoryItem', RDX.Players[u].source, item.name, item.count)
					RDX.Players[u].triggerEvent('rdx:removeInventoryItem', item.name, item.count)
				end
			end
		end

		RDX.Players[u].setInventoryItem = function(name, count)
			local item = RDX.Players[u].getInventoryItem(name)

			if item and count >= 0 then
				count = RDX.Math.Round(count)

				if count > item.count then
					RDX.Players[u].addInventoryItem(item.name, count - item.count)
				else
					RDX.Players[u].removeInventoryItem(item.name, item.count - count)
				end
			end
		end

		RDX.Players[u].getWeight = function()
			return RDX.Players[u].weight
		end

		RDX.Players[u].getMaxWeight = function()
			return RDX.Players[u].maxWeight
		end

		RDX.Players[u].canCarryItem = function(name, count)
			local currentWeight, itemWeight = RDX.Players[u].weight, RDX.Items[name].weight
			local newWeight = currentWeight + (itemWeight * count)

			return newWeight <= RDX.Players[u].maxWeight
		end

		RDX.Players[u].canSwapItem = function(firstItem, firstItemCount, testItem, testItemCount)
			local firstItemObject = RDX.Players[u].getInventoryItem(firstItem)
			local testItemObject = RDX.Players[u].getInventoryItem(testItem)

			if firstItemObject.count >= firstItemCount then
				local weightWithoutFirstItem = RDX.Math.Round(RDX.Players[u].weight - (firstItemObject.weight * firstItemCount))
				local weightWithTestItem = RDX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

				return weightWithTestItem <= RDX.Players[u].maxWeight
			end

			return false
		end

		RDX.Players[u].setMaxWeight = function(newWeight)
			RDX.Players[u].maxWeight = newWeight
			RDX.Players[u].triggerEvent('rdx:setMaxWeight', RDX.Players[u].maxWeight)
		end

		RDX.Players[u].setJob = function(job, grade)
			grade = tostring(grade)
			local lastJob = json.decode(json.encode(RDX.Players[u].job))

			if RDX.DoesJobExist(job, grade) then
				local jobObject, gradeObject = RDX.Jobs[job], RDX.Jobs[job].grades[grade]

				RDX.Players[u].job.id    = jobObject.id
				RDX.Players[u].job.name  = jobObject.name
				RDX.Players[u].job.label = jobObject.label

				RDX.Players[u].job.grade        = tonumber(grade)
				RDX.Players[u].job.grade_name   = gradeObject.name
				RDX.Players[u].job.grade_label  = gradeObject.label
				RDX.Players[u].job.grade_salary = gradeObject.salary

				if gradeObject.skin_male then
					RDX.Players[u].job.skin_male = json.decode(gradeObject.skin_male)
				else
					RDX.Players[u].job.skin_male = {}
				end

				if gradeObject.skin_female then
					RDX.Players[u].job.skin_female = json.decode(gradeObject.skin_female)
				else
					RDX.Players[u].job.skin_female = {}
				end

				TriggerEvent('rdx:setJob', RDX.Players[u].source, RDX.Players[u].job, lastJob)

				RDX.Players[u].triggerEvent('rdx:setJob', RDX.Players[u].job)
			else
				print(('[redm_extended] [^3WARNING^7] Ignoring invalid .setJob() usage for "%s"'):format(RDX.Players[u].identifier))
			end
		end

		RDX.Players[u].addWeapon = function(weaponName, ammo)
			if not RDX.Players[u].hasWeapon(weaponName) then
				local weaponLabel = RDX.GetWeaponLabel(weaponName)

				table.insert(RDX.Players[u].loadout, {
					name = weaponName,
					ammo = ammo,
					label = weaponLabel,
					components = {},
					tintIndex = 0
				})

				RDX.Players[u].triggerEvent('rdx:addWeapon', weaponName, 0) --Prevent duplicate ammo
				RDX.Players[u].triggerEvent('rdx:setWeaponAmmo', weaponName, ammo)
				RDX.Players[u].triggerEvent('rdx:addInventoryItem', weaponLabel, false, true)
			end
		end

		RDX.Players[u].addWeaponComponent = function(weaponName, weaponComponent)
			local loadoutNum, weapon = RDX.Players[u].getWeapon(weaponName)

			if weapon then
				local component = RDX.GetWeaponComponent(weaponName, weaponComponent)

				if component then
					if not RDX.Players[u].hasWeaponComponent(weaponName, weaponComponent) then
						table.insert(RDX.Players[u].loadout[loadoutNum].components, weaponComponent)
						RDX.Players[u].triggerEvent('rdx:addWeaponComponent', weaponName, weaponComponent)
						RDX.Players[u].triggerEvent('rdx:addInventoryItem', component.label, false, true)
					end
				end
			end
		end

		RDX.Players[u].addWeaponAmmo = function(weaponName, ammoCount)
			local loadoutNum, weapon = RDX.Players[u].getWeapon(weaponName)

			if weapon then
				weapon.ammo = weapon.ammo + ammoCount
				RDX.Players[u].triggerEvent('rdx:setWeaponAmmo', weaponName, weapon.ammo)
			end
		end

		RDX.Players[u].updateWeaponAmmo = function(weaponName, ammoCount)
			local loadoutNum, weapon = RDX.Players[u].getWeapon(weaponName)

			if weapon then
				if ammoCount < weapon.ammo then
					weapon.ammo = ammoCount
				end
			end
		end

		RDX.Players[u].removeWeapon = function(weaponName)
			local weaponLabel
			for k, v in pairs(RDX.Players[u].loadout) do
				if v.name == weaponName then
					weaponLabel = v.label
					foreach(v.components, function(component)
						RDX.Players[u].removeWeaponComponent(weaponName, component)
					end)
					table.remove(RDX.Players[u].loadout, k)
					break
				end
			end
			if weaponLabel then
				RDX.Players[u].triggerEvent('rdx:removeWeapon', weaponName)
				RDX.Players[u].triggerEvent('rdx:removeInventoryItem', weaponLabel, false, true)
			end
		end

		RDX.Players[u].removeWeaponComponent = function(weaponName, weaponComponent)
			local loadoutNum, weapon = RDX.Players[u].getWeapon(weaponName)

			if weapon then
				local component = RDX.GetWeaponComponent(weaponName, weaponComponent)

				if component then
					if RDX.Players[u].hasWeaponComponent(weaponName, weaponComponent) then
						foreach(RDX.Players[u].loadout[loadoutNum].components, function(_component, i)
							if _component == weaponComponent then
								table.remove(RDX.Players[u].loadout[loadoutNum].components, i)
								return
							end
						end)

						RDX.Players[u].triggerEvent('rdx:removeWeaponComponent', weaponName, weaponComponent)
						RDX.Players[u].triggerEvent('rdx:removeInventoryItem', component.label, false, true)
					end
				end
			end
		end

		RDX.Players[u].removeWeaponAmmo = function(weaponName, ammoCount)
			local loadoutNum, weapon = RDX.Players[u].getWeapon(weaponName)

			if weapon then
				weapon.ammo = weapon.ammo - ammoCount
				RDX.Players[u].triggerEvent('rdx:setWeaponAmmo', weaponName, weapon.ammo)
			end
		end

		RDX.Players[u].hasWeaponComponent = function(weaponName, weaponComponent)
			local loadoutNum, weapon = RDX.Players[u].getWeapon(weaponName)

			if weapon then
				return foreach(weapon.components, function(component)
					if component == weaponComponent then
						return true
					end
				end) or false
			else
				return false
			end
		end

		RDX.Players[u].hasWeapon = function(weaponName)
			return foreach(RDX.Players[u].loadout, function(loadout)
				if loadout.name == weaponName then
					return true
				end
			end) or false
		end

		RDX.Players[u].getWeapon = function(weaponName)
			for k,v in pairs(RDX.Players[u].loadout) do
				if v.name == weaponName then
					return k, v
				end
			end
			return
		end

		RDX.Players[u].showNotification = function(msg, flash, saveToBrief, hudColorIndex)
			RDX.Players[u].triggerEvent('rdx:showNotification', msg, flash, saveToBrief, hudColorIndex)
		end

		RDX.Players[u].showHelpNotification = function(msg, thisFrame, beep, duration)
			RDX.Players[u].triggerEvent('rdx:showHelpNotification', msg, thisFrame, beep, duration)
		end

		if (cb ~= nil) then cb(RDX.Players[u]) end
	end)
end
