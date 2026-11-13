-- Host adapters: JSON snapshots and a durable KVP store, shared across resource reloads.
local M={}
function M.storage()
  local data,snapshots,serial={}, {},0
  local function copy(value)
    if type(value)~='table' then return value end
    local out={};for k,v in pairs(value) do out[k]=copy(v) end;return out
  end
  local json={encode=function(value) serial=serial+1;local key='json:'..serial;snapshots[key]=copy(value);return key end,
    decode=function(key) assert(snapshots[key],'corrupt JSON');return copy(snapshots[key]) end}
  return {data=data,json=json}
end
function M.progress(env,storage)
  storage=storage or M.storage()
  env.json=storage.json
  env.GetPlayerIdentifierByType=function(src,kind) return kind=='license' and 'test-license-'..src or nil end
  env.GetResourceKvpString=function(key) return storage.data[key] end
  env.SetResourceKvp=function(key,value) if storage.fail then error('disk full') end;storage.data[key]=value end
  assert(loadfile('fivem/resources/[prf]/prf_core/progress_server.lua','t',env))()
  return storage
end
return M
