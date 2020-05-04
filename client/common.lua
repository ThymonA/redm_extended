AddEventHandler('rdx:getSharedObject', function(cb)
	cb(RDX)
end)

function getSharedObject()
	return RDX
end

exports('getSharedObject', function()
	return RDX
end)