function ui_convert_value(amount) --format very long numbers
  local formatted = amount

  if tonumber(formatted) == nil then return nil end

  if tonumber(formatted) <= 1000000 then --we are below or just equal to a meg
    while true do
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')

      if (k==0) then
        break
      end
    end
  else --we are above a meg
    --divide by 100,000 so the decimal is shifted
    --floor the result to throw away everything after the decimal
    --divide by 10 to put the decimal in the right spot
    formatted = math.floor(tonumber(formatted)/100000) / 10 .. " m"
  end

  return formatted
end

function ui_color_percent(num_cur, num_max) --colorize based on a percentage
  --0 is ansiRed, 5 is ansiYellow, 9 is ansiGreen, 10 is default white
  --unfortunately mudlet's color table doesn't have a good gradiant 
  --so hexcodes from a random online gradiant tool it is
  local color_grad = {[0] = "#800000", [1] = "#801a00", [2] = "#803400", [3] = "#804e00", [4] = "#806800", 
    [5] = "#808000", [6] = "#668000", [7] = "#4c8000", [8] = "#328000", [9] = "#008000", [10] = "#FFFFFF"
  }
  --divide the current value by the max value to get a percentage
  --then multiply it by ten to shift the decimal
  --then floor it to chop off everything after the decimal
  --should result in a number between 0 and 10
  percent = math.floor((tonumber(num_cur) / tonumber(num_max)) * 10)
  color   = color_grad[percent]

  return color
end

-- Establish ranks as integers for logic that displays based on rank
ui_ranks = {
  ["Groundhog"]     = 0,
  ["Commander"]     = 1,
  ["Captain"]       = 2,
  ["Adventurer"]    = 3,
  ["Adventuress"]   = 3,
  ["Merchant"]      = 4,
  ["Trader"]        = 5,
  ["Industrialist"] = 6,
  ["Manufacturer"]  = 7,
  ["Financier"]     = 8,
  ["Founder"]       = 9,
}

--magic numbers taken from the documentation (https://federation2.com/guide/#sec-220.10)
--magic numbers confirmed by in-game 'help tax' document
--everyone over Financier has no cap (but may have a cap of 1,000,000,000?)
--planets and companies do have a cap of 1,000,000,000 but we don't track this so it's fine
--businesses have a cap of 100,000,000 but we also don't track this so it's still fine
ui_magic_cash_numbers = {
  ["Commander"] = 250000,
  ["Captain"] = 400000,
  ["Adventurer"] = 600000,
  ["Adventuress"] = 600000,
  ["Merchant"] = 7500000,
  ["Trader"] = 12500000,
  ["Industrialist"] = 17500000,
  ["Manufacturer"] = 22500000,
  ["Financier"] = 27500000,
}

--certainly there's a better way to do it, but distances manually counted using the map
--(https://federation2.com/guide/#sec-20.10)
--used with CommanderWork triggers
ui_sol_distances = {
  BrassCastilo = 5,
  BrassDoris = 2,
  BrassEarth = 8,
  BrassLattice = 4,
  BrassMagellan = 7,
  BrassMars = 6,
  BrassMercury = 8,
  BrassParadise = 8,
  BrassPearl = 10,
  BrassPhobos = 7,
  BrassRhea = 5,
  BrassSelena = 9,
  BrassSilk = 4,
  BrassSumatra = 4,
  BrassTitan = 5,
  BrassVenus = 7,
  CastilloDoris = 4,
  CastilloEarth = 3,
  CastilloLattice = 6,
  CastilloMagellan = 4,
  CastilloMars = 2,
  CastilloMercury = 6,
  CastilloParadise = 6,
  CastilloPearl = 8,
  CastilloPhobos = 2,
  CastilloRhea = 4,
  CastilloSelena = 4,
  CastilloSilk = 5,
  CastilloSumatra = 2,
  CastilloTitan = 2,
  CastilloVenus = 5,
  DorisEarth = 7,
  DorisLattice = 3,
  DorisMagellan = 6,
  DorisMars = 5,
  DorisMercury = 7,
  DorisParadise = 7,
  DorisPearl = 9,
  DorisPhobos = 6,
  DorisRhea = 4,
  DorisSelena = 8,
  DorisSilk = 3,
  DorisSumatra = 3,
  DorisTitan = 4,
  DorisVenus = 6,
  EarthLattice = 9,
  EarthMagellan = 1,
  EarthMars = 2,
  EarthMercury = 3,
  EarthParadise = 4,
  EarthPearl = 5,
  EarthPhobos = 2,
  EarthRhea = 7,
  EarthSelena = 1,
  EarthSilk = 8,
  EarthSumatra = 4,
  EarthTitan = 5,
  EarthVenus = 3,
  LatticeMagellan = 8,
  LatticeMars = 7,
  LatticeMercury = 9,
  LatticeParadise = 9,
  LatticePearl = 11,
  LatticePhobos = 8,
  LatticeRhea = 6,
  LatticeSelena = 10,
  LatticeSilk = 5,
  LatticeSumatra = 5,
  LatticeTitan = 6,
  LatticeVenus = 8,
  MagellanMars = 2,
  MagellanMercury = 2,
  MagellanParadise = 3,
  MagellanPearl = 4,
  MagellanPhobos = 3,
  MagellanRhea = 6,
  MagellanSelena = 2,
  MagellanSilk = 7,
  MagellanSumatra = 3,
  MagellanTitan = 5,
  MagellanVenus = 2,
  MarsMercury = 4,
  MarsParadise = 4,
  MarsPearl = 6,
  MarsPhobos = 1,
  MarsRhea = 5,
  MarsSelena = 3,
  MarsSilk = 6,
  MarsSumatra = 2,
  MarsTitan = 3,
  MarsVenus = 3,
  MercuryParadise = 4,
  MercuryPearl = 2,
  MercuryPhobos = 5,
  MercuryRhea = 7,
  MercurySelena = 2,
  MercurySilk = 8,
  MercurySumatra = 4,
  MercuryTitan = 7,
  MercuryVenus = 3,
  ParadisePearl = 5,
  ParadisePhobos = 5,
  ParadiseRhea = 7,
  ParadiseSelena = 5,
  ParadiseSilk = 8,
  ParadiseSumatra = 4,
  ParadiseTitan = 7,
  ParadiseVenus = 1,
  PearlPhobos = 7,
  PearlRhea = 9,
  PearlSelena = 4,
  PearlSilk = 10,
  PearlSumatra = 6,
  PearlTitan = 9,
  PearlVenus = 4,
  PhobosRhea = 6,
  PhobosSelena = 3,
  PhobosSilk = 7,
  PhobosSumatra = 3,
  PhobosTitan = 4,
  PhobosVenus = 4,
  RheaSelena = 8,
  RheaSilk = 5,
  RheaSumatra = 3,
  RheaTitan = 2,
  RheaVenus = 6,
  SelenaSilk = 9,
  SelenaSumatra = 5,
  SelenaTitan = 6,
  SelenaVenus = 4,
  SilkSumatra = 4,
  SilkTitan = 5,
  SilkVenus = 7,
  SumatraTitan = 3,
  SumatraVenus = 3,
  TitanVenus = 6,
 }