fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Nova Byte'
description 'PRF RP Legacy - base, favela, blitz, guincho, reforco e rondas'
version '0.8.0'

shared_script 'config.lua'
shared_script 'operations_config.lua'
shared_script 'gameplay_config.lua'
shared_script 'copom_config.lua'
ui_page 'html/index.html'
files { 'html/index.html', 'html/style.css', 'html/app.js' }
client_scripts {
  'base_stream_client.lua',
  'client.lua',
  'base_client.lua',
  'keys_client.lua',
  'blitz_client.lua',
  'squad_client.lua',
  'operations_client.lua',
  'traffic_client.lua',
  'backup_client.lua',
  'inventory_client.lua',
  'tablet_client.lua',
  'services_client.lua',
  'people_client.lua',
  'copom_client.lua',
  'commands_client.lua'
}
server_script 'progress_server.lua'
server_script 'server.lua'
server_script 'backup_server.lua'
server_script 'inventory_server.lua'
server_script 'people_server.lua'
server_script 'blitz_server.lua'
server_script 'services_server.lua'
server_script 'operations_server.lua'
server_script 'copom_server.lua'
server_script 'commands_server.lua'
