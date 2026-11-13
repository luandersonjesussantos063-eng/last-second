Config.Operations = {
  encounterChance = 35, -- porcentagem por ronda; confronto somente em missao aceita
  nonComplianceChance = 15, -- porcentagem de motoristas NPC que fogem da parada
  missions = {
    { name = 'Ronda na Favela Realista', resource = 'prf_favela_realista',
      points = {
        { x = 1180.15991, y = -125.015266, z = 61.4836 },
        { x = 1191.339, y = -168.3792, z = 58.655865 },
        { x = 1213.55408, y = -67.8079, z = 73.05714 }
      } },
    { name = 'Ronda preventiva em Davis',
      points = {
        { x = 115.0, y = -1940.0, z = 20.6 },
        { x = 82.0, y = -1810.0, z = 27.1 },
        { x = -45.0, y = -1750.0, z = 29.4 }
      } },
    { name = 'Ronda em Rancho',
      points = {
        { x = 470.0, y = -1850.0, z = 27.7 },
        { x = 405.0, y = -1725.0, z = 29.3 },
        { x = 250.0, y = -1720.0, z = 29.3 }
      } },
    { name = 'Apoio a equipe sob ataque em Davis', encounter = true,
      points = { { x = 115.0, y = -1940.0, z = 20.6 } } }
  }
}
-- Confrontos entre faccoes ficticias do universo GTA.
for _,incident in ipairs({
  {name='Guerra de faccao: Ballas x Families em Davis',x=115.0,y=-1940.0,z=20.6},
  {name='Guerra de faccao: disputa em Rancho',x=470.0,y=-1850.0,z=27.7},
  {name='Guerra de faccao na Favela Realista',x=1180.15991,y=-125.015266,z=61.4836,resource='prf_favela_realista'}
}) do
  Config.Operations.missions[#Config.Operations.missions+1]={name=incident.name,kind='factionWar',encounter=true,resource=incident.resource,
    points={{x=incident.x,y=incident.y,z=incident.z}},combatants={
      {model='g_m_y_ballaeast_01',weapon='WEAPON_ASSAULTRIFLE',side=1},
      {model='g_m_y_ballaorig_01',weapon='WEAPON_MICROSMG',side=1},
      {model='g_m_y_ballaeast_01',weapon='WEAPON_PISTOL',side=1},
      {model='g_m_y_famca_01',weapon='WEAPON_CARBINERIFLE',side=2},
      {model='g_m_y_famdnf_01',weapon='WEAPON_SMG',side=2},
      {model='g_m_y_famca_01',weapon='WEAPON_PISTOL',side=2}
    }}
end
Config.Operations.defaultCombatants={
  {model='g_m_y_ballaeast_01',weapon='WEAPON_PISTOL',side=1},
  {model='g_m_y_mexgoon_02',weapon='WEAPON_PISTOL',side=1},
  {model='g_m_y_ballaeast_01',weapon='WEAPON_PISTOL',side=1}
}
