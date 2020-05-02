RDX = {}
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
		for i = 1, #result do
			local item = result[i]

			RDX.Items[item.name] = {
				label = item.label,
				weight = item.weight,
				rare = item.rare,
				canRemove = item.can_remove
			}
		end
	end)

	MySQL.Async.fetchAll('SELECT * FROM jobs', {}, function(jobs)
		for i = 1, #jobs do
			local job = jobs[i]

			RDX.Jobs[job.name] = job
			RDX.Jobs[job.name].grades = {}
		end

		MySQL.Async.fetchAll('SELECT * FROM job_grades', {}, function(jobGrades)
			for i = 1, #jobGrades do
				local jobGrade = jobGrades[i]

				if RDX.Jobs[jobGrade.job_name] then
					RDX.Jobs[jobGrade.job_name].grades[tostring(jobGrade.grade)] = jobGrade
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
