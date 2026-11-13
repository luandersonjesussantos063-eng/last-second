-- O servidor autoriza cada apreensao; o dono do NPC le as armas reais no jogo.
local pending,finished={}, {}
local sequence=0
local function notice(src,text) TriggerClientEvent('prfrp:operationsNotify',src,text) end
local function valid(job)
  if not job or not PrfHasDuty(job.officer) or os.time()>job.expires then return false end
  local current=PrfInspectionPerson and PrfInspectionPerson(job.officer)
  local ped=NetworkGetEntityFromNetworkId(job.id)
  if not current or current.entity~=job.entity or ped~=job.entity or not DoesEntityExist(ped)
    or GetEntityModel(ped)~=job.model or NetworkGetEntityOwner(ped)~=job.owner then return false end
  for _,id in ipairs(GetPlayers()) do if GetPlayerPed(tonumber(id))==ped then return false end end
  local p,q=GetEntityCoords(GetPlayerPed(job.officer)),GetEntityCoords(ped)
  return (p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2<=3.5^2
end
local function report(job,text)
  TriggerClientEvent('prfrp:person:report',job.officer,job.id,'search',{'REVISTA PESSOAL',text})
end
PrfCancelInspection=function(src)
  local job=pending[src]
  if not job then return end
  if job.phase=='remove' then TriggerClientEvent('prfrp:inventory:restore',job.owner,job.id,job.token,job.weapons) end
  pending[src]=nil
end
PrfInspectPerson=function(src,stop)
  if pending[src] and os.time()<=pending[src].expires then notice(src,'Aguarde a revista em andamento.');return end
  PrfCancelInspection(src)
  sequence=sequence+1
  local job={officer=src,id=stop.id,entity=stop.entity,model=stop.model,owner=NetworkGetEntityOwner(stop.entity),
    token=sequence,phase='inspect',expires=os.time()+12}
  if not valid(job) then notice(src,'Aproxime-se do NPC para revistar.');return end
  pending[src]=job
  TriggerClientEvent('prfrp:inventory:inspect',job.owner,job.id,job.token)
end
local function find(owner,id,token)
  for _,job in pairs(pending) do if job.owner==owner and job.id==id and job.token==token then return job end end
end
local function normalize(job,items)
  if type(items)~='table' or #items>128 then return end
  local result,seen={},{}
  for _,item in ipairs(items) do
    local name=type(item)=='table' and item.name
    local ammo=type(item)=='table' and item.ammo
    if type(name)~='string' or not Config.SearchWeapons[name] or seen[name]
      or type(ammo)~='number' or ammo~=ammo or ammo<0 or ammo>3000 or ammo%1~=0 then return end
    seen[name]=true
    result[#result+1]={name=name,ammo=ammo}
  end
  return result
end
RegisterNetEvent('prfrp:inventory:inspection',function(id,token,items)
  local job=find(source,id,token)
  if not job or job.phase~='inspect' then return end
  if not valid(job) then PrfCancelInspection(job.officer);return end
  local weapons=normalize(job,items)
  if not weapons then PrfCancelInspection(job.officer);return end
  if #weapons==0 then pending[job.officer]=nil;report(job,'Nenhuma arma apreensivel encontrada.');return end
  job.weapons,job.phase,job.expires=weapons,'remove',os.time()+12
  TriggerClientEvent('prfrp:inventory:seize',job.owner,id,token,weapons)
end)
RegisterNetEvent('prfrp:inventory:removed',function(id,token,items)
  if finished[token] then return end
  local job=find(source,id,token)
  if not job or job.phase~='remove' then return end
  if not valid(job) then PrfCancelInspection(job.officer);return end
  local actual=normalize(job,items)
  if not actual then PrfCancelInspection(job.officer);return end
  local allowed={}
  for _,item in ipairs(job.weapons) do allowed[item.name]=item.ammo end
  for _,item in ipairs(actual) do
    if allowed[item.name]==nil or item.ammo>allowed[item.name] then PrfCancelInspection(job.officer);return end
  end
  if #actual==0 then pending[job.officer]=nil;report(job,'A arma nao estava mais com o NPC.');return end
  local ok,err=PrfMutateProfile(job.officer,function(profile)
    local ammunition={}
    for _,item in ipairs(actual) do
      profile.inventory[item.name]=(profile.inventory[item.name] or 0)+1
      local kind=Config.SearchWeapons[item.name].ammo
      if kind then ammunition[kind]=math.max(ammunition[kind] or 0,item.ammo) end
    end
    for kind,count in pairs(ammunition) do profile.inventory[kind]=(profile.inventory[kind] or 0)+count end
    profile.stats.seizures=profile.stats.seizures+#actual
  end)
  if not ok then PrfCancelInspection(job.officer);notice(job.officer,err);return end
  local labels={}
  for _,item in ipairs(actual) do labels[#labels+1]=Config.SearchWeapons[item.name].label end
  pending[job.officer]=nil;finished[token]=os.time()+60
  TriggerClientEvent('prfrp:inventory:finished',job.owner,token)
  report(job,'APREENDIDO E SALVO NO INVENTARIO: '..table.concat(labels,', '))
end)
AddEventHandler('playerDropped',function() PrfCancelInspection(source) end)
CreateThread(function()
  while true do
    Wait(3000)
    for src,job in pairs(pending) do if os.time()>job.expires then PrfCancelInspection(src) end end
    for token,expires in pairs(finished) do if os.time()>expires then finished[token]=nil end end
  end
end)
