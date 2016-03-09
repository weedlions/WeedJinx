local ts, ts2
local minman
local jinxq, jinxqtrue = false -- 0 = MG, 1 = RL
local myHero = GetMyHero()
local predTable = {"None"}
local currentPred = nil
local qlvl = 0
local q0,q1,q2,q3,q4,q5 = false
local healactive = false
local Version = 0.909
local Heal, Barrier = nil
local OrbWalkers = {}
local LoadedOrb = nil
local targets, wtargets

if myHero.charName ~= "Jinx" then return end

function VPredLoader()
  local LibPath = LIB_PATH.."VPrediction.lua"
  if not (FileExist(LibPath)) then
    local Host = "raw.githubusercontent.com"
    local Path = "/SidaBoL/Scripts/master/Common/VPrediction.lua"
    DownloadFile("https://"..Host..Path, LibPath, function () prntChat("VPrediction installed. Please press 2x F9") end)
    require "VPrediction"
    currentPred = VPrediction()
  else
    require "VPrediction"
    currentPred = VPrediction()
  end
end
AddLoadCallback(function() VPredLoader() end)

function OnLoad()

  minman = minionManager(MINION_ALL, 800)

  if(myHero.charName == "Jinx") then
    prntChat("Welcome to Weed Jinx. Good Luck, Have Fun!")
    prntChat("Version "..Version.." loaded.")
  end

  ts = TargetSelector(TARGET_LESS_CAST,1450)
  ts2 = TargetSelector(TARGET_LESS_CAST,525)

  initMenu()
  initSumms()
  CheckUpdates()
  InitOrbs()
  LoadOrb()

end

function initSumms()

  if myHero:GetSpellData(SUMMONER_1).name == "SummonerBarrier" then Barrier = 1
  elseif myHero:GetSpellData(SUMMONER_1).name == "SummonerHeal" then Heal = 1 end

  if myHero:GetSpellData(SUMMONER_2).name == "SummonerBarrier" then Barrier = 2
  elseif myHero:GetSpellData(SUMMONER_2).name == "SummonerHeal" then Heal = 2 end

end

function initMenu()

  Config = scriptConfig("Weed Jinx", "weedjnx")

  Config:addSubMenu("Combo Settings", "settComb")
  Config.settComb:addParam("useq", "Smart Q Usage", SCRIPT_PARAM_ONOFF, true)
  Config.settComb:addParam("usew", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.settComb:addParam("usewaa", "Use W Only if enemy not in AA Range", SCRIPT_PARAM_ONOFF, true)
  Config.settComb:addParam("usee", "Use E", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Harass Settings", "settHar")
  Config.settHar:addParam("useq", "Smart Q Usage", SCRIPT_PARAM_ONOFF, true)
  Config.settHar:addParam("usew", "Use W", SCRIPT_PARAM_ONOFF, true)
  Config.settHar:addParam("usewaa", "Use W Only if enemy not in AA Range", SCRIPT_PARAM_ONOFF, true)
  Config.settHar:addParam("usee", "Use E", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Laneclear Settings", "settLC")
  Config.settLC:addParam("minigun", "Switch to Minigun on Laneclear", SCRIPT_PARAM_ONOFF, true)
  Config.settLC:addParam("rocket", "Use Rocket Launcher", SCRIPT_PARAM_ONOFF, false)
  Config.settLC:addParam("count", "X Minions to use Rocket Launcher", SCRIPT_PARAM_SLICE, 3, 1, 10, 0)

  Config:addSubMenu("Lasthit Settings", "settLH")
  Config.settLH:addParam("minigun", "Switch to Minigun on Lasthit", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Killsteal Settings", "settSteal")
  Config.settSteal:addParam("usew", "Use W for Killsteal", SCRIPT_PARAM_ONOFF, true)
  Config.settSteal:addParam("user", "Use R for Killsteal", SCRIPT_PARAM_ONOFF, true)
  Config.settSteal:addParam("minrange", "Min Range for R Steal", SCRIPT_PARAM_SLICE, 500, 0, 5000, 0)
  Config.settSteal:addParam("range", "Max Range for R Steal", SCRIPT_PARAM_SLICE, 1500, 0, 5000, 0)

  Config:addSubMenu("Draw Settings", "settDraw")
  Config.settDraw:addParam("qrange", "Draw Q Range", SCRIPT_PARAM_ONOFF, false)
  Config.settDraw:addParam("wrange", "Draw W Range", SCRIPT_PARAM_ONOFF, false)
  Config.settDraw:addParam("erange", "Draw E Range", SCRIPT_PARAM_ONOFF, false)
  Config.settDraw:addParam("wayp", "Draw Waypoints", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Auto Potion Settings", "settPot")
  Config.settPot:addParam("active", "Use Auto Potion", SCRIPT_PARAM_ONOFF, true)
  Config.settPot:addParam("hp", "Min % HP to Activate", SCRIPT_PARAM_SLICE, 60, 0, 100, 0)

  Config:addSubMenu("Auto Heal/Auto Barrier Settings", "settAHeal")
  Config.settAHeal:addParam("active", "Use Auto Heal/Barrier", SCRIPT_PARAM_ONOFF, true)
  Config.settAHeal:addParam("hp", "Use on X % HP", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)

  Config:addSubMenu("HitChance Settings", "settHit")
  Config.settHit:addParam("Blank", "HitChance for W", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("whit", "HitChance: Recommended = 2", SCRIPT_PARAM_SLICE, 2, 2, 4, 0)
  Config.settHit:addParam("Blank", "HitChance for E", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("ehit", "HitChance: Recommended = 4", SCRIPT_PARAM_SLICE, 4, 2, 4, 0)
  Config.settHit:addParam("x", "HitChance when under X % HP", SCRIPT_PARAM_SLICE, 25, 0, 100, 0)
  Config.settHit:addParam("ehitx", "HitChance: Recommended = 2", SCRIPT_PARAM_SLICE, 2, 2, 4, 0)
  Config.settHit:addParam("Blank", "HitChance for R", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("rhit", "HitChance: Recommended = 2", SCRIPT_PARAM_SLICE, 2, 2, 4, 0)
  Config.settHit:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "Explanation", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "2 = High Hitchance", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "3 = Slowed Targets (~100%)", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "4 = Immobile Targets (~100%)", SCRIPT_PARAM_INFO, "")

end

function OnTick()

  if myHero.dead then return end

  ts:update()
  ts2:update()
  minman:update()

  if(getMode() == "Laneclear") then onLaneClear() end

  if(getMode() == "Lasthit") then onLastHit() end

  if(getMode() == "Combo") then onCombo() end

  if(getMode() == "Harass") then onHarass() end

  getQStatus()
  qlvl = myHero:GetSpellData(_Q).level
  if Config.settPot then autoPotion() end

  tsUpdate()

  onKillSteal()

  if Config.settAHeal.active then autoHeal() end

end

function autoHeal()

  if ((myHero.health/myHero.maxHealth)*100) < Config.settAHeal.hp then
    if Barrier==1 and myHero:CanUseSpell(SUMMONER_1) then
      CastSpell(SUMMONER_1)
    elseif Heal==1 and myHero:CanUseSpell(SUMMONER_1) then
      CastSpell(SUMMONER_1)
    elseif Barrier==2 and myHero:CanUseSpell(SUMMONER_2) then
      CastSpell(SUMMONER_2)
    elseif Heal==2 and myHero:CanUseSpell(SUMMONER_2) then
      CastSpell(SUMMONER_2)
    end
  end

end

function onKillSteal()

  if Config.settSteal.usew then
    for i=1, heroManager.iCount do
      local enemy = heroManager:getHero(i)

      if enemy.team ~= myHero.team and not enemy.dead and enemy.visible and myHero:CanUseSpell(_W) == READY and enemy.health < (getDmg("W", enemy, myHero) - 10) and enemy.bTargetable then
        local CastPosition = predict(enemy, "W")
        if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
      end
    end
  end

  if Config.settSteal.user then
    for i=1, heroManager.iCount do
      local enemy = heroManager:getHero(i)
      if enemy.team ~= myHero.team and not enemy.dead and enemy.visible and myHero:CanUseSpell(_R) == READY and enemy.health < (getDmg("R", enemy, myHero) - 10) and enemy.bTargetable then
        local CastPosition = predict(enemy, "R")
        if(CastPosition ~= nil) then CastSpell(_R, CastPosition.x, CastPosition.z) end
      end
    end
  end

end

function tsUpdate()

  if qlvl == 0 and not q0 then
    ts2 = TargetSelector(TARGET_LESS_CAST,525)
    minman = minionManager(MINION_ALL, 525)
    q0 = true
  elseif qlvl == 1 and not q1 then
    ts2 = TargetSelector(TARGET_LESS_CAST,600)
    minman = minionManager(MINION_ALL, 600)
    q1 = true
  elseif qlvl == 2 and not q2 then
    ts2 = TargetSelector(TARGET_LESS_CAST,625)
    minman = minionManager(MINION_ALL, 625)
    q2 = true
  elseif qlvl == 3 and not q3 then
    ts2 = TargetSelector(TARGET_LESS_CAST,650)
    minman = minionManager(MINION_ALL, 650)
    q3 = true
  elseif qlvl == 4 and not q4 then
    ts2 = TargetSelector(TARGET_LESS_CAST,675)
    minman = minionManager(MINION_ALL, 675)
    q4 = true
  elseif qlvl == 5 and not q5 then
    ts2 = TargetSelector(TARGET_LESS_CAST,700)
    minman = minionManager(MINION_ALL, 700)
    q5 = true
  end

end

function onLaneClear()

  local count = 0

  if jinxq and Config.settLC.minigun then
    CastSpell(_Q)
  end

  if Config.settLC.rocket then
    for i, minion in pairs(minman.objects) do
      if not minion.dead and minion.team ~= myHero.team then count = count+1 end
    end

    if count >= Config.settLC.count and not jinxq then CastSpell(_Q)
    elseif count < Config.settLC.count and jinxq then CastSpell(_Q) end
  end

end

function onLastHit()

  if jinxq and Config.settLH.minigun then
    CastSpell(_Q)
  end

end

function autoPotion()

  local hac = false

  for i = 1, myHero.buffCount do
    local tBuff = myHero:getBuff(i)
    if BuffIsValid(tBuff) then
      if(tBuff.name == "ItemMiniRegenPotion" or tBuff.name == "RegenerationPotion") then hac = true end
    end
  end

  if hac then healactive = true
  else healactive = false end

  if ((myHero.health/myHero.maxHealth)*100) < Config.settPot.hp and not healactive then
    CastItem("ItemMiniRegenPotion")
    CastItem("RegenerationPotion")
  end

end

function getQStatus()

  for i = 1, myHero.buffCount do
    local tBuff = myHero:getBuff(i)
    if BuffIsValid(tBuff) then
      if(tBuff.name == "JinxQ") then jinxqtrue = true end
    end
  end

  if jinxqtrue then
    jinxq, jinxqtrue = true, false
  else jinxq, jinxqtrue = false
  end

end

function onHarass()

  local enemy = GetTarget()
  local wenemy = GetWTarget()

  if enemy == nil then return end
  if wenemy == nil then return end

  if not enemy.bTargetable and not enemy.visible then return end
  if not wenemy.bTargetable and not wenemy.visible then return end

  if enemy ~= nil then
    if Config.settComb.useq and myHero:CanUseSpell(_Q) then
      if GetDistance(enemy.pos) > 525 then
        if(qlvl == 0) then
        elseif(qlvl == 1) then
          if GetDistance(enemy.pos) < 600 and not jinxq then CastSpell(_Q) end
        elseif(qlvl == 2) then
          if GetDistance(enemy.pos) < 625 and not jinxq then CastSpell(_Q) end
        elseif(qlvl == 3) then
          if GetDistance(enemy.pos) < 650 and not jinxq then CastSpell(_Q) end
        elseif(qlvl == 4) then
          if GetDistance(enemy.pos) < 675 and not jinxq then CastSpell(_Q) end
        elseif(qlvl == 5) then
          if GetDistance(enemy.pos) < 700 and not jinxq then CastSpell(_Q) end
        end
      elseif GetDistance(enemy.pos) < 525 then
        if jinxq then CastSpell(_Q) end
      end
    end
  end

  if wenemy ~= nil then
    if Config.settHar.usew and myHero:CanUseSpell(_W) then
      if Config.settHar.usewaa then
        if(qlvl == 0) then
          if GetDistance(wenemy.pos) > 525 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 1) then
          if GetDistance(wenemy.pos) > 600 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 2) then
          if GetDistance(wenemy.pos) > 625 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 3) then
          if GetDistance(wenemy.pos) > 650 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 4) then
          if GetDistance(wenemy.pos) > 675 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 5) then
          if GetDistance(wenemy.pos) > 700 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        end
      else
        local CastPosition = predict(wenemy, "W")
        if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
      end
    end

    if Config.settHar.usee and myHero:CanUseSpell(_E) then
      if ((myHero.health/myHero.maxHealth)*100) > Config.settHit.x then
        local CastPosition = predict(enemy, "E")
        if(CastPosition ~= nil) then CastSpell(_E, CastPosition.x, CastPosition.z) end
      else
        local CastPosition = predict(enemy, "EX")
        if(CastPosition ~= nil) then CastSpell(_E, CastPosition.x, CastPosition.z) end
      end
    end
  end

end

function onCombo()

  local enemy = GetTarget()
  local wenemy = GetWTarget()

  if enemy == nil then return end
  if wenemy == nil then return end

  if not enemy.bTargetable and not enemy.visible then return end
  if not wenemy.bTargetable and not wenemy.visible then return end

  if enemy ~= nil then
    if Config.settComb.useq and myHero:CanUseSpell(_Q) then
      if GetDistance(enemy.pos) > 525 then
        if(qlvl == 0) then
        elseif(qlvl == 1) then
          if GetDistance(enemy.pos) < 600 and not jinxq then CastSpell(_Q) end
        elseif(qlvl == 2) then
          if GetDistance(enemy.pos) < 625 and not jinxq then CastSpell(_Q) end
        elseif(qlvl == 3) then
          if GetDistance(enemy.pos) < 650 and not jinxq then CastSpell(_Q) end
        elseif(qlvl == 4) then
          if GetDistance(enemy.pos) < 675 and not jinxq then CastSpell(_Q) end
        elseif(qlvl == 5) then
          if GetDistance(enemy.pos) < 700 and not jinxq then CastSpell(_Q) end
        end
      elseif GetDistance(enemy.pos) < 525 then
        if jinxq then CastSpell(_Q) end
      end
    end
  end

  if wenemy ~= nil then
    if Config.settComb.usew and myHero:CanUseSpell(_W) then
      if Config.settComb.usewaa then
        if(qlvl == 0) then
          if GetDistance(wenemy.pos) > 525 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 1) then
          if GetDistance(wenemy.pos) > 600 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 2) then
          if GetDistance(wenemy.pos) > 625 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 3) then
          if GetDistance(wenemy.pos) > 650 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 4) then
          if GetDistance(wenemy.pos) > 675 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        elseif(qlvl == 5) then
          if GetDistance(wenemy.pos) > 700 then
            local CastPosition = predict(wenemy, "W")
            if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
          end
        end
      else
        local CastPosition = predict(wenemy, "W")
        if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
      end
    end

    if Config.settComb.usee and myHero:CanUseSpell(_E) then
      if ((myHero.health/myHero.maxHealth)*100) > Config.settHit.x then
        local CastPosition = predict(enemy, "E")
        if(CastPosition ~= nil) then CastSpell(_E, CastPosition.x, CastPosition.z) end
      else
        local CastPosition = predict(enemy, "EX")
        if(CastPosition ~= nil) then CastSpell(_E, CastPosition.x, CastPosition.z) end
      end
    end
  end

end

function GetTarget()

  if LoadedOrb == "Sac" and TIMETOSACLOAD then
    return _G.AutoCarry.Crosshair:GetTarget()
  elseif LoadedOrb == "Mma" then
    return _G.MMA_GetTarget()
  elseif LoadedOrb == "Pewalk" then
    return _G._Pewalk.GetTarget()
  elseif LoadedOrb == "Now" then
    return _G.NOWi:GetTarget()
  elseif LoadedOrb == "Sow" then
    return _G.SOWi:GetTarget(true)
  elseif LoadedOrb == "SxOrbWalk" then
    return _G.SxOrb:GetTarget()
  end

  ts2:update()
  return ts2.target

end

function GetWTarget()

  ts:update()
  return ts.target

end

function predict(target, spell)

  if(spell == "W") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.60, 40, 1450, math.huge, myHero, true)
    if CastPosition and HitChance >= Config.settHit.whit and GetDistance(CastPosition) < 1440 then
      return CastPosition
    end
  elseif(spell == "E") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.35, 50, 900, 1500, myHero, false)
    if CastPosition and HitChance >= Config.settHit.ehit and GetDistance(CastPosition) < 890 then
      return CastPosition
    end
  elseif(spell == "EX") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.35, 50, 900, 1500, myHero, false)
    if CastPosition and HitChance >= Config.settHit.ehitx and GetDistance(CastPosition) < 890 then
      return CastPosition
    end
  elseif(spell == "R") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.55, 150, math.huge, 1500, myHero, true)
    if CastPosition and HitChance >= Config.settHit.rhit and GetDistance(CastPosition) < Config.settSteal.range and GetDistance(CastPosition) > Config.settSteal.minrange then
      return CastPosition
    end
  else return nil
  end

end

function CastItem(item, unit)
  for slot = ITEM_1, ITEM_7 do
    if myHero:GetSpellData(slot).name == item and unit then
      CastSpell(slot, unit)
    elseif myHero:GetSpellData(slot).name == item then
      CastSpell(slot)
    end
  end
end

function OnDraw()

  if(Config.settDraw.qrange) then
    if(qlvl == 0) then
    elseif(qlvl == 1) then
      DrawCircle(myHero.x, myHero.y, myHero.z, 600, 0x111111)
    elseif(qlvl == 2) then
      DrawCircle(myHero.x, myHero.y, myHero.z, 625, 0x111111)
    elseif(qlvl == 3) then
      DrawCircle(myHero.x, myHero.y, myHero.z, 650, 0x111111)
    elseif(qlvl == 4) then
      DrawCircle(myHero.x, myHero.y, myHero.z, 675, 0x111111)
    elseif(qlvl == 5) then
      DrawCircle(myHero.x, myHero.y, myHero.z, 700, 0x111111)
    end
  end

  if(Config.settDraw.wrange) then
    DrawCircle(myHero.x, myHero.y, myHero.z, 1450, 0x111111)
  end

  if(Config.settDraw.erange) then
    DrawCircle(myHero.x, myHero.y, myHero.z, 900, 0x111111)
  end

  if Config.settDraw.wayp then
    for i=1, heroManager.iCount do
      local enemy = heroManager:getHero(i)

      if enemy.team ~= myHero.team and not enemy.dead then
        currentPred:DrawSavedWaypoints(enemy, 1)
      end
    end
  end

end

function prntChat(message)

  PrintChat("<font color=\"#0B6121\"><b>--Weed Jinx--</b></font> ".."<font color=\"#FFFFFF\"><b>"..message..".</b></font>")

end



local serveradress = "raw.githubusercontent.com"
local scriptadress = "/weedlions/WeedJinx/master"
local scriptname = "WeedJinx"
local adressfull = "http://"..serveradress..scriptadress.."/"..scriptname..".lua"
function CheckUpdates()
  local ServerVersionDATA = GetWebResult(serveradress , scriptadress.."/"..scriptname..".version")
  if ServerVersionDATA then
    local ServerVersion = tonumber(ServerVersionDATA)
    if ServerVersion then
      if ServerVersion > tonumber(Version) then
        prntChat("Updating, don't press F9")
        DownloadUpdate()
      else
        prntChat("You have the latest version")
      end
    else
      prntChat("An error occured, while updating")
    end
  else
    prntChat("Could not connect to update Server")
  end
end

function DownloadUpdate()
  DownloadFile(adressfull, SCRIPT_PATH..scriptname..".lua", function ()
    prntChat("Updated, press 2x F9")
  end)
end

function InitOrbs()
  if _G.Reborn_Loaded or _G.Reborn_Initialised or _G.AutoCarry ~= nil then
    table.insert(OrbWalkers, "SAC")
  end
  if _G.MMA_IsLoaded then
    table.insert(OrbWalkers, "MMA")
  end
  if _G._Pewalk then
    table.insert(OrbWalkers, "Pewalk")
  end
  if FileExist(LIB_PATH .. "/Nebelwolfi's Orb Walker.lua") then
    table.insert(OrbWalkers, "NOW")
  end
  if FileExist(LIB_PATH .. "/Big Fat Orbwalker.lua") then
    table.insert(OrbWalkers, "Big Fat Walk")
  end
  if FileExist(LIB_PATH .. "/SOW.lua") then
    table.insert(OrbWalkers, "SOW")
  end
  if FileExist(LIB_PATH .. "/SxOrbWalk.lua") then
    table.insert(OrbWalkers, "SxOrbWalk")
  end
  if #OrbWalkers > 0 then
    Config:addSubMenu("Orbwalkers", "Orbwalkers")
    Config:addSubMenu("Keys", "Keys")
    Config.Orbwalkers:addParam("Orbwalker", "OrbWalker", SCRIPT_PARAM_LIST, 1, OrbWalkers)
    Config.Keys:addParam("info", "Detecting keys from: "..OrbWalkers[Config.Orbwalkers.Orbwalker], SCRIPT_PARAM_INFO, "")
    local OrbAlr = false
    Config.Orbwalkers:setCallback("Orbwalker", function(value)
      if OrbAlr then return end
      OrbAlr = true
      Menu.Orbwalkers:addParam("info", "Press F9 2x to load your selected Orbwalker.", SCRIPT_PARAM_INFO, "")
      prntChat("Press F9 2x to load your selected Orbwalker")
    end)
  end
end

function LoadOrb()
  if OrbWalkers[Config.Orbwalkers.Orbwalker] == "SAC" then
    LoadedOrb = "Sac"
    TIMETOSACLOAD = false
    DelayAction(function() TIMETOSACLOAD = true end,15)
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "MMA" then
    LoadedOrb = "Mma"
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "Pewalk" then
    LoadedOrb = "Pewalk"
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "NOW" then
    LoadedOrb = "Now"
    require "Nebelwolfi's Orb Walker"
    _G.NOWi = NebelwolfisOrbWalkerClass()
    Config.Orbwalkers:addSubMenu("NOW", "NOW")
    _G.NebelwolfisOrbWalkerClass(Config.Orbwalkers.NOW)
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "Big Fat Walk" then
    LoadedOrb = "Big"
    require "Big Fat Orbwalker"
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "SOW" then
    LoadedOrb = "Sow"
    require "SOW"
    Config.Orbwalkers:addSubMenu("SOW", "SOW")
    _G.SOWi = SOW(_G.VP)
    SOW:LoadToMenu(Config.Orbwalkers.SOW)
  elseif OrbWalkers[Config.Orbwalkers.Orbwalker] == "SxOrbWalk" then
    LoadedOrb = "SxOrbWalk"
    require "SxOrbWalk"
    Config.Orbwalkers:addSubMenu("SxOrbWalk", "SxOrbWalk")
    SxOrb:LoadToMenu(Config.Orbwalkers.SxOrbWalk)
  end
end

function getMode()
  if LoadedOrb == "Sac" and TIMETOSACLOAD then
    if _G.AutoCarry.Keys.AutoCarry then return "Combo" end
    if _G.AutoCarry.Keys.MixedMode then return "Harass" end
    if _G.AutoCarry.Keys.LaneClear then return "Laneclear" end
    if _G.AutoCarry.Keys.LastHit then return "Lasthit" end
  elseif LoadedOrb == "Mma" then
    if _G.MMA_IsOrbwalking() then return "Combo" end
    if _G.MMA_IsDualCarrying() then return "Harass" end
    if _G.MMA_IsLaneClearing() then return "Laneclear" end
    if _G.MMA_IsLastHitting() then return "Lasthit" end
  elseif LoadedOrb == "Pewalk" then
    if _G._Pewalk.GetActiveMode().Carry then return "Combo" end
    if _G._Pewalk.GetActiveMode().Mixed then return "Harass" end
    if _G._Pewalk.GetActiveMode().LaneClear then return "Laneclear" end
    if _G._Pewalk.GetActiveMode().Farm then return "Lasthit" end
  elseif LoadedOrb == "Now" then
    if _G.NOWi.Config.k.Combo then return "Combo" end
    if _G.NOWi.Config.k.Harass then return "Harass" end
    if _G.NOWi.Config.k.LaneClear then return "Laneclear" end
    if _G.NOWi.Config.k.LastHit then return "Lasthit" end
  elseif LoadedOrb == "Big" then
    if _G["BigFatOrb_Mode"] == "Combo" then return "Combo" end
    if _G["BigFatOrb_Mode"] == "Harass" then return "Harass" end
    if _G["BigFatOrb_Mode"] == "LaneClear" then return "Laneclear" end
    if _G["BigFatOrb_Mode"] == "LastHit" then return "Lasthit" end
  elseif LoadedOrb == "Sow" then
    if _G.SOWi.Menu.Mode0 then return "Combo" end
    if _G.SOWi.Menu.Mode1 then return "Harass" end
    if _G.SOWi.Menu.Mode2 then return "Laneclear" end
    if _G.SOWi.Menu.Mode3 then return "Lasthit" end
  elseif LoadedOrb == "SxOrbWalk" then
    if _G.SxOrb.isFight then return "Combo" end
    if _G.SxOrb.isHarass then return "Harass" end
    if _G.SxOrb.isLaneClear then return "Laneclear" end
    if _G.SxOrb.isLastHit then return "Lasthit" end
  end
end