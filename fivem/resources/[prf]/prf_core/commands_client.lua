-- Usa o chat padrao, sem NUI ou paineis e sem capturar as teclas numericas.
local function notice(message)
  TriggerEvent('chat:addMessage',{color={245,210,65},args={'PRF',tostring(message)}})
end
AddEventHandler('prfrp:chatNotice',notice)
local function help()
  notice('T > servico | viatura | farda | fuzil | giroflex | sirene | equipe')
  notice('Aponte a arma para abordar uma pessoa. T > documento | antecedentes | revistar | liberar')
  notice('T > abordar (pessoa/carro) | guincho | reforco | blitz | ronda | cancelarronda | base | favela')
  notice('Digite a palavra e Enter. Tambem aceita /viatura, /revistar etc. Dados e antecedentes sao ficticios.')
end
AddEventHandler('prfrp:chatHelp',help)
local function execute(name)
  local action=Config.ChatCommands[name]
  if not action then return end
  if action=='help' then help()
  elseif action=='approach' then TriggerEvent('prfrp:person:approachCommand')
  elseif action=='lights' then TriggerEvent('prfrp:toggleEmergencyLights')
  elseif action=='siren' then TriggerEvent('prfrp:toggleSirenSound')
  elseif action=='team' then TriggerEvent('prfrp:squadRally')
  elseif action=='blitz' or action=='release' then TriggerEvent('prfrp:ops:command',action)
  elseif action=='base' or action=='favela' then
    local resource=action=='base' and Config.CustomBaseResource or 'prf_favela_realista'
    if GetResourceState(resource)~='started' then notice('Mapa ainda nao iniciou: '..resource); return end
    local point=action=='base' and Config.CustomBase or Config.Operations.missions[1].points[1]
    SetNewWaypoint(point.x,point.y)
    notice('Destino marcado no GPS: '..(action=='base' and 'base PRF' or 'favela')..'.')
  elseif action=='duty' or action=='vehicle' or action=='uniform' or action=='weapon'
    or action=='call' or action=='cancel' or action=='status' then
    TriggerServerEvent('prfrp:requestAction',action)
  else TriggerServerEvent('prfrp:ops:action',action) end
end
for name in pairs(Config.ChatCommands) do
  local command=name
  RegisterCommand(command,function() execute(command) end,false)
end
RegisterNetEvent('prfrp:chatCommand',execute)
local suggestions={
  {name='/servico',help='Entrar ou sair de servico'},
  {name='/viatura',help='Pegar a viatura PRF'},
  {name='/abordar',help='Abordar a pessoa ou o carro a frente'},
  {name='/documento',help='Documento e antecedentes ficticios da pessoa abordada'},
  {name='/revistar',help='Revistar a pessoa ou o carro abordado'},
  {name='/liberar',help='Encerrar a abordagem'},
  {name='/reforco',help='Chamar apoio policial'},
  {name='/guincho',help='Solicitar guincho para o carro abordado'},
  {name='/blitz',help='Colocar ou recolher cones'},
  {name='/ronda',help='Iniciar uma missao de patrulha'},
  {name='/ajuda',help='Ver os comandos PRF no chat'}
}
CreateThread(function() Wait(1000); TriggerEvent('chat:addSuggestions',suggestions) end)
AddEventHandler('onClientResourceStart',function(name)
  if name=='chat' then TriggerEvent('chat:addSuggestions',suggestions) end
end)
AddEventHandler('onResourceStop',function(name)
  if name~=GetCurrentResourceName() then return end
  for _,item in ipairs(suggestions) do TriggerEvent('chat:removeSuggestion',item.name) end
end)
