require "UOL"
local ts, ts2
local minman
local jinxq, jinxqtrue = false -- 0 = MG, 1 = RL
local myHero = GetMyHero()
local predTable = {"None"}
local currentPred = nil
local qlvl = 0
local q0,q1,q2,q3,q4,q5 = false
local healactive = false
local Version = 0.3
local Heal, Barrier = nil

if myHero.charName ~= "Jinx" then return end
if not FileExist(LIB_PATH .. "/VPrediction.lua") then PrintChat("<font color=\"0B6121\"><b>--Weed Jinx--</b></font> ".."<font color=\"#FFFFFF\"><b>Missing lib: VPrediction.</b></font>") return end

function OnLoad()

  minman = minionManager(MINION_ALL, 800)

  if(myHero.charName == "Jinx") then
    prntChat("Welcome to Weed Jinx. Good Luck, Have Fun!")
    prntChat("Version "..Version.." loaded.")
  end

  ts = TargetSelector(TARGET_LESS_CAST,1600)
  ts2 = TargetSelector(TARGET_LESS_CAST,800)

  initMenu()
  initSumms()

  require "VPrediction"
  currentPred = VPrediction()

  CheckUpdates()

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
  Config.settLC:addParam("rocket", "Use Rocket Launcher", SCRIPT_PARAM_ONOFF, true)
  Config.settLC:addParam("count", "X Minions to use Rocket Launcher", SCRIPT_PARAM_SLICE, 1, 1, 10, 0)

  Config:addSubMenu("Lasthit Settings", "settLH")
  Config.settLH:addParam("minigun", "Switch to Minigun on Lasthit", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Killsteal Settings", "settSteal")
  Config.settSteal:addParam("usew", "Use W for Killsteal", SCRIPT_PARAM_ONOFF, true)
  Config.settSteal:addParam("user", "Use R for Killsteal", SCRIPT_PARAM_ONOFF, true)
  Config.settSteal:addParam("range", "Max Range for R Steal", SCRIPT_PARAM_SLICE, 500, 0, 5000, 0)

  Config:addSubMenu("Draw Settings", "settDraw")
  Config.settDraw:addParam("qrange", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
  Config.settDraw:addParam("wrange", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
  Config.settDraw:addParam("erange", "Draw E Range", SCRIPT_PARAM_ONOFF, true)

  Config:addSubMenu("Auto Potion Settings", "settPot")
  Config.settPot:addParam("active", "Use Auto Potion", SCRIPT_PARAM_ONOFF, true)
  Config.settPot:addParam("hp", "Min % HP to Activate", SCRIPT_PARAM_SLICE, 60, 0, 100, 0)

  Config:addSubMenu("Auto Heal/Auto Barrier Settings", "settAHeal")
  Config.settAHeal:addParam("active", "Use Auto Heal/Barrier", SCRIPT_PARAM_ONOFF, true)
  Config.settAHeal:addParam("hp", "Use on X % HP", SCRIPT_PARAM_SLICE, 20, 0, 100, 0)

  Config:addSubMenu("HitChance Settings", "settHit")
  Config.settHit:addParam("Blank", "HitChance for E", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("whit", "Recommended = 2", SCRIPT_PARAM_SLICE, 2, 2, 4, 0)
  Config.settHit:addParam("Blank", "HitChance for E", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("ehit", "Recommended = 4", SCRIPT_PARAM_SLICE, 4, 2, 4, 0)
  Config.settHit:addParam("Blank", "HitChance for R", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("rhit", "Recommended = 2", SCRIPT_PARAM_SLICE, 2, 2, 4, 0)
  Config.settHit:addParam("Blank", "", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "Explanation", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "2 = High Hitchance", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "3 = Slowed Targets (~100%)", SCRIPT_PARAM_INFO, "")
  Config.settHit:addParam("Blank", "4 = Immobile Targets (~100%)", SCRIPT_PARAM_INFO, "")

  Config:addSubMenu("Key Settings", "settKey")
  Config.settKey:addParam("Blank", "Use Orbwalker Keys", SCRIPT_PARAM_INFO, "")

  UOL:AddToMenu(scriptConfig("OrbWalker", "OrbWalker"))

end

function OnTick()

  if myHero.dead then return end

  ts:update()
  ts2:update()
  minman:update()

  if(UOL:GetOrbWalkMode() == "LaneClear") then onLaneClear() end

  if(UOL:GetOrbWalkMode() == "LastHit") then onLastHit() end

  if(UOL:GetOrbWalkMode() == "Combo") then onCombo() end

  if(UOL:GetOrbWalkMode() == "Harass") then onHarass() end

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

      if enemy.team ~= myHero.team and not enemy.dead and myHero:CanUseSpell(_W) == READY and enemy.health < (getDmg("W", enemy, myHero) - 10) and enemy.bTargetable then
        local CastPosition = predict(enemy, "W")
        if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
      end
    end
  end

  if Config.settSteal.user then
    for i=1, heroManager.iCount do
      local enemy = heroManager:getHero(i)
      if enemy.team ~= myHero.team and not enemy.dead and myHero:CanUseSpell(_R) == READY and enemy.health < (getDmg("R", enemy, myHero) - 10) and enemy.bTargetable then
        local CastPosition = predict(enemy, "R")
        if(CastPosition ~= nil) then CastSpell(_R, CastPosition.x, CastPosition.z) end
      end
    end
  end

end

function tsUpdate()

  if qlvl == 0 and not q0 then
    ts2 = TargetSelector(TARGET_LESS_CAST,625)
    minman = minionManager(MINION_ALL, 625)
    q0 = true
  elseif qlvl == 1 and not q1 then
    ts2 = TargetSelector(TARGET_LESS_CAST,700)
    minman = minionManager(MINION_ALL, 700)
    q1 = true
  elseif qlvl == 2 and not q2 then
    ts2 = TargetSelector(TARGET_LESS_CAST,725)
    minman = minionManager(MINION_ALL, 725)
    q2 = true
  elseif qlvl == 3 and not q3 then
    ts2 = TargetSelector(TARGET_LESS_CAST,750)
    minman = minionManager(MINION_ALL, 750)
    q3 = true
  elseif qlvl == 4 and not q4 then
    ts2 = TargetSelector(TARGET_LESS_CAST,775)
    minman = minionManager(MINION_ALL, 775)
    q4 = true
  elseif qlvl == 5 and not q5 then
    ts2 = TargetSelector(TARGET_LESS_CAST,800)
    minman = minionManager(MINION_ALL, 800)
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

    if count > Config.settLC.count and not jinxq then CastSpell(_Q)
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

  if enemy == nil then return end

  if enemy.team == myHero.team and not enemy.bTargetable and not enemy.visible and enemy.dead then return end

  if Config.settHar.useq and myHero:CanUseSpell(_Q) then
    if GetDistance(enemy.pos) > 525 then
      if(qlvl == 0) then
      elseif(qlvl == 1) then
        if GetDistance(enemy.pos) < 600 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 600 and jinxq then CastSpell(_Q) end
      elseif(qlvl == 2) then
        if GetDistance(enemy.pos) < 625 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 625 and jinxq then CastSpell(_Q) end
      elseif(qlvl == 3) then
        if GetDistance(enemy.pos) < 650 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 650 and jinxq then CastSpell(_Q) end
      elseif(qlvl == 4) then
        if GetDistance(enemy.pos) < 675 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 675 and jinxq then CastSpell(_Q) end
      elseif(qlvl == 5) then
        if GetDistance(enemy.pos) < 700 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 700 and jinxq then CastSpell(_Q) end
      end
    elseif GetDistance(enemy.pos) < 525 then
      if jinxq then CastSpell(_Q) end
    end
  end

  if Config.settHar.usew and myHero:CanUseSpell(_W)then
    if Config.settHar.usewaa then
      if(qlvl == 0) then
      elseif(qlvl == 1) then
        if GetDistance(enemy.pos) > 600 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      elseif(qlvl == 2) then
        if GetDistance(enemy.pos) > 625 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      elseif(qlvl == 3) then
        if GetDistance(enemy.pos) > 650 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      elseif(qlvl == 4) then
        if GetDistance(enemy.pos) > 675 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      elseif(qlvl == 5) then
        if GetDistance(enemy.pos) > 700 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      end
    else
      local CastPosition = predict(enemy, "W")
      if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
    end
  end

  if Config.settHar.usee and myHero:CanUseSpell(_E) then
    local CastPosition = predict(enemy, "E")
    if(CastPosition ~= nil) then CastSpell(_E, CastPosition.x, CastPosition.z) end
  end

end

function onCombo()

  local enemy = GetTarget()

  if enemy == nil then return end

  if enemy.team == myHero.team and not enemy.bTargetable and not enemy.visible and enemy.dead then return end

  if Config.settComb.useq and myHero:CanUseSpell(_Q) then
    if GetDistance(enemy.pos) > 525 then
      if(qlvl == 0) then
      elseif(qlvl == 1) then
        if GetDistance(enemy.pos) < 600 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 600 and jinxq then CastSpell(_Q) end
      elseif(qlvl == 2) then
        if GetDistance(enemy.pos) < 625 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 625 and jinxq then CastSpell(_Q) end
      elseif(qlvl == 3) then
        if GetDistance(enemy.pos) < 650 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 650 and jinxq then CastSpell(_Q) end
      elseif(qlvl == 4) then
        if GetDistance(enemy.pos) < 675 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 675 and jinxq then CastSpell(_Q) end
      elseif(qlvl == 5) then
        if GetDistance(enemy.pos) < 700 and not jinxq then CastSpell(_Q)
        elseif GetDistance(enemy.pos) > 700 and jinxq then CastSpell(_Q) end
      end
    elseif GetDistance(enemy.pos) < 525 then
      if jinxq then CastSpell(_Q) end
    end
  end

  if Config.settComb.usew and myHero:CanUseSpell(_W)then
    if Config.settComb.usewaa then
      if(qlvl == 0) then
      elseif(qlvl == 1) then
        if GetDistance(enemy.pos) > 600 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      elseif(qlvl == 2) then
        if GetDistance(enemy.pos) > 625 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      elseif(qlvl == 3) then
        if GetDistance(enemy.pos) > 650 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      elseif(qlvl == 4) then
        if GetDistance(enemy.pos) > 675 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      elseif(qlvl == 5) then
        if GetDistance(enemy.pos) > 700 then
          local CastPosition = predict(enemy, "W")
          if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
        end
      end
    else
      local CastPosition = predict(enemy, "W")
      if(CastPosition ~= nil) then CastSpell(_W, CastPosition.x, CastPosition.z) end
    end
  end

  if Config.settComb.usee and myHero:CanUseSpell(_E) then
    local CastPosition = predict(enemy, "E")
    if(CastPosition ~= nil) then CastSpell(_E, CastPosition.x, CastPosition.z) end
  end

end

function GetTarget()
  if UOL:GetTarget() ~= nil and UOL:GetTarget().type == myHero.type then return UOL:GetTarget() end

  ts:update()
  if ts2.target and not ts2.target.dead and ts2.target.type == myHero.type then
    return ts2.target
  else
    return nil
  end
end

function GetWTarget()
  if UOL:GetTarget() ~= nil and UOL:GetTarget().type == myHero.type then return UOL:GetTarget() end

  ts:update()
  if ts.target and not ts.target.dead and ts.target.type == myHero.type then
    return ts.target
  else
    return nil
  end
end

function predict(target, spell)

  if(spell == "W") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.75, 50, 1440, 2000, myHero, true)
    if CastPosition and HitChance >= Config.settHit.ehit and GetDistance(CastPosition) < 1440 then
      return CastPosition
    end
  elseif(spell == "E") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.35, 50  , 900, 1500, myHero, false)
    if CastPosition and HitChance >= Config.settHit.ehit and GetDistance(CastPosition) < 890 then
      return CastPosition
    end
  elseif(spell == "R") then
    local CastPosition, HitChance, Position = currentPred:GetLineCastPosition(target, 0.55, 150, math.huge, 1500, myHero, true)
    if CastPosition and HitChance >= Config.settHit.rhit and GetDistance(CastPosition) < Config.settSteal.range then
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
  
  DrawTextA(qlvl,12,20,20*1+20)

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