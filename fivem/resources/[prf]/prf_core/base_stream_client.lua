-- Nascer no acostamento, com solo verificado, evita aceitar o terreno sob o MLO.
local door,doorHash,doorOpen=0,GetHashKey('prf_base_front_door'),false
local function insideBuilding(p)
  return p.x>-3036 and p.x<-3018 and p.y>360 and p.y<387
end
PrfFindSafeBaseSpawn=function(custom)
  local base=custom and Config.CustomBase or Config.Base
  local seeds={{0,0},{-25,0},{25,0},{0,-25},{0,25},{-40,-20},{40,20}}
  for _,offset in ipairs(seeds) do
    local found,node,heading=GetClosestVehicleNodeWithHeading(base.x+offset[1],base.y+offset[2],base.z,1,3.0,0)
    if found and node and (node.x-base.x)^2+(node.y-base.y)^2<110^2 then
      local angle=math.rad(heading)
      for _,side in ipairs({4.0,-4.0,0.0}) do
        local x,y=node.x+math.cos(angle)*side,node.y+math.sin(angle)*side
        local candidate={x=x,y=y,z=node.z}
        if (not custom or not insideBuilding(candidate)) and not IsAnyVehicleNearPoint(x,y,node.z,2.5) then
          RequestCollisionAtCoord(x,y,node.z)
          local ok,z=GetGroundZFor_3dCoord(x,y,node.z+4.0,false)
          if ok and math.abs(z-node.z)<2.0 then
            local ray=StartShapeTestRay(x,y,node.z+4,x,y,node.z-4,17,PlayerPedId(),7)
            local status,hit,at,normal=GetShapeTestResult(ray)
            local started=GetGameTimer()
            while status==1 and GetGameTimer()-started<350 do
              Wait(0);status,hit,at,normal=GetShapeTestResult(ray)
            end
            if status==2 and hit and at and normal and normal.z>0.65 and math.abs(at.z-node.z)<2.0 then
              return {x=x,y=y,z=at.z+1.0,heading=heading}
            end
          end
        end
      end
    end
  end
end
local function removeDoor()
  if door~=0 and DoesEntityExist(door) then DeleteObject(door) end
  RemoveDoorFromSystem(doorHash);door=0
end
local function createDoor()
  local hash=GetHashKey('v_ilev_shrfdoor')
  RequestModel(hash)
  local started=GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer()-started<5000 do Wait(0) end
  if not HasModelLoaded(hash) then return end
  local lo,hi=GetModelDimensions(hash)
  local heading=(hi.x-lo.x>=hi.y-lo.y) and 171.0 or 81.0
  local angle=math.rad(heading)
  local cx,cy=(lo.x+hi.x)/2,(lo.y+hi.y)/2
  local x=-3030.729-math.cos(angle)*cx+math.sin(angle)*cy
  local y=364.466-math.sin(angle)*cx-math.cos(angle)*cy
  local z=14.893536-lo.z
  door=CreateObjectNoOffset(hash,x,y,z,false,false,false)
  SetModelAsNoLongerNeeded(hash)
  if door==0 then return end
  SetEntityHeading(door,heading);SetEntityCollision(door,true,true)
  AddDoorToSystem(doorHash,hash,x,y,z,false,false,false)
  DoorSystemSetDoorState(doorHash,0,false,true)
  DoorSystemSetAutomaticDistance(doorHash,1.8,false,false)
end
AddEventHandler('prfrp:baseDoor',function()
  local p=GetEntityCoords(PlayerPedId())
  if door==0 or (p.x+3030.729)^2+(p.y-364.466)^2>5^2 then
    TriggerEvent('prfrp:chatNotice','Aproxime-se da entrada da base.');return
  end
  doorOpen=not doorOpen
  DoorSystemSetDoorState(doorHash,0,false,true)
  DoorSystemSetOpenRatio(doorHash,doorOpen and 1.0 or 0.0,true,true)
end)
CreateThread(function()
  while true do
    local p=GetEntityCoords(PlayerPedId())
    local started=GetResourceState(Config.CustomBaseResource)=='started'
    if started and (p.x-Config.CustomBase.x)^2+(p.y-Config.CustomBase.y)^2<160^2 then
      if door==0 then createDoor() end
      local interior=GetInteriorAtCoords(-3025.5,373.86,16.4)
      if interior~=0 then PinInteriorInMemory(interior);RefreshInterior(interior) end
      if insideBuilding(p) and p.z<14.45 and not IsPedInAnyVehicle(PlayerPedId(),false) then
        TriggerEvent('prfrp:requestSafeBaseSpawn')
      end
    elseif not started and door~=0 then removeDoor() end
    Wait(2000)
  end
end)
AddEventHandler('onResourceStop',function(name) if name==GetCurrentResourceName() then removeDoor() end end)
