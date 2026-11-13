-- Ocorrencias ficticias, com cenas e objetivos verificaveis no mundo do jogo.
Config.Copom={
  locations={
    {name='Route 68 / Harmony',x=1183.9,y=2660.7,z=38.02},
    {name='Senora / Sandy Shores',x=1714.2,y=3288.8,z=41.15},
    {name='Grapeseed',x=2471.5,y=4112.8,z=38.06},
    {name='Sandy Shores',x=1513.5,y=3594.2,z=35.35},
    {name='Senora Freeway',x=2664.4,y=3263.1,z=55.24},
    {name='Harmony / carga',x=1090.2,y=2647.5,z=38.12},
    {name='Great Ocean Highway / Chumash',x=-3090.0,y=1200.0,z=20.0},
    {name='Paleto / Great Ocean Highway',x=-110.0,y=6200.0,z=31.0}
  },
  templates={
    {key='breakdown',name='Pane no acostamento',code='PRF-201'},
    {key='collision',name='Colisao com vitimas',code='PRF-202'},
    {key='debris',name='Carga espalhada na pista',code='PRF-203'},
    {key='dui',name='Direcao perigosa e suspeita de alcool',code='PRF-204'},
    {key='stolen',name='Alerta de veiculo furtado',code='PRF-205'},
    {key='threat',name='Motoristas ameacados por homens armados',code='PRF-206'},
    {key='pedestrian',name='Pessoa desorientada junto a pista',code='PRF-207'},
    {key='fire',name='Veiculo em chamas',code='PRF-208'},
    {key='cargo',name='Caminhao com carga insegura',code='PRF-209'},
    {key='officer',name='Equipe policial sob ataque',code='PRF-210'}
  }
}
Config.ChatCommands.copom='copomStatus'
Config.ChatCommands.ocorrencia='call'
Config.ChatCommands.finalizar='copomFinish'
Config.ChatCommands.sinalizar='copomSecure'
Config.ChatCommands.conversar='copomTalk'
Config.ChatCommands.recolher='copomWork'
Config.ChatCommands.inspecionar='copomWork'
Config.ChatPhrases['encerrar ocorrencia']='finalizar'
Config.ChatPhrases['encerrar ocorrência']='finalizar'
Config.Services.tow={name='Guincho',vehicle='flatbed',ped='s_m_m_trucker_01'}

PrfBuildCopom=function(template,variant)
  local t={key=template.key,name=template.name,code=template.code,variant=variant,actors={},objectives={}}
  local function actor(key,kind,model,x,y,extra)
    local a={key=key,kind=kind,model=model,x=x,y=y}
    for k,v in pairs(extra or {}) do a[k]=v end
    t.actors[#t.actors+1]=a
    return a
  end
  local function vehicle(key,model,x,y,extra) return actor(key,'vehicle',model,x,y,extra) end
  local function person(key,model,x,y,extra) return actor(key,'ped',model,x,y,extra) end
  local function goal(key,kind,who,label,extra)
    local g={key=key,kind=kind,actor=who,label=label}
    for k,v in pairs(extra or {}) do g[k]=v end
    t.objectives[#t.objectives+1]=g
  end
  local function secure() goal('secure','secure',nil,'Sinalize: use cone ou sinalizar e coloque dois cones proximos da cena.') end
  local function talk(who,text) goal('talk_'..who,'talk',who,'Ouvir '..who..': conversar ou segurar E junto a pessoa.',{seconds=4,dialogue=text}) end
  local function medic(who) goal('medic_'..who,'ambulance',who,'Chame ambulancia perto de '..who..' e aguarde o socorro.') end
  local function tow(who) goal('tow_'..who,'tow',who,'Chame guincho junto a '..who..' e aguarde a remocao.') end
  local function arrest(who) goal('arrest_'..who,'arrest',who,'Aborde e prenda '..who..' com prender.') end
  local key=template.key
  if key=='breakdown' then
    vehicle('carro',variant==1 and 'blista' or 'asea',5,0,{damage=350,broken=true})
    person('motorista','a_m_m_business_01',8,2)
    secure();talk('motorista',variant==1 and 'O motor apagou e nao voltou. Preciso de um mecanico para continuar.' or 'Houve uma batida antes da pane. O carro nao pode seguir: preciso do guincho.')
    if variant==1 then goal('repair','mechanic','carro','Chame mecanico junto ao carro e aguarde o reparo.') else tow('carro') end
  elseif key=='collision' then
    vehicle('carro1','primo',5,0,{damage=240,broken=true})
    vehicle('carro2','ingot',4,7,{damage=350,broken=true,turn=25})
    person('vitima','a_f_y_tourist_01',9,4,{injured=true})
    person('testemunha','a_m_y_business_01',9,-3)
    secure();talk('testemunha','O outro carro freou de repente. Ela saiu machucada; chame socorro antes de remover os carros.')
    medic('vitima')
    if variant==2 then person('vitima2','a_m_y_roadcyc_01',10,8,{injured=true});medic('vitima2') end
    tow('carro1');tow('carro2')
  elseif key=='debris' then
    vehicle('caminhao','mule',6,12,{broken=true})
    person('motorista','s_m_m_trucker_01',9,9)
    secure();talk('motorista','A amarracao cedeu e a carga caiu na faixa. Ainda ha material atras do caminhao.')
    for i=1,variant+2 do
      local name='obstaculo'..i
      actor(name,'object',variant==1 and 'prop_box_wood02a_pu' or 'prop_barrel_02a',(i%2)*2-1,-4-i*2)
      goal('clear_'..i,'clear',name,'Retire '..name..': recolher ou segurar E junto ao objeto.',{seconds=5,needs={'secure'}})
    end
  elseif key=='dui' or key=='stolen' then
    vehicle('carro',variant==1 and 'sultan' or 'baller',3,0,{moving=true,suspect=true,flee=variant==2})
    person('suspeito','a_m_y_stbla_01',3,0,{driver='carro',weapon=key=='stolen' and 'WEAPON_PISTOL' or nil})
    goal('stop','stop','carro','Intercepte o carro com abordar e aguarde ele parar.')
    goal('documents','documents','carro','Consulte documento do carro ou do suspeito.')
    if key=='dui' then
      t.alcohol='0.62 mg/L'
      goal('alcohol','breathalyzer','carro','Use bafometro na abordagem. Se desembarcou, aborde o suspeito primeiro.')
    else
      t.wanted=true
      goal('search','search','suspeito','Mande descer, aborde o suspeito e use revistar para recolher a arma.')
    end
    arrest('suspeito')
    if key=='stolen' then tow('carro') end
    t.details=key=='dui' and 'Denuncia de manobras perigosas. Localize, pare o veiculo e apure a condicao do condutor.' or 'Placa com alerta ficticio de furto. Localize o veiculo, confirme o alerta e detenha o suspeito.'
  elseif key=='threat' or key=='officer' then
    local cop=key=='officer'
    vehicle('carro',cop and Config.Vehicle or 'asea',6,0,{damage=400,broken=true})
    person('vitima',cop and (Config.PRFSkinModel or 's_m_y_hwaycop_01') or 'a_m_m_business_01',9,0,{injured=true})
    if cop then goal('backup','backup',nil,'Solicite reforco e aguarde a viatura de apoio chegar perto da cena.') end
    for i=1,variant+1 do
      local who='agressor'..i
      person(who,i%2==1 and 'g_m_y_ballaeast_01' or 'g_m_y_mexgoon_02',-5-i*2,i*5-10,
        {hostile=true,weapon=i==1 and 'WEAPON_MICROSMG' or 'WEAPON_PISTOL'})
      goal('contain_'..i,'contain',who,'Contenha '..who..': prenda se houver rendicao ou impeça o ataque.')
    end
    medic('vitima');talk('vitima',cop and 'A equipe foi surpreendida na abordagem. Obrigado pelo apoio; preciso de atendimento medico.' or 'Eles bloquearam meu carro e ameacaram atirar. Obrigado por chegar.')
  elseif key=='pedestrian' then
    person('pedestre',variant==1 and 'a_m_m_hillbilly_01' or 'a_f_y_tourist_01',1,0,{wander=true})
    talk('pedestre','Estou desorientado e quase fui atingido. Posso acompanhar voce ate um lugar seguro?')
    t.safe={x=11,y=-16}
    goal('escort','escort','pedestre','Aborde, mande seguir e conduza a pessoa ate a area segura marcada.')
    medic('pedestre')
  elseif key=='fire' then
    vehicle('carro','emperor',5,0,{damage=450,fire=true,broken=true})
    person('motorista','a_m_y_business_01',13,0,{injured=true})
    secure();goal('fire','fire','carro','Chame bombeiros e aguarde o combate ao incendio.');medic('motorista')
    if variant==2 then
      vehicle('carro2','ingot',4,10,{damage=420,fire=true,broken=true})
      person('motorista2','a_f_y_tourist_01',13,10,{injured=true})
      goal('fire2','fire','carro2','Atenda tambem o segundo carro em chamas com bombeiros.');medic('motorista2')
    end
  elseif key=='cargo' then
    vehicle('caminhao','mule',5,0,{broken=true,cargo=true})
    person('motorista','s_m_m_trucker_01',9,2)
    secure();talk('motorista','Percebi a carga se movendo. Abri o compartimento para conferir; preciso deixar tudo seguro antes de seguir.')
    goal('documents','documents','caminhao','Aborde o caminhao e confira documento.')
    local volumes={}
    for i=1,variant+1 do
      local name='volume'..i
      actor(name,'object','prop_box_wood02a_pu',8,-3-i*2)
      goal('cargo_'..i,'cargo',name,'Inspecione '..name..': inspecionar ou segurar E junto ao volume.',{seconds=5})
      volumes[#volumes+1]='cargo_'..i
    end
    goal('load','load','caminhao','Prenda a carga e feche o compartimento: inspecionar junto a traseira.',{seconds=7,needs=volumes})
  end
  t.details=t.details or ('COPOM: '..t.name..'. Avalie a cena e atenda os envolvidos. Digite copom para conferir pendencias.')
  return t
end
