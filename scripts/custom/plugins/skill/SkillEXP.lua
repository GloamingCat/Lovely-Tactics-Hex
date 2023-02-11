
--[[===============================================================================================

SkillEXP
---------------------------------------------------------------------------------------------------
Characters receive EXP for each action and can level-up mid-battle.

-- Plugin parameters:
<battleOnly> When true, characters will only receive EXP during a battle.
<expPopup> When true, a pop-up will show the gained EXP every time an action is executed.
<defaultExp> Default skill EXP when not defined.
<missExp> Multiplier for when the skill did not succeed.
<levelDiff> Aditional exp per level difference between user and target.
<enemyExp> When true enemies also receive experience.

=================================================================================================]]

-- Imports
local RewardGUI = require('core/gui/battle/RewardGUI')
local Inventory = require('core/battle/Inventory')
local SkillAction = require('core/battle/action/SkillAction')
local Character = require('core/objects/Character')
local PopupText = require('core/battle/PopupText')

-- Parameters
local battleOnly = args.battleOnly
local expPopup = args.expPopup
local defaultExp = args.defaultExp or 0
local missExp = args.missExp or 1
local levelDiff = args.levelDiff or 0
local enemyExp = args.enemyExp

---------------------------------------------------------------------------------------------------
-- RewardGUI
---------------------------------------------------------------------------------------------------

-- Removes EXP rewards for each enemy.
function RewardGUI:getBattleRewards()
  local r = { exp = {},
    items = Inventory(),
    money = 0 }
  -- List of living party members
  local characters = TroopManager:currentCharacters(self.troop.party, true)
  -- Rewards per troop
  for party, troop in pairs(TroopManager.troops) do
    if troop ~= self.troop then
      -- Troop EXP
      for char in characters:iterator() do
        r.exp[char.key] = (r.exp[char.key] or 0) + troop.data.exp
      end
      -- Troop items
      r.items:addAllItems(troop.inventory)
      -- Troop money
      r.money = r.money + troop.money
      for enemy in TroopManager:currentCharacters(party, false):iterator() do
        -- Enemy items
        r.items:addAllItems(enemy.battler.inventory)
        -- Enemy money
        r.money = r.money + enemy.battler.data.money
      end
    end
  end
  return r
end

---------------------------------------------------------------------------------------------------
-- SkillAction
---------------------------------------------------------------------------------------------------

-- Gets the EXP optained from the action.
function SkillAction:expGain(user, target, results)
  local gain = (self.tags.exp or defaultExp) + (target.job.level - user.job.level) * levelDiff
  if #results.points == 0 and #results.status == 0 then
    gain = gain * missExp
  elseif results.kill then
    gain = gain + target.data.exp
  end
  return gain
end
-- Override. Gives EXP if target if killed and user is from the player's party.
local SkillAction_allTargetsEffect = SkillAction.allTargetsEffect
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
      local popupText = PopupText(pos.x, pos.y - 10, FieldManager.renderer)
      popupText:addLine('+' .. tostring(maxGain) .. ' ' .. Vocab.exp, 'popup_exp', 'popup_exp')
      wait = popupText:popup()
    end
    input.user.battler.job:addExperience(maxGain)
    if nextLevel then
      _G.Fiber:wait(wait)
      local popupText = PopupText(pos.x, pos.y - 10, FieldManager.renderer)
      popupText:addLine('Level ' .. nextLevel .. '!', 'popup_levelup', 'popup_levelup')
      if Config.sounds.levelup then
        AudioManager:playSFX(Config.sounds.levelup)
      end
      popupText:popup()
    end
  end
  return allTargets
end
-- Override.
local SkillAction_menuTargetsEffect = SkillAction.menuTargetsEffect
function SkillAction:menuTargetsEffect(input, targets)
  if battleOnly then
    return SkillAction_menuTargetsEffect(self, input, targets)
  end
  local maxGain = 0
  local popupText = nil
  for i = 1, #targets do
    local results = self:calculateEffectResults(input.user, targets[i])
    popupText = self:singleTargetEffect(results, input, targets[i])
    if popupText and input.user ~= input.target then
      popupText:popup()
      popupText = nil
    end
    maxGain = math.max(maxGain, self:expGain(input.user, targets[i], results))
  end
  if maxGain > 0 then
    local nextLevel = input.user.job:levelsup(maxGain)
    if expPopup then
      popupText = popupText or PopupText(input.originX or 0, input.originY or 0, GUIManager.renderer)
      popupText:addLine('+' .. tostring(maxGain) .. ' ' .. Vocab.exp, 'popup_exp', 'popup_exp')
    end
    if nextLevel then
      popupText = popupText or PopupText(input.originX or 0, input.originY or 0, GUIManager.renderer)
      popupText:addLine('Level ' .. nextLevel .. '!', 'popup_levelup', 'popup_levelup')
      if Config.sounds.levelup then
        AudioManager:playSFX(Config.sounds.levelup)
      end
    end
    input.user.job:addExperience(maxGain)
    if popupText then
      popupText:popup()
    end
  end
end