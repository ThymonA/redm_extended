RDX = {}
RDX.Players = {}
RDX.UsableItemsCallbacks = {}
RDX.Items = {}
RDX.ServerCallbacks = {}
RDX.TimeoutCount = -1
RDX.CancelledTimeouts = {}
RDX.Pickups = {}
RDX.PickupId = 0
RDX.Jobs = {}
RDX.RegisteredCommands = {}

AddEventHandler('rdx:getSharedObject', function(cb)
	cb(RDX)
end)

function getSharedObject()
	return RDX
end

MySQL.ready(function()
	MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
		for k,v in ipairs(result) do
			RDX.Items[v.name] = {
				label = v.label,
				weight = v.weight,
				rare = v.rare,
				canRemove = v.can_remove
			}
		end
	end)

	MySQL.Async.fetchAll('SELECT * FROM jobs', {}, function(jobs)
		for k,v in ipairs(jobs) do
			RDX.Jobs[v.name] = v
			RDX.Jobs[v.name].grades = {}
		end

		MySQL.Async.fetchAll('SELECT * FROM job_grades', {}, function(jobGrades)
			for k,v in ipairs(jobGrades) do
				if RDX.Jobs[v.job_name] then
					RDX.Jobs[v.job_name].grades[tostring(v.grade)] = v
				else
					print(('[redm_extended] [^3WARNING^7] Ignoring job grades for "%s" due to missing job'):format(v.job_name))
				end
			end

			for k2,v2 in pairs(RDX.Jobs) do
				if RDX.Table.SizeOf(v2.grades) == 0 then
					RDX.Jobs[v2.name] = nil
					print(('[redm_extended] [^3WARNING^7] Ignoring job "%s" due to no job grades found'):format(v2.name))
				end
			end
		end)
	end)

	print('[redm_extended] [^2INFO^7] RDX by ESX-Org and modified by TIGO has been initialized')
end)

RegisterServerEvent('rdx:clientLog')
AddEventHandler('rdx:clientLog', function(msg)
	if Config.EnableDebug then
		print(('[redm_extended] [^2TRACE^7] %s^7'):format(msg))
	end
end)

RegisterServerEvent('rdx:triggerServerCallback')
AddEventHandler('rdx:triggerServerCallback', function(name, requestId, ...)
	local playerId = source

	RDX.TriggerServerCallback(name, requestId, playerId, function(...)
		TriggerClientEvent('rdx:serverCallback', playerId, requestId, ...)
	end, ...)
end)
