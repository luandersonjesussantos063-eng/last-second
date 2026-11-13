-- Operacoes pelo T; consultas abrem o tablet e fecham com Esc.
local function notice(message)
  TriggerEvent('chat:addMessage',{color={245,210,65},args={'PRF',tostring(message)}})
end
AddEventHandler('prfrp:chatNotice',notice)
local function help()
  notice('T > servico | viatura | farda | fuzil | giroflex | sirene | equipe')
  notice('Aponte a arma para abordar uma pessoa. T > documento | antecedentes | revistar | liberar')
  notice('T > abordar (pessoa/carro) | guincho | reforco | blitz | ronda | cancelarronda | base | favela')
  notice('Ordens: desce do carro | mao na cabeca | maos pra cima | deita no chao | ajoelhar | levantar')
  notice('Custodia: algemar | desalgemar | seguir | parar | entrar no carro | liberar | bafometro')
  notice('Prisao de NPC: prender > entrar no carro > base > registrarprisao. prisoes mostra o historico salvo.')
  notice('Reforco: reforco 3 acrescenta tres viaturas iguais a sua. dispensar reforco cancela o apoio. Z: segure para mirar.')
  notice('Transito: liberarcarro solta o carro selecionado; liberar encerra a abordagem. cancelarperseguicao encerra uma fuga.')
  notice('Cones: cone > Z ou botao direito + clique no chao. guardarcone | recolhercones. Equipe trabalha junto aos cones.')
  notice('Tablet e progresso: tablet | inventario | progresso | salvar. Chamadas: ambulancia | mecanico | bombeiros | guincho | reforco.')
  notice('Ocorrencias: ronda | guerradefaccao. Conducao: aborde e digite seguir; parar encerra o acompanhamento.')
  notice('Digite a palavra e Enter. Tambem aceita /viatura, /revistar etc. Dados e antecedentes sao ficticios.')
end
AddEventHandler('prfrp:chatHelp',help)
local function execute(name,args)
  local action=Config.ChatCommands[name]
  if not action then return end
  if action=='help' then help()
  elseif action=='inventory' or action=='progress' then TriggerServerEvent('prfrp:progress:request',action)
  elseif action=='saveProgress' then TriggerServerEvent('prfrp:progress:request','save')
  elseif action=='tablet' or action=='services' then TriggerEvent('prfrp:tablet:open',action=='services' and 'services' or 'documents')
  elseif Config.Services[action] then TriggerEvent('prfrp:services:request',action)
  elseif action=='baseDoor' then TriggerEvent('prfrp:baseDoor')
  elseif action=='cone' then TriggerEvent('prfrp:blitz:toggle')
  elseif action=='cancelCone' then TriggerEvent('prfrp:blitz:cancel')
  elseif action=='clearCones' then TriggerEvent('prfrp:blitz:recollect')
  elseif action=='bookArrest' then TriggerServerEvent('prfrp:person:bookArrest')
  elseif action=='arrestHistory' then TriggerServerEvent('prfrp:person:arrestHistory')
  elseif action=='backup' then
    local count=args and args[1] and tonumber(args[1]) or 1
    if (args and args[1] and not args[1]:match('^%d+$')) or not count or count<1 or count%1~=0 or count>2147483647 then
      notice('Use reforco ou reforco 3. Digite uma quantidade inteira positiva.');return
    end
    TriggerEvent('prfrp:backup:request',count)
  elseif Config.PersonOrders[action] then TriggerEvent('prfrp:person:orderCommand',action)
  elseif action=='approach' then TriggerEvent('prfrp:person:approachCommand')
  elseif action=='lights' then TriggerEvent('prfrp:toggleEmergencyLights')
  elseif action=='siren' then TriggerEvent('prfrp:toggleSirenSound')
  elseif action=='team' then TriggerEvent('prfrp:squadRally')
  elseif action=='cancelPursuit' then TriggerEvent('prfrp:traffic:cancelPursuit')
  elseif action=='blitz' or action=='release' or action=='releaseVehicle' then TriggerEvent('prfrp:ops:command',action)
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
  RegisterCommand(command,function(_,args)
    local parsed,values=PrfParseChat(command..((args and #args>0) and ' '..table.concat(args,' ') or ''))
    if not parsed then notice('Comando invalido. Digite ajuda no T.');return end
    execute(parsed,values)
  end,false)
end
RegisterNetEvent('prfrp:chatCommand',execute)
local suggestions={
  {name='/servico',help='Entrar ou sair de servico'},
  {name='/viatura',help='Pegar a viatura PRF'},
  {name='/abordar',help='Abordar a pessoa ou o carro a frente'},
  {name='/documento',help='Documento e antecedentes ficticios da pessoa abordada'},
  {name='/revistar',help='Revistar a pessoa ou o carro abordado'},
  {name='/liberar',help='Encerrar a abordagem'},
  {name='/liberarcarro',help='Liberar somente o carro selecionado'},
  {name='/cancelarperseguicao',help='Encerrar a perseguicao atual'},
  {name='/reforco',help='Acrescentar viaturas iguais a sua',params={{name='quantidade',help='Opcional: reforco 3'}}},
  {name='/dispensarreforco',help='Dispensar unidades de apoio e cancelar a fila'},
  {name='/descer',help='Mandar os ocupantes do carro abordado desembarcarem'},
  {name='/maonacabeca',help='Mandar a pessoa abordada colocar as maos na cabeca'},
  {name='/maos',help='Mandar levantar as maos'},
  {name='/deitar',help='Mandar deitar no chao'},
  {name='/ajoelhar',help='Mandar ajoelhar'},
  {name='/levantar',help='Mandar levantar'},
  {name='/algemar',help='Algemar a pessoa abordada'},
  {name='/prender',help='Prender o NPC abordado e marcar a entrega na base'},
  {name='/registrarprisao',help='Entregar o preso na base e registrar a prisao'},
  {name='/prisoes',help='Consultar as suas ultimas prisoes salvas'},
  {name='/desalgemar',help='Retirar as algemas'},
  {name='/seguir',help='Conduzir a pessoa abordada a pe'},
  {name='/parar',help='Mandar a pessoa permanecer no local'},
  {name='/entrar',help='Colocar a pessoa em um assento livre da sua viatura'},
  {name='/bafometro',help='Teste simulado na abordagem atual'},
  {name='/guincho',help='Solicitar guincho para o carro abordado'},
  {name='/blitz',help='Equipar cones; mire no chao e clique para colocar'},
  {name='/recolhercones',help='Recolher os cones e liberar a equipe'},
  {name='/inventario',help='Ver armas e municao apreendidas e salvas'},
  {name='/progresso',help='Ver ocorrencias e prisoes salvas'},
  {name='/salvar',help='Salvar seu progresso agora'},
  {name='/ambulancia',help='Solicitar socorro medico'},
  {name='/mecanico',help='Solicitar reparo da viatura'},
  {name='/bombeiros',help='Solicitar combate a incendio na viatura'},
  {name='/servicos',help='Abrir chamadas no tablet'},
  {name='/porta',help='Abrir ou fechar a porta da base'},
  {name='/guerradefaccao',help='Atender uma ocorrencia de guerra de faccao'},
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
