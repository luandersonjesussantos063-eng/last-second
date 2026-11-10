-- PRF RP: simulacao ficticia; nao utiliza dados oficiais.
-- Coordenadas podem ser adaptadas para o seu mapa.
Config = {}

Config.Base = { x = 1853.5, y = 3687.6, z = 34.27, heading = 210.0 }
Config.Vehicle = 'police3' -- modelo padrao do GTA V, sem pacote pago
Config.Plate = 'PRF RP'
Config.TeleportOnDuty = true -- somente para ambiente de testes

Config.Calls = {
  {
    id = 'PRF-101',
    name = 'Veiculo imobilizado no acostamento',
    type = 'Apoio ao condutor',
    x = 1714.2, y = 3288.8, z = 41.15,
    details = 'Va ate o local, sinalize e verifique o condutor.'
  },
  {
    id = 'PRF-102',
    name = 'Objeto perigoso na rodovia',
    type = 'Seguranca viaria',
    x = 2471.5, y = 4112.8, z = 38.06,
    details = 'Sinalize o trecho e remova o risco.'
  },
  {
    id = 'PRF-103',
    name = 'Fiscalizacao de transito',
    type = 'Patrulhamento',
    x = 1183.9, y = 2660.7, z = 38.02,
    details = 'Desloque-se ao ponto indicado e inicie a fiscalizacao.'
  }
}
