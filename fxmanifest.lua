fx_version 'adamant'

game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

description 'RMX (RedM Extended)'

version '1.0.0'

server_scripts {
	'libs/libs.lua',

	'@async/async.lua',
	'@mysql-async/lib/MySQL.lua',

	'locale.lua',
	'locales/en.lua',

	'configs/config.lua',
	'configs/config.weapons.lua',
	'configs/config.horses.lua',

	'server/common.lua',
	'server/objects/player.lua',
	'server/functions.lua',
	'server/paycheck.lua',
	'server/main.lua',
	'server/commands.lua',

	'common/modules/math.lua',
	'common/modules/table.lua',
	'common/functions.lua'
}

client_scripts {
	'libs/libs.lua',

	'locale.lua',
	'locales/en.lua',

	'configs/config.lua',
	'configs/config.weapons.lua',
	'configs/config.horses.lua',

	'client/common.lua',
	'client/entityiter.lua',
	'client/main.js',
	'client/functions.lua',
	'client/wrapper.lua',
	'client/main.lua',

	'client/modules/death.lua',
	'client/modules/scaleform.lua',
	'client/modules/streaming.lua',

	'common/modules/math.lua',
	'common/modules/table.lua',
	'common/functions.lua'
}

ui_page {
	'html/ui.html'
}

files {
	'locale.js',
	'html/ui.html',

	'html/css/app.css',

	'html/js/mustache.min.js',
	'html/js/wrapper.js',
	'html/js/app.js',

	'html/fonts/pdown.ttf',
	'html/fonts/bankgothic.ttf',
	'html/fonts/RDR/HapnaSlabSerif-DemiBold.eot',
	'html/fonts/RDR/HapnaSlabSerif-DemiBold.ttf',
	'html/fonts/RDR/HapnaSlabSerif-DemiBold.woff',
	'html/fonts/RDR/HapnaSlabSerif-DemiBold.woff2',
	'html/fonts/RDR/RDRCatalogueBold-Bold.eot',
	'html/fonts/RDR/RDRCatalogueBold-Bold.ttf',
	'html/fonts/RDR/RDRCatalogueBold-Bold.woff',
	'html/fonts/RDR/RDRCatalogueBold-Bold.woff2',
	'html/fonts/RDR/RDRGothica-Regular.eot',
	'html/fonts/RDR/RDRGothica-Regular.ttf',
	'html/fonts/RDR/RDRGothica-Regular.woff',
	'html/fonts/RDR/RDRGothica-Regular.woff2',
	'html/fonts/RDR/RDRLino-Regular.eot',
	'html/fonts/RDR/RDRLino-Regular.ttf',
	'html/fonts/RDR/RDRLino-Regular.woff',
	'html/fonts/RDR/RDRLino-Regular.woff2',
	'html/fonts/RDR/Redemption.eot',
	'html/fonts/RDR/Redemption.ttf',
	'html/fonts/RDR/Redemption.woff',
	'html/fonts/RDR/Redemption.woff2',

	'html/img/accounts/bank.png',
	'html/img/accounts/black_money.png',
	'html/img/accounts/money.png'
}

export 'getSharedObject'

server_exports {
	'getSharedObject'
}

dependencies {
	'mysql-async',
	'async'
}
