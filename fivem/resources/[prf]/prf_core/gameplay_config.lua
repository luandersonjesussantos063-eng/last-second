Config.SearchWeapons={}
local function weapons(names,label,ammo)
  for name in names:gmatch('%S+') do Config.SearchWeapons['WEAPON_'..name]={label=label..' ('..name..')',ammo=ammo} end
end
weapons('PISTOL COMBATPISTOL APPISTOL PISTOL50 SNSPISTOL HEAVYPISTOL VINTAGEPISTOL MARKSMANPISTOL REVOLVER DOUBLEACTION CERAMICPISTOL NAVYREVOLVER GADGETPISTOL PISTOL_MK2 SNSPISTOL_MK2 REVOLVER_MK2','Pistola','AMMO_PISTOL')
weapons('MICROSMG SMG ASSAULTSMG COMBATPDW MACHINEPISTOL MINISMG SMG_MK2','Submetralhadora','AMMO_SMG')
weapons('ASSAULTRIFLE CARBINERIFLE ADVANCEDRIFLE SPECIALCARBINE BULLPUPRIFLE COMPACTRIFLE MILITARYRIFLE HEAVYRIFLE TACTICALRIFLE ASSAULTRIFLE_MK2 CARBINERIFLE_MK2 SPECIALCARBINE_MK2 BULLPUPRIFLE_MK2','Fuzil','AMMO_RIFLE')
weapons('PUMPSHOTGUN SAWNOFFSHOTGUN ASSAULTSHOTGUN BULLPUPSHOTGUN HEAVYSHOTGUN DBSHOTGUN AUTOSHOTGUN COMBATSHOTGUN PUMPSHOTGUN_MK2','Espingarda','AMMO_SHOTGUN')
weapons('SNIPERRIFLE HEAVYSNIPER MARKSMANRIFLE HEAVYSNIPER_MK2 MARKSMANRIFLE_MK2','Rifle de precisao','AMMO_SNIPER')
weapons('MG COMBATMG GUSENBERG COMBATMG_MK2','Metralhadora','AMMO_MG')
weapons('KNIFE NIGHTSTICK HAMMER BAT CROWBAR GOLFCLUB BOTTLE DAGGER HATCHET KNUCKLE MACHETE SWITCHBLADE BATTLEAXE POOLCUE WRENCH STONE_HATCHET','Arma branca',nil)
weapons('STUNGUN STUNGUN_MP','Arma de choque',nil)
weapons('MUSKET','Mosquete','AMMO_SHOTGUN')
weapons('RPG HOMINGLAUNCHER','Lancador','AMMO_ROCKET')
weapons('GRENADELAUNCHER COMPACTLAUNCHER','Lancador de granadas','AMMO_GRENADELAUNCHER')
weapons('MINIGUN','Metralhadora pesada','AMMO_MINIGUN')
weapons('GRENADE STICKYBOMB MOLOTOV PIPEBOMB PROXMINE','Explosivo',nil)
Config.AmmoLabels={AMMO_PISTOL='Municao de pistola',AMMO_SMG='Municao de SMG',AMMO_RIFLE='Municao de fuzil',
  AMMO_SHOTGUN='Cartuchos de espingarda',AMMO_SNIPER='Municao de precisao',AMMO_MG='Municao de metralhadora',
  AMMO_ROCKET='Foguetes',AMMO_GRENADELAUNCHER='Granadas de lancador',AMMO_MINIGUN='Municao de minigun'}
Config.ChatCommands.inventario='inventory'
Config.ChatCommands.progresso='progress'
Config.ChatCommands.salvar='saveProgress'
Config.ChatCommands.tablet='tablet'
Config.ChatCommands.porta='baseDoor'
Config.ChatCommands.ambulancia='ambulance'
Config.ChatCommands.mecanico='mechanic'
Config.ChatCommands.bombeiros='fire'
Config.ChatCommands.servicos='services'
Config.ChatCommands.chamar='services'
Config.ChatCommands.cone='cone'
Config.ChatCommands.recolhercones='clearCones'
Config.ChatCommands.guardarcone='cancelCone'
Config.ChatCommands.guerradefaccao='factionWar'
Config.ChatPhrases['chamar ambulancia']='ambulancia'
Config.ChatPhrases['chamar ambulância']='ambulancia'
Config.ChatPhrases['chamar mecanico']='mecanico'
Config.ChatPhrases['chamar mecânico']='mecanico'
Config.ChatPhrases['chamar bombeiros']='bombeiros'
Config.ChatPhrases['recolher cones']='recolhercones'
Config.ChatPhrases['guerra de faccao']='guerradefaccao'
Config.ChatPhrases['guerra de facção']='guerradefaccao'
Config.Services={
  ambulance={name='Ambulancia',vehicle='ambulance',ped='s_m_m_paramedic_01'},
  mechanic={name='Mecanico',vehicle='utillitruck3',ped='s_m_y_xmech_01'},
  fire={name='Bombeiros',vehicle='firetruk',ped='s_m_y_fireman_01'}
}
