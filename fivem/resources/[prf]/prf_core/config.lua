-- PRF RP standalone - cenário fictício inspirado em um posto rodoviário.
-- Modelos nativos GTA V: não são veículos/fardas oficiais da PRF.
Config = {}
-- Extraído do mapa prfminibaseln3d3v.ymap, próximo a Chumash / Great Ocean Highway.
-- Posição da construção, NÃO é ainda ponto de spawn/garagem validado no jogo.
Config.CustomBase = { x = -3026.0, y = 367.0, z = 14.0 }
Config.CustomBaseResource = 'prfMiniLN3d3v'
Config.Base = { x = 1853.5, y = 3687.6, z = 34.27, heading = 210.0 }
Config.Garage = { x = 1848.5, y = 3692.3, z = 34.25, heading = 207.0 }
Config.Wardrobe = { x = 1858.0, y = 3692.0, z = 34.25 }
Config.Dispatch = { x = 1854.0, y = 3686.8, z = 34.25 }
Config.Armory = { x = 1859.5, y = 3687.0, z = 34.25 }
Config.Vehicle = 'police' -- slot substituido pela viatura PRF instalada
Config.Plate = 'PRF RP'
-- O chat padrao do FiveM abre no T. Aceita estas palavras com ou sem barra.
Config.ChatCommands = {
  servico='duty', viatura='vehicle', farda='uniform', arma='weapon', fuzil='weapon',
  abordar='approach', documento='documents', documentos='documents',
  passagem='documents', antecedentes='documents', revistar='search', liberar='release',
  guincho='tow', reforco='backup', ['reforço']='backup', blitz='blitz',
  ronda='mission', cancelarronda='cancelMission', giroflex='lights', sirene='siren',
  equipe='team', chamado='call', cancelar='cancel', status='status',
  base='base', favela='favela', ajuda='help'
}
Config.ChatCommands.descer='exit'
Config.ChatCommands.desce='exit'
Config.ChatCommands.desembarcar='exit'
Config.ChatCommands.deitar='prone'
Config.ChatCommands.deita='prone'
Config.ChatCommands.maonacabeca='head'
Config.ChatCommands.mao='head'
Config.ChatCommands.maos='handsup'
Config.ChatCommands.ajoelhar='kneel'
Config.ChatCommands.levantar='stand'
Config.ChatCommands.parar='stay'
Config.ChatCommands.ficar='stay'
Config.ChatCommands.seguir='follow'
Config.ChatCommands.conduzir='follow'
Config.ChatCommands.algemar='cuff'
Config.ChatCommands.desalgemar='uncuff'
Config.ChatCommands.entrar='enter'
Config.ChatCommands.entra='enter'
Config.ChatCommands.bafometro='breathalyzer'
Config.ChatCommands.dispensarreforco='dismissBackup'
Config.ChatCommands.liberarcarro='releaseVehicle'
Config.ChatCommands.cancelarperseguicao='cancelPursuit'
Config.ChatCommands.prender='arrest'
Config.ChatCommands.registrarprisao='bookArrest'
Config.ChatCommands.entregarpreso='bookArrest'
Config.ChatCommands.prisoes='arrestHistory'
Config.PersonOrders = {head=true,handsup=true,prone=true,kneel=true,stand=true,stay=true,
  follow=true,cuff=true,uncuff=true,enter=true,exit=true,arrest=true}
Config.Custody = {radius=15.0,transportTimeout=1800,historyLimit=200}
Config.ChatPhrases = {
  ['desce do carro']='descer', ['descer do carro']='descer',
  ['deita no chao']='deitar', ['deita no chão']='deitar', ['deitar no chao']='deitar',
  ['mao na cabeca']='maonacabeca', ['mão na cabeça']='maonacabeca',
  ['maos na cabeca']='maonacabeca', ['mãos na cabeça']='maonacabeca',
  ['maos pra cima']='maos', ['mãos pra cima']='maos', ['maos para cima']='maos',
  ['entra no carro']='entrar', ['entrar no carro']='entrar',
  ['dispensar reforco']='dispensarreforco', ['dispensar reforço']='dispensarreforco'
}
Config.ChatPhrases['liberar carro']='liberarcarro'
Config.ChatPhrases['cancelar perseguicao']='cancelarperseguicao'
Config.ChatPhrases['cancelar perseguição']='cancelarperseguicao'
Config.ChatPhrases['registrar prisao']='registrarprisao'
Config.ChatPhrases['registrar prisão']='registrarprisao'
Config.ChatPhrases['entregar preso']='entregarpreso'
-- Parser compartilhado: frases exatas e quantidade de reforco, sem executar texto.
PrfParseChat = function(message)
  if type(message)~='string' or #message>96 then return end
  local text=message:lower():gsub('^%s*',''):gsub('%s*$',''):gsub('^/',''):gsub('%s+',' ')
  if Config.ChatPhrases[text] then return Config.ChatPhrases[text],{} end
  local name,rest=text:match('^(%S+)%s*(.-)$')
  if not name or not Config.ChatCommands[name] then return end
  if rest=='' then return name,{} end
  if Config.ChatCommands[name]=='backup' then return name,{rest} end
end
Config.TeleportOnDuty = true
-- Entrada externa calculada a partir da porta do MLO e da transformacao no YMAP.
-- A altura do piso e conferida no cliente antes de liberar o personagem.
Config.SpawnAtBase = true
Config.SpawnBase = { x = -3030.98, y = 362.89, z = 15.89, heading = 81.0 }
Config.Fleet = {
  { model = 'police', name = 'SUV PRF (Equinox/Trailblazer)',
    resource = 'prf_equinox_replace', alternateResource = 'prf_trailblazer', preservePaint = true },
  { model = 'police3', name = 'Sedan de patrulhamento (GTA)' },
  { model = 'police2', name = 'Sedan de apoio (GTA)' },
  { model = 'sheriff2', name = 'SUV de apoio (GTA)' },
  { model = 'policeb', name = 'Moto de patrulhamento (GTA)' },
}
-- Três colegas NPC: dois agentes rodoviários e uma policial do GTA V.
Config.Team = { 's_m_y_hwaycop_01', 's_m_y_hwaycop_01', 's_m_y_hwaycop_01' }
-- Mod enviado pelo usuário: substitui o ped original de xerife, não é addon.
Config.PRFSkinResource = 'prf_skin_replace'
Config.PRFSkinModel = 's_m_y_sheriff_01'
Config.UniformModel = 's_m_y_hwaycop_01' -- fallback sem o mod instalado
Config.DutyWeapon = 'WEAPON_CARBINERIFLE' -- arma fictícia GTA V, apenas turno autorizado
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
