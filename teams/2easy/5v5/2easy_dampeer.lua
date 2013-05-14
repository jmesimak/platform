local _G = getfenv(0)
local dampeer = _G.object

dampeer.heroName = "Hero_Dampeer"

runfile 'bots/core_herobot.lua'

local core, behaviorLib = dampeer.core, dampeer.behaviorLib

--huono buildi, paranna
behaviorLib.StartingItems  = {"2 Item_DuckBoots", "2 Item_MinorTotem", "Item_HealthPotion", "Item_RunesOfTheBlight"}
behaviorLib.LaneItems  = {"Item_Marchers", "Item_HelmOfTheVictim", "Item_Steamboots"}
behaviorLib.MidItems  = {"Item_Sicarius", "Item_WhisperingHelm", "Item_Immunity"}
behaviorLib.LateItems  = {"Item_ManaBurn2", "Item_LifeSteal4", "Item_Evasion"}


dampeer.skills = {
  2, 1, 2, 1, 2,
  3, 1, 1, 2, 0,
  3, 0, 0, 0, 4,
  3, 4, 4, 4, 4,
  4, 4, 4, 4, 4
}
local skills = dampeer.skills

local tinsert = _G.table.insert

function dampeer:SkillBuildOverride()
  local unitSelf = self.core.unitSelf
  if skills.abilDeny == nil then
    skills.abilScare = unitSelf:GetAbility(0)
    skills.abilFlight = unitSelf:GetAbility(1)
    skills.abilAura = unitSelf:GetAbility(2)
    skills.abilUltimate = unitSelf:GetAbility(3)
    skills.stats = unitSelf:GetAbility(4)
  end
  if unitSelf:GetAbilityPointsAvailable() <= 0 then
    return
  end
  if skills.abilUltimate:CanLevelUp() then
    skills.abilUltimate:LevelUp()
  elseif skills.abilAura:CanLevelUp() then
    skills.abilAura:LevelUp()
  elseif skills.abilScare:CanLevelUp() then
    skills.abilScare:LevelUp()
  elseif skills.abilFlight:CanLevelUp() then
    skills.abilFlight:LevelUp()
  else
    skills.stats:LevelUp()
  end
end
dampeer.SkillBuildOld = dampeer.SkillBuild
dampeer.SkillBuild = dampeer.SkillBuildOverride

------------------------------------------------------
--            onthink override                      --
-- Called every bot tick, custom onthink code here  --
------------------------------------------------------
-- @param: tGameVariables
-- @return: none
function dampeer:onthinkOverride(tGameVariables)
  self:onthinkOld(tGameVariables)

  -- custom code here
end
dampeer.onthinkOld = dampeer.onthink
dampeer.onthink = dampeer.onthinkOverride

----------------------------------------------
--            oncombatevent override        --
-- use to check for infilictors (fe. buffs) --
----------------------------------------------
-- @param: eventdata
-- @return: none
function dampeer:oncombateventOverride(EventData)
  self:oncombateventOld(EventData)

  -- custom code here
end
-- override combat event trigger function.
dampeer.oncombateventOld = dampeer.oncombatevent
dampeer.oncombatevent = dampeer.oncombateventOverride

local function CustomHarassUtilityFnOverride(hero)
  local nUtil = 0

  
  local unitSelf = core.unitSelf
  local manaP = unitSelf:GetManaPercent()
  local mana = unitSelf:GetMana()

  if skills.abilFlight:CanActivate() and ((manaP > 0.90) or (mana > 175)) then
    nUtil = nUtil + 30
    local damages = {50,90,130,170}
    if hero:GetHealth() < damages[skills.abilFlight:GetLevel()] then
      nUtil = nUtil + 30
    end
  end

  if skills.abilUltimate:CanActivate()  then
    nUtil = nUtil + 40
  end

  return nUtil
end
behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride

local function HarassHeroExecuteOverride(botBrain)

  local unitTarget = behaviorLib.heroTarget
  if unitTarget == nil then
    return dampeer.harassExecuteOld(botBrain)
  end

  local unitSelf = core.unitSelf
  local nTargetDistanceSq = Vector3.Distance2DSq(unitSelf:GetPosition(), unitTarget:GetPosition())

  local bActionTaken = false

  if core.CanSeeUnit(botBrain, unitTarget) then
    local abilStun = skills.abilStun

    if abilFlight:CanActivate() then
      local nRange = abilFlight:GetRange()
      if nTargetDistanceSq < (nRange * nRange) then
        bActionTaken = core.OrderAbilityEntity(botBrain, abilFlight, unitTarget)
      else
        bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
      end
    end

    local abilUltimate = skills.abilUltimate
    if not bActionTaken then
      if abilUltimate:CanActivate() then
        local nRange = abilUltimate:GetRange()
        if nTargetDistanceSq < (nRange * nRange) then
          bActionTaken = core.OrderAbilityEntity(botBrain, abilUltimate, unitTarget)
        else
          bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
        end
      end
    end
  end

  if not bActionTaken then
    return dampeer.harassExecuteOld(botBrain)
  end
end
andromeda.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride
