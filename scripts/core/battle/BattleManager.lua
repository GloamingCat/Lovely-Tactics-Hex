
--[[===============================================================================================

BattleManager
---------------------------------------------------------------------------------------------------
Controls battle flow (initializes troops, runs loop, checks victory and game over).
Parameters:
  gameOverCondition: 0 => no gameover, 1 => only when lost, 2 => lost or draw
  skipAnimations: for debugging purposes (skips battle/character animations)
  escapeEnabled: enable Escape action
Results: 1 => win, 0 => draw, -1 => lost

=================================================================================================]]

-- Imports
local Animation = require('core/graphics/Animation')
local GameOverGUI = require('core/gui/battle/GameOverGUI')
local IntroGUI = require('core/gui/battle/IntroGUI')
local Inventory = require('core/battle/Inventory')
local RewardGUI = require('core/gui/battle/RewardGUI')
local TileGUI = require('core/field/TileGUI')

-- Constants
local defaultParams = {
  fade = 60,
  intro = false,
  gameOverCondition = 0, 
  escapeEnabled = true }

local BattleManager = class()

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
function BattleManager:init()
  self.onBattle = false
  self.params = defaultParams
end
-- Creates battle elements (GUI, characters, party tiles).
-- @param(state : table) Data about battle state for when the game is loaded mid-battle (optional).
function BattleManager:setUp(state)
  TroopManager:setPartyTiles(self.currentField)
  for tile in FieldManager.currentField:gridIterator() do
    tile.gui = TileGUI(tile, true, true)
  end
  TroopManager:createTroops(state and state.troops)
  TurnManager:setUp(state and state.turn)
end
-- Gets the current battle state to save the game mid-battle.
-- @ret(table) Battle state data.
function BattleManager:getState()
  return {
    params = self.params,
    troops = TroopManager:getAllPartyData(),
    turn = TurnManager:getState()
  }
end

---------------------------------------------------------------------------------------------------
-- Battle Loop
---------------------------------------------------------------------------------------------------

-- Loads a battle field and waits for the battle to finish.
-- It MUST be called from a fiber in FieldManager's fiber list, or else the fiber will be 
-- lost in the field transition. At the end of the battle, it reloads the previous field.
-- @param(state : table) Data about battle state for when the game is loaded mid-battle (optional).
function BattleManager:loadBattle(state)
  self.saveData = state
  TroopManager:reset()
  FieldManager:loadField(self.params.fieldID or self.currentField.id)
  -- Run battle
  while true do
    FieldManager:playFieldBGM()
    self:setUp(self.saveData)
    local result = self:runBattle(self.saveData and self.saveData.turn ~= nil)
    self:clear()
    if result == 1 then -- Continue
      break
    elseif result == 2 then -- Retry
      FieldManager:loadField(self.params.fieldID or self.currentField.id)
      self.saveData = nil
    elseif result == 3 then -- Title Screen
      GameManager.restartRequested = true
      return
    end
  end
  self.saveData = nil
  FieldManager:loadTransition(FieldManager.playerState.transition, FieldManager.playerState.field)
end
-- Runs until battle finishes.
-- @ret(number) The result of the end GUI.
function BattleManager:runBattle(skipIntro)
  self.result = nil
  self.winner = nil
  self:battleStart(skipIntro)
  if not skipIntro then
    GUIManager:showGUIForResult(IntroGUI(nil))
    TroopManager:onBattleStart()
  end
  repeat
    self.result, self.winner = TurnManager:runTurn(skipIntro)
    skipIntro = false
  until self.result
  return self:battleEnd()
end
-- Runs before battle loop.
function BattleManager:battleStart(skipIntro)
  self.onBattle = true
  if self.params.fade then
    FieldManager.renderer:fadeout(0)
    FieldManager.renderer:fadein(self.params.fade, true)
  end
  if skipIntro then
    return
  end
  if self.params.intro then
    self:battleIntro()
  end
  FieldManager:runLoadScripts()
end
-- Player intro animation, to show each party.
function BattleManager:battleIntro()
  local speed = 50
  for i = 1, #TroopManager.centers do
    if i ~= TroopManager.playerParty then
      local p = TroopManager.centers[i]
      FieldManager.renderer:moveToPoint(p.x, p.y, speed, true)
      _G.Fiber:wait(30)
    end
  end
  local p = TroopManager.centers[TroopManager.playerParty]
  FieldManager.renderer:moveToPoint(p.x, p.y, speed, true)
  _G.Fiber:wait(15)
end
-- Runs after winner was determined and battle loop ends.
-- @ret(number) The result code: 1 -> continue; 2 -> retry; 3 -> title screen.
function BattleManager:battleEnd()
  local result = 1
  if self:playerWon() then
    GUIManager:showGUIForResult(RewardGUI(nil))
  elseif self:enemyWon() or self:drawed() then
    result = GUIManager:showGUIForResult(GameOverGUI(nil))
  end
  TroopManager:onBattleEnd()
  if result <= 1 then
    TroopManager:saveTroops()
  end
  if self.params.fade then
    FieldManager.renderer:fadeout(self.params.fade, true)
  end
  self.onBattle = false
  return result
end
-- Clears batte information from characters and field.
function BattleManager:clear()
  for tile in FieldManager.currentField:gridIterator() do
    tile.gui:destroy()
    tile.gui = nil
  end
  if self.cursor then
    self.cursor:destroy()
  end
  TroopManager:clear()
end

---------------------------------------------------------------------------------------------------
-- Battle results
---------------------------------------------------------------------------------------------------

-- @ret(boolean) Whether the player party won the battle.
function BattleManager:playerWon()
  return self.result > 0
end
-- @ret(boolean) Whether the player party escaped.
function BattleManager:playerEscaped()
  return self.result == -2
end
-- @ret(boolean) Whether the enemy party won battle.
function BattleManager:enemyWon()
  return self.result == -1
end
-- @ret(boolean) Whether the enemy party escaped.
function BattleManager:enemyEscaped()
  return self.result == 2
end
-- @ret(boolean) Whether both parties lost.
function BattleManager:drawed()
  return self.result == 0
end
-- Checks if the player received a game over.
function BattleManager:isGameOver()
  if self:drawed() then
    return self.params.gameOverCondition >= 2
  elseif self:enemyWon() then
    return self.params.gameOverCondition >= 1
  else
    return false
  end
end

---------------------------------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------------------------------

-- Creates a table of reward from the current state of the battle field.
-- @ret(table) Table with exp per battler, items and money.
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
    -- Enemy EXP
    for char in characters:iterator() do
      r.exp[char.key] = (r.exp[char.key] or 0) + enemy.data.exp
    end
    -- Enemy items
    r.items:addAllItems(enemy.inventory)
    -- Enemy money
    r.money = r.money + enemy.data.money
  end
  return r
end

return BattleManager
