
-- ================================================================================================

--- Characters receive EXP for each action and can level-up mid-battle.
---------------------------------------------------------------------------------------------------
-- @plugin SkillEXP

--- Plugin parameters.
-- @tags Plugin
-- @tfield boolean battleOnly Flag to make characters only receive EXP during a battle.
-- @tfield boolean expPopup Flag to show a pop-up with the gained EXP every time an action is executed.
-- @tfield number defaultExp Default skill EXP when not defined.
-- @tfield number missExp Multiplier for when the skill did not succeed.
-- @tfield number levelDiff Aditional exp per level difference between user and target.
-- @tfield boolean enemyExp Flag to make enemies also receive experience.

-- ================================================================================================

-- Imports
local BattleManager = require('core/battle/BattleManager')
local Inventory = require('core/battle/Inventory')
local SkillAction = require('core/battle/action/SkillAction')
local Character = require('core/objects/Character')
local PopText = require('core/graphics/PopText')

-- Rewrites
local SkillAction_allTargetsEffect = SkillAction.allTargetsEffect
local SkillAction_menuTargetsEffect = SkillAction.menuTargetsEffect

-- Parameters
local battleOnly = args.battleOnly
local expPopup = args.expPopup
local defaultExp = args.defaultExp or 0
local missExp = args.missExp or 1
local levelDiff = args.levelDiff or 0
local enemyExp = args.enemyExp

-- ------------------------------------------------------------------------------------------------
-- RewardMenu
-- ------------------------------------------------------------------------------------------------

--- Rewrites `BattleManager:getBattleRewards`. Removes EXP rewards for each enemy.
-- @rewrite
function BattleManager:getBattleRewards(winnerParty)
  local r = { exp = {},
    items = Inventory(),
    money = 0 }
  -- List of living party members
  local characters = TroopManager:currentCharacters(winnerParty, true)
  -- Rewards per troop
  for party, troop in pairs(TroopManager.troops) do
    if party ~= winnerParty then
      -- Troop EXP
      for char in characters:iterator() do
        r.exp[char.key] = (r.exp[char.key] or 0) + troop.data.exp
      end
      -- Troop items
      r.items:addAllItems(troop.inventory)
      -- Troop money
      r.money = r.money + troop.money
    end
  end
  -- Rewards per enemy
  for enemy in TroopManager:enemyBattlers(winnerParty, false):iterator() do
    -- Enemy items
    r.items:addAllItems(enemy.inventory)
    -- Enemy money
    r.money = r.money + enemy.data.money
  end
  return r
end

-- ------------------------------------------------------------------------------------------------
-- SkillAction
-- ------------------------------------------------------------------------------------------------

--- Gets the EXP optained from the action.
function SkillAction:expGain(user, target, results)
  local gain = (self.tags.exp or defaultExp) + (target.job.level - user.job.level) * levelDiff
  if #results.points == 0 and #results.status == 0 then
    gain = gain * missExp
  elseif results.kill then
    gain = gain + target.data.exp
  end
  return gain
end
--- Rewrites `SkillAction:allTargetsEffect`.
-- @rewrite
function SkillAction:allTargetsEffect(input, originTile)
  if not enemyExp and input.user.party ~= TroopManager.playerParty then
    return SkillAction_allTargetsEffect(self, input, originTile)
  end
  local allTargets = self:getAllAffectedTiles(input)
  local maxGain = 0
  for i = #allTargets, 1, -1 do
    for targetChar in allTargets[i].characterList:iterator() do
      local gain = self.tags.exp or defaultExp
      local results = self:calculateEffectResults(input.user.battler, targetChar.battler)
      self:singleTargetEffect(results, input, targetChar.battler, originTile)
      _G.Fiber:wait(self.targetTime)
      maxGain = math.max(maxGain, self:expGain(input.user.battler, targetChar.battler, results))
    end
  end
  local wait = 0
  if maxGain > 0 then
    local nextLevel = input.user.battler.job:levelsup(maxGain)
    local pos = input.user.position
    if expPopup then
      local popText = PopText(pos.x, pos.y - 10, FieldManager.renderer)
      popText:addLine('+' .. tostring(maxGain) .. ' ' .. Vocab.exp, 'popup_exp', 'popup_exp')
      wait = popText:popUp()
    end
    input.user.battler.job:addExperience(maxGain)
    if nextLevel then
      _G.Fiber:wait(wait)
      local popText = PopText(pos.x, pos.y - 10, FieldManager.renderer)
      popText:addLine('Level ' .. nextLevel .. '!', 'popup_levelup', 'popup_levelup')
      if Config.sounds.levelup then
        AudioManager:playSFX(Config.sounds.levelup)
      end
      popText:popUp()
    end
  end
  return allTargets
end
--- Rewrites `SkillAction:menuTargetsEffect`.
-- @rewrite
function SkillAction:menuTargetsEffect(input, targets)
  if battleOnly then
    return SkillAction_menuTargetsEffect(self, input, targets)
  end
  local maxGain = 0
  local popText = nil
  for i = 1, #targets do
    local results = self:calculateEffectResults(input.user, targets[i])
    popText = self:singleTargetEffect(results, input, targets[i])
    if popText and input.user ~= input.target then
      popText:popUp()
      popText = nil
    end
    maxGain = math.max(maxGain, self:expGain(input.user, targets[i], results))
  end
  if maxGain > 0 then
    local nextLevel = input.user.job:levelsup(maxGain)
    if expPopup then
      popText = popText or PopText(input.originX or 0, input.originY or 0, MenuManager.renderer)
      popText:addLine('+' .. tostring(maxGain) .. ' ' .. Vocab.exp, 'popup_exp', 'popup_exp')
    end
    if nextLevel then
      popText = popText or PopText(input.originX or 0, input.originY or 0, MenuManager.renderer)
      popText:addLine('Level ' .. nextLevel .. '!', 'popup_levelup', 'popup_levelup')
      if Config.sounds.levelup then
        AudioManager:playSFX(Config.sounds.levelup)
      end
    end
    input.user.job:addExperience(maxGain)
    if popText then
      popText:popUp()
    end
  end
end