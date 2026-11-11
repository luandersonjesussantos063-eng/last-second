-- PRF RP standalone - cenário fictício inspirado em um posto rodoviário.
-- Trailblazer e uniformes enviados pelo usuario; modelos GTA continuam na frota de teste.
Config = {}
Config.Base = {
  name = 'Posto PRF RP Sandy Shores',
  x = 1853.5, y = 3687.6, z = 34.27, heading = 210.0,
  mapResource = false -- resource do mapa personalizado, quando instalado
}
Config.Garage = { x = 1848.5, y = 3692.3, z = 34.25, heading = 207.0 }
Config.Wardrobe = { x = 1858.0, y = 3692.0, z = 34.25 }
Config.Dispatch = { x = 1854.0, y = 3686.8, z = 34.25 }
Config.Armory = { x = 1859.5, y = 3687.0, z = 34.25 }
Config.Vehicle = 'police' -- Trailblazer PRF; exige prf_trailblazer com os arquivos do mod
Config.Plate = 'PRF RP'
Config.TeleportOnDuty = true
Config.PhotoMotorcycle = false -- codigo de spawn da BMW da foto, quando instalada
Config.Uniform = {
  resource = 'prf_uniformes_wlukaas',
  defaultSex = 'male',
  male = {
    model = 'mp_m_freemode_01',
    components = {
      { component = 11, collection = 'mp_m_christmas2017', drawable = 1, texture = 0 },
      { component = 9, collection = 'male_freemode_business2', drawable = 0, texture = 0 }
    },
    props = {
      { anchor = 0, collection = 'mp_m_christmas2017', drawable = 1, texture = 0 }
    }
  },
  female = {
    model = 'mp_f_freemode_01',
    components = {
      { component = 11, collection = 'female_heist', drawable = 3, texture = 0 },
      { component = 4, collection = 'female_heist', drawable = 1, texture = 0 },
      { component = 9, collection = 'female_heist', drawable = 0, texture = 0 },
      { component = 7, collection = 'female_heist', drawable = 1, texture = 0 }
    },
    props = {
      { anchor = 0, collection = 'mp_f_christmas2017', drawable = 1, texture = 0 }
    }
  }
}
-- Frota em array: F9 percorre estes modelos; resource/livery/modLivery/extras sao opcionais.
-- Modelos externos mantem as cores e texturas do autor.
Config.Fleet = {
  { model = 'police', name = 'Chevrolet Trailblazer PRF', resource = 'prf_trailblazer',
    livery = false, modLivery = false, extras = {}, demoColours = false,
    assetFiles = { ['stream/police.yft'] = 14393991, ['stream/police_hi.yft'] = 14393991,
      ['stream/police.ytd'] = 1418431 } },
  { model = 'police3', name = 'Sedan de patrulhamento (GTA)', demoColours = true },
  { model = 'police2', name = 'Sedan de apoio (GTA)', demoColours = true },
  { model = 'sheriff2', name = 'SUV de apoio (GTA)', demoColours = true },
  { model = 'policeb', name = 'Moto de patrulhamento (GTA)' },
}
-- Três colegas NPC: dois agentes rodoviários e uma policial do GTA V.
Config.Team = { 's_m_y_hwaycop_01', 's_m_y_hwaycop_01', 's_f_y_cop_01' }
Config.BaseProps = {
  { model = 'prop_roadcone02a', x = 1845.5, y = 3692.2, z = 33.3, heading = 0.0 },
  { model = 'prop_roadcone02a', x = 1845.5, y = 3696.0, z = 33.3, heading = 0.0 },
  { model = 'prop_barrier_work05', x = 1861.6, y = 3687.8, z = 33.3, heading = 30.0 },
  { model = 'prop_barrier_work05', x = 1862.2, y = 3690.8, z = 33.3, heading = 30.0 },
}
Config.Calls = {
  {
    id = 'PRF-101', name = 'Veículo imobilizado no acostamento',
    type = 'Apoio ao condutor', x = 1714.2, y = 3288.8, z = 41.15,
    pedModel = 'a_m_m_business_01', scene = 'breakdown',
    details = 'Motorista parado no acostamento. Faça a sinalização e verifique a situação.',
    steps = { 'Sinalizar a área', 'Conversar com o motorista', 'Registrar atendimento' }
  },
  {
    id = 'PRF-102', name = 'Objeto perigoso na rodovia',
    type = 'Segurança viária', x = 2471.5, y = 4112.8, z = 38.06,
    pedModel = 's_m_m_dockwork_01', scene = 'hazard',
    details = 'Material na pista. Isole o local e registre a retirada simulada.',
    steps = { 'Isolar a via', 'Inspecionar o objeto', 'Liberar trânsito' }
  },
  {
    id = 'PRF-103', name = 'Fiscalização de trânsito',
    type = 'Patrulhamento', x = 1183.9, y = 2660.7, z = 38.02,
    pedModel = 'a_m_y_business_01', scene = 'inspection',
    details = 'Ponto de fiscalização. Faça a abordagem simulada.',
    steps = { 'Sinalizar parada', 'Verificar documentação', 'Finalizar fiscalização' }
  },
  {
    id = 'PRF-104', name = 'Apoio em colisão leve',
    type = 'Atendimento rodoviário', x = 1513.5, y = 3594.2, z = 35.35,
    pedModel = 'a_m_y_roadcyc_01', scene = 'breakdown',
    details = 'Colisão sem feridos reportados. Proteja a cena e oriente o condutor.',
    steps = { 'Proteger local', 'Conferir envolvidos', 'Registrar e liberar via' }
  },
  {
    id = 'PRF-105', name = 'Condutor precisando de auxílio',
    type = 'Apoio rodoviário', x = 2664.4, y = 3263.1, z = 55.24,
    pedModel = 'a_f_y_tourist_01', scene = 'breakdown',
    details = 'Condutor solicita ajuda para seguir viagem.',
    steps = { 'Estacionar e sinalizar', 'Prestar auxílio', 'Encerrar atendimento' }
  },
  {
    id = 'PRF-106', name = 'Fiscalização de carga',
    type = 'Operação rodoviária', x = 1090.2, y = 2647.5, z = 38.12,
    pedModel = 's_m_m_trucker_01', scene = 'inspection',
    details = 'Caminhão aguarda verificação fictícia dos documentos da carga.',
    steps = { 'Isolar ponto de parada', 'Conferir carga e documentos', 'Liberar caminhão' }
  },
}
