Config.Operations = {
  encounterChance = 35, -- porcentagem por ronda; confronto somente em missao aceita
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
