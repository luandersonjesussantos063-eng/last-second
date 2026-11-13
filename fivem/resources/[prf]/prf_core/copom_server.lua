-- Objetivos so avancam por acoes verificadas dos outros modulos ou estado das entidades.
local calls,serial={},0
local kinds={vehicle=2,ped=1,object=3}
local function notice(src,text) TriggerClientEvent('prfrp:operationsNotify',src,'COPOM: '..text) end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<20000 end
local function distance(a,b) return (a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2 end
local function near(src,point,radius)
  local ped=GetPlayerPed(src)
  return ped~=0 and DoesEntityExist(ped) and distance(GetEntityCoords(ped),point)<=radius^2
end
local function entity(call,key)
  local a=call.actors and call.actors[key]
  if not a then return end
  local e=NetworkGetEntityFromNetworkId(a.id)
  if e~=a.entity or not DoesEntityExist(e) or GetEntityModel(e)~=GetHashKey(a.def.model) then return end
  return e
end
local function actor(call,e)
  for key,a in pairs(call.actors or {}) do if a.entity==e and entity(call,key)==e then return key,a end end
end
local function pointAt(anchor,offset)
  local h=math.rad(anchor.heading)
  return {x=anchor.x+math.cos(h)*offset.x-math.sin(h)*offset.y,y=anchor.y+math.sin(h)*offset.x+math.cos(h)*offset.y,z=anchor.z}
end
local function current(src,session)
  local c=calls[src]
  return PrfHasDuty(src) and c and c.session==session and c or nil
end
local function update(src,c)
  local list={}
  for _,g in ipairs(c.definition.objectives) do list[#list+1]={key=g.key,kind=g.kind,actor=g.actor,label=g.label,done=c.done[g.key]==true} end
  TriggerClientEvent('prfrp:copom:progress',src,c.session,list)
end
local function clear(src,reason)
  local c=calls[src]
  calls[src]=nil
  if c then
    if PrfCancelCopomServices then PrfCancelCopomServices(src,c.session) end
    for key,a in pairs(c.actors or {}) do
      local e=entity(c,key)
      if e then
        if PrfCopomReleaseTraffic then PrfCopomReleaseTraffic(src,e) end
        if not (PrfIsArrestedEntity and PrfIsArrestedEntity(e)) then DeleteEntity(e) end
      end
    end
  end
  TriggerClientEvent('prfrp:copom:call',src,false)
  if reason then notice(src,reason) end
end
PrfCancelCopom=function(src,quiet)
  if not calls[src] then if not quiet then notice(src,'Nenhum chamado ativo.') end;return end
  clear(src,not quiet and 'Atendimento cancelado. Nenhuma conclusao foi contabilizada.' or nil)
end
local function draw(bag,count,last)
  if #bag==0 then
    for i=1,count do bag[i]=i end
    for i=count,2,-1 do local j=math.random(i);bag[i],bag[j]=bag[j],bag[i] end
    if count>1 and bag[#bag]==last then bag[1],bag[#bag]=bag[#bag],bag[1] end
  end
  return table.remove(bag)
end
PrfAssignCopom=function(src)
  if not PrfHasDuty(src) then return end
  if calls[src] then notice(src,'Ha um chamado ativo. Digite copom para ver as pendencias, ou cancelar.');return end
  local ok,choice=PrfMutateProfile(src,function(p)
    p.copom=p.copom or {remaining={},locations={}}
    local b=p.copom
    -- Listas antigas de configuracoes editadas sao reconstruidas sem apagar estatisticas.
    for _,pair in ipairs({{b.remaining,#Config.Copom.templates},{b.locations,#Config.Copom.locations}}) do
      for i=#pair[1],1,-1 do if pair[1][i]>pair[2] then table.remove(pair[1],i) end end
    end
    local template=draw(b.remaining,#Config.Copom.templates,b.lastTemplate)
    local location=draw(b.locations,#Config.Copom.locations,b.lastLocation)
    b.lastTemplate,b.lastLocation=template,location
    return {template=template,location=location,variant=math.random(2)}
  end)
  if not ok then notice(src,choice);return end
  serial=serial+1
  local definition=PrfBuildCopom(Config.Copom.templates[choice.template],choice.variant)
  local location=Config.Copom.locations[choice.location]
  calls[src]={session=serial,definition=definition,location=location,done={},evidence={},started=os.time()}
  TriggerClientEvent('prfrp:copom:call',src,{session=serial,definition=definition,location=location})
  notice(src,definition.code..' | '..definition.name..' | '..location.name..'. '..definition.details)
end
local function goalByKey(c,key) for _,g in ipairs(c.definition.objectives) do if g.key==key then return g end end end
local function needs(c,g)
  for _,key in ipairs(g.needs or {}) do if not c.done[key] then return false end end
  return true
end
local function evidence(c,kind,key) return c.evidence[kind..':'..(key or '')]==true end
local function satisfied(src,c,g)
  local e=g.actor and entity(c,g.actor)
  if g.kind=='secure' then return PrfCountBlitzCones and PrfCountBlitzCones(src,c.anchor,30)>=2
  elseif g.kind=='stop' then return e and evidence(c,'stop',g.actor) and GetEntitySpeed(e)<1.0
  elseif g.kind=='contain' then return evidence(c,'arrest',g.actor) or (e and GetEntityHealth(e)<=0)
  elseif g.kind=='arrest' then return evidence(c,'arrest',g.actor)
  elseif g.kind=='escort' then
    return e and evidence(c,'follow',g.actor) and distance(GetEntityCoords(e),pointAt(c.anchor,c.definition.safe))<5^2 and near(src,GetEntityCoords(e),10)
  elseif g.kind=='ambulance' then return e and evidence(c,'ambulance',g.actor) and GetEntityHealth(e)>=180
  elseif g.kind=='backup' then return evidence(c,'backup')
  else return evidence(c,g.kind,g.actor) end
end
local function refresh(src,c)
  if not c.actors then return end
  local changed=false
  for _,g in ipairs(c.definition.objectives) do
    if not c.done[g.key] and needs(c,g) and satisfied(src,c,g) then c.done[g.key]=true;changed=true end
  end
  if changed then update(src,c) end
  for _,g in ipairs(c.definition.objectives) do if not c.done[g.key] then return end end
  -- Nao e necessario retornar ao ponto inicial depois de uma perseguicao ou escolta.
  local saved,total=PrfProgressStat(src,'calls',1)
  if not saved then
    if not c.saveNotice or os.time()-c.saveNotice>10 then notice(src,total);c.saveNotice=os.time() end
    return
  end
  clear(src,c.definition.name..' resolvida. Total salvo: '..total..'. Solicite chamado quando estiver pronto.')
end
PrfCopomEvidence=function(src,kind,e)
  local c=calls[src]
  if not c or not c.actors or not PrfHasDuty(src) then return end
  local key,a=actor(c,e)
  if kind=='backup' then
    if e and DoesEntityExist(e) and distance(GetEntityCoords(e),c.anchor)<100^2 and near(src,c.anchor,100) then c.evidence['backup:']=true end
  elseif key then
    c.evidence[kind..':'..key]=true
    -- Documento/bafometro do motorista valem para o carro identificado na ocorrencia.
    if a.def.driver then c.evidence[kind..':'..a.def.driver]=true end
  end
  refresh(src,c)
end
PrfCopomStopBehavior=function(src,e)
  local c=calls[src];if not c then return end
  local _,a=actor(c,e)
  if a and a.def.suspect then return {flee=a.def.flee==true} end
end
PrfCopomDocument=function(src,e)
  local c=calls[src];if not c then return end
  local key=actor(c,e)
  if key and (c.definition.key=='dui' or c.definition.key=='stolen') then
    return c.definition.wanted and 'ALERTA FICTICIO: veiculo com registro de furto; confirme o condutor e preserve o veiculo.' or 'Denuncia de direcao perigosa. Realize o bafometro antes de concluir a abordagem.'
  end
end
PrfCopomAlcohol=function(src,e)
  local c=calls[src]
  if c and actor(c,e) and c.definition.alcohol then return c.definition.alcohol end
end
PrfCopomServiceTarget=function(src,kind,target)
  local c=calls[src]
  if not c or not c.actors then return end
  for _,g in ipairs(c.definition.objectives) do
    local e=g.actor and entity(c,g.actor)
    if g.kind==kind and not c.done[g.key] and e and (not target or target==e) then
      if kind=='tow' then
        for _,other in ipairs(c.definition.objectives) do
          if other.kind~='tow' and not c.done[other.key] then return nil,'Conclua o socorro e a fiscalizacao antes de remover o veiculo.' end
        end
      end
      return e,c.session
    end
  end
end
PrfIsCopomEntity=function(src,e) local c=calls[src];return c and actor(c,e)~=nil or false end
RegisterNetEvent('prfrp:copom:register',function(session,anchor,ids)
  local src=source;local c=current(src,session)
  if not c or type(anchor)~='table' or type(ids)~='table' then return end
  if c.actors then TriggerClientEvent('prfrp:copom:registered',src,session);return end
  if not finite(anchor.x) or not finite(anchor.y) or not finite(anchor.z) or not finite(anchor.heading)
    or distance(anchor,c.location)>160^2 or not near(src,anchor,200) then return end
  local count=0;for _ in pairs(ids) do count=count+1 end
  if count~=#c.definition.actors then return end
  local registered,seen={},{}
  for _,def in ipairs(c.definition.actors) do
    local id=ids[def.key]
    if type(id)~='number' or id<=0 or id%1~=0 or seen[id] then return end
    seen[id]=true
    local e=NetworkGetEntityFromNetworkId(id)
    if e==0 or not DoesEntityExist(e) or GetEntityType(e)~=kinds[def.kind]
      or GetEntityModel(e)~=GetHashKey(def.model) or NetworkGetEntityOwner(e)~=src
      or distance(GetEntityCoords(e),pointAt(anchor,def))>9^2 then return end
    registered[def.key]={id=id,entity=e,def=def}
  end
  c.actors,c.anchor=registered,anchor
  TriggerClientEvent('prfrp:copom:registered',src,session)
  update(src,c)
end)
RegisterNetEvent('prfrp:copom:workStart',function(session,key)
  local src=source;local c=current(src,session)
  if not c or not c.actors or c.work or type(key)~='string' then return end
  local g=goalByKey(c,key)
  if not g or c.done[key] or not needs(c,g) or not ({talk=true,clear=true,cargo=true,load=true})[g.kind] then return end
  local e=entity(c,g.actor)
  if not e or GetEntityHealth(e)<=0 or not near(src,GetEntityCoords(e),g.kind=='load' and 6 or 3.5)
    or GetVehiclePedIsIn(GetPlayerPed(src),false)~=0 then return end
  if c.workAt and os.time()-c.workAt<1 then return end
  c.workAt=os.time();c.work={key=key,started=os.time(),entity=e,expires=os.time()+(g.seconds or 4)+10}
  TriggerClientEvent('prfrp:copom:workBegin',src,session,key,g.seconds or 4,g.kind)
end)
RegisterNetEvent('prfrp:copom:workCancel',function(session,key)
  local c=current(source,session);if c and c.work and c.work.key==key then c.work=nil end
end)
RegisterNetEvent('prfrp:copom:workFinish',function(session,key)
  local src=source;local c=current(src,session)
  if not c or not c.work or c.work.key~=key then return end
  local g=goalByKey(c,key);local e=entity(c,g.actor);local work=c.work
  if os.time()-work.started<(g.seconds or 4) then return end
  c.work=nil
  if os.time()>work.expires or not e or e~=work.entity or not near(src,GetEntityCoords(e),g.kind=='load' and 6 or 3.5)
    or GetVehiclePedIsIn(GetPlayerPed(src),false)~=0 or GetEntityHealth(GetPlayerPed(src))<=0 then return end
  if g.kind=='clear' then DeleteEntity(e)
  elseif g.kind=='talk' then notice(src,g.dialogue)
  elseif g.kind=='load' then
    for _,a in pairs(c.actors) do
      if a.def.kind=='object' and DoesEntityExist(a.entity) then DeleteEntity(a.entity) end
    end
    TriggerClientEvent('prfrp:copom:closeLoad',NetworkGetEntityOwner(e),NetworkGetNetworkIdFromEntity(e))
  end
  c.evidence[g.kind..':'..g.actor]=true
  refresh(src,c)
end)
RegisterNetEvent('prfrp:copom:status',function(finish)
  local src=source;local c=calls[src]
  if not c or not PrfHasDuty(src) then notice(src,'Nenhum chamado ativo. Digite chamado.');return end
  refresh(src,c)
  if calls[src]~=c then return end
  notice(src,c.definition.name..' | '..c.location.name)
  for _,g in ipairs(c.definition.objectives) do notice(src,(c.done[g.key] and '[OK] ' or '[PENDENTE] ')..g.label) end
  if finish then notice(src,'A conclusao exige resolver as pendencias. Chegar ao local ou apertar E nao finaliza o chamado.') end
end)
RegisterNetEvent('prfrp:copom:spawnFailed',function(session)
  if current(source,session) then clear(source,'Nao foi possivel montar a cena com piso seguro. Solicite outro chamado.') end
end)
AddEventHandler('prfrp:ops:dutyEnded',function(src) clear(src) end)
AddEventHandler('playerDropped',function() clear(source) end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then for src in pairs(calls) do clear(src) end end end)
CreateThread(function()
  while true do
    Wait(2000)
    for src,c in pairs(calls) do
      if not PrfHasDuty(src) or os.time()-c.started>2700 then clear(src,'Atendimento encerrado por tempo ou fim do turno.')
      elseif c.actors then
        if c.work and os.time()>c.work.expires then c.work=nil end
        local failed
        for key,a in pairs(c.actors) do
          local e=entity(c,key)
          if not e and not (evidence(c,'clear',key) or evidence(c,'cargo',key) or evidence(c,'tow',key) or evidence(c,'arrest',key)) then
            failed='Um envolvido ou veiculo deixou de estar disponivel. Atendimento encerrado sem pontuar.'
          elseif e and a.def.kind=='ped' and not a.def.hostile and GetEntityHealth(e)<=0 then
            failed='Houve uma morte entre os envolvidos que precisavam de atendimento ou custodia. Atendimento encerrado sem pontuar.'
          end
        end
        if failed then clear(src,failed) else refresh(src,c) end
      end
    end
  end
end)
