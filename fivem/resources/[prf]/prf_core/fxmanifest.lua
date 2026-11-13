fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Nova Byte'
description 'PRF RP Legacy - base, favela, blitz, guincho, reforco e rondas'
version '0.5.0'

shared_script 'config.lua'
shared_script 'operations_config.lua'
client_scripts {
  'client.lua',
  'base_client.lua',
  'keys_client.lua',
  'squad_client.lua',
  'operations_client.lua',
  'traffic_client.lua',
  'backup_client.lua',
  'people_client.lua',
  'commands_client.lua'
}
server_script 'server.lua'
server_script 'backup_server.lua'
server_script 'people_server.lua'
server_script 'operations_server.lua'
server_script 'commands_server.lua'
