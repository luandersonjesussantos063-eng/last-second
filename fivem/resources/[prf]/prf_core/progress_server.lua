-- O KVP do FXServer fica fora de resources; atualizar o core nao apaga perfis.
local cache,keys={},{}
local function key(src)
  local id=GetPlayerIdentifierByType(src,'license') or GetPlayerIdentifierByType(src,'license2') or GetPlayerIdentifierByType(src,'fivem')
  return id and 'prfrp:profile:v1:'..id or nil
end
local function empty()
  return {version=1,stats={calls=0,missions=0,arrests=0,seizures=0},inventory={},arrests={}}
end
local function valid(value)
  if type(value)~='table' or value.version~=1 or type(value.stats)~='table'
    or type(value.inventory)~='table' or type(value.arrests)~='table' then return false end
  for _,name in ipairs({'calls','missions','arrests','seizures'}) do
    local n=value.stats[name]
    if type(n)~='number' or n~=n or n<0 or n%1~=0 then return false end
  end
  for name,count in pairs(value.inventory) do
    if not (Config.SearchWeapons[name] or Config.AmmoLabels[name]) or type(count)~='number'
      or count~=count or count<0 or count%1~=0 then return false end
  end
  if #value.arrests>200 then return false end
  for _,entry in ipairs(value.arrests) do
    if type(entry)~='table' or type(entry.name)~='string' or #entry.name>256
      or type(entry.document)~='string' or #entry.document>128 then return false end
    for _,field in ipairs({'number','officer','time'}) do
      local n=entry[field]
      if type(n)~='number' or n~=n or n<0 or n%1~=0 then return false end
    end
  end
  return true
end
local function decode(raw)
  if not raw then return end
  local ok,value=pcall(json.decode,raw)
  if ok and valid(value) then return value end
end
PrfLoadProfile=function(src)
  if cache[src] then return cache[src] end
  local profileKey=key(src)
  if not profileKey then return nil,'Identificador de progresso indisponivel.' end
  local raw=GetResourceKvpString(profileKey)
  local backup=GetResourceKvpString(profileKey..':backup')
  local value=decode(raw) or decode(backup)
  if (raw or backup) and not value then return nil,'Progresso nao pode ser lido. O arquivo existente foi preservado.' end
  value=value or empty()
  cache[src],keys[src]=value,profileKey
  return value
end
local function view(profile)
  local items={}
  for name,count in pairs(profile.inventory) do
    if count>0 then items[#items+1]={name=name,label=Config.SearchWeapons[name] and Config.SearchWeapons[name].label or Config.AmmoLabels[name],count=count} end
  end
  table.sort(items,function(a,b)return a.label<b.label end)
  return {stats=profile.stats,items=items,arrests=profile.arrests}
end
PrfProfileView=function(src)
  local profile,err=PrfLoadProfile(src)
  if not profile then return nil,err end
  return view(profile)
end
PrfMutateProfile=function(src,mutate)
  local old,err=PrfLoadProfile(src)
  if not old then return false,err end
  local nextValue=json.decode(json.encode(old))
  local ok,result=pcall(mutate,nextValue)
  if not ok or not valid(nextValue) then return false,'Alteracao de progresso invalida.' end
  local encoded=json.encode(nextValue)
  local saved=pcall(function()
    SetResourceKvp(keys[src]..':backup',json.encode(old))
    SetResourceKvp(keys[src],encoded)
    assert(GetResourceKvpString(keys[src])==encoded)
  end)
  if not saved then return false,'Nao foi possivel salvar. Tente novamente.' end
  cache[src]=nextValue
  TriggerClientEvent('prfrp:progress:updated',src,view(nextValue))
  return true,result
end
PrfProgressStat=function(src,name,amount)
  return PrfMutateProfile(src,function(profile)
    assert(profile.stats[name]~=nil)
    profile.stats[name]=profile.stats[name]+amount
    return profile.stats[name]
  end)
end
PrfStoreArrest=function(src,entry)
  return PrfMutateProfile(src,function(profile)
    profile.stats.arrests=profile.stats.arrests+1
    entry.number=profile.stats.arrests
    profile.arrests[#profile.arrests+1]=entry
    while #profile.arrests>200 do table.remove(profile.arrests,1) end
    return entry
  end)
end
RegisterNetEvent('prfrp:progress:request',function(kind)
  local src=source
  if not PrfHasDuty or not PrfHasDuty(src) then return end
  local profile,err=PrfProfileView(src)
  if not profile then TriggerClientEvent('prfrp:notify',src,err);return end
  if kind=='save' then
    local ok,message=PrfMutateProfile(src,function() end)
    TriggerClientEvent('prfrp:notify',src,ok and 'Progresso salvo no servidor.' or message)
  else TriggerClientEvent('prfrp:tablet:profile',src,profile,kind) end
end)
AddEventHandler('playerDropped',function() cache[source],keys[source]=nil,nil end)
