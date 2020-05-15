Config = {}
Config.Locale = 'en'

Config.Accounts = {
	{ name = 'bank', label = _U('account_bank'), priority = 0 },
	{ name = 'black_money', label = _U('account_black_money'), priority = 1 },
	{ name = 'money', label = _U('account_money'), priority = 2 }
}

Config.StartingAccountMoney = { bank = 50000 }

Config.EnableSocietyPayouts = false -- pay from the society account that the player is employed at? Requirement: esx_society
Config.EnableHud            = true -- enable the default hud? Display current job and accounts (black, bank & cash)
Config.MaxWeight            = 24   -- the max inventory weight without backpack
Config.PaycheckInterval     = 7 * 60000 -- how often to recieve pay checks in milliseconds
Config.EnableDebug          = false
Config.AutoStopResources	= false -- `true` is recommended because those resources are incompatible with RDX framework, `false` is default for visibility in server list
Config.DefaultIdentifier	= 'license' -- Options: `steam`, `license`, `fivem`, `discord`, `xbl`, `live` and `ip`, default `license`

Config.IncompatibleResourcesToStop = {
	['spawnmanager'] = 'Default resource that takes care of spawning players, RDX does this already',
	['mapmanager'] = 'Default resource that was required by spawnmanager, but neither are used',
	['basic-gamemode'] = 'Resource that is solely for choosing the default game type',
	['fivem'] = 'Resource that is solely for choosing the default game type',
	['fivem-map-hipster'] = 'Default spawn locations for mapmanager',
	['fivem-map-skater'] = 'Default spawn locations for mapmanager',
	['baseevents'] = 'Default resource for handling death events, RDX does this already'
}