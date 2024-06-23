
-- ================================================================================================

--- Controls battle flow.
-- It initializes troops, runs loop, checks victory and game over.
-- Dependencies: `TurnManager`, `TroopManager`, `IntroMenu`,  `GameOverMenu`, `RewardMenu`, `Inventory`
---------------------------------------------------------------------------------------------------
-- @manager BattleManager

-- ================================================================================================

-- Imports
local GameOverMenu = require('core/gui/battle/GameOverMenu')
local IntroMenu = require('core/gui/battle/IntroMenu')
local Inventory = require('core/battle/Inventory')
local RewardMenu = require('core/gui/battle/RewardMenu')

-- Class table.
local BattleManager = class()

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Result codes.
-- @enum GameOverCondition
-- @field NONE Code for no game over, regardless of battle result. Equals to 0.
-- @field LOSE Code for game over when the player party loses. Equals to 1.
-- @field NOWIN Code for game over when the player party loses or there's a draw. Equals to 2.
BattleManager.GameOverCondition = {
  NONE = 0,
  LOSE = 1,
  NOWIN = 2
}
--- Options for when the player loses.
-- @enum PostDefeatChoice
-- @field CONTINUE Continue the game after defeat (only if defeat is allowed). Equals to 1.
-- @field LOSE Return to pre-battle state and start battle again. Equals to 2.
-- @field EXIT Return to title screen. Equals to 3.
BattleManager.PostDefeatChoice = {
  CONTINUE = 1,
  RETRY = 2,
  EXIT = 3
}

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function BattleManager:init()
  self.onBattle = false
  self.defaultParams = {
    fade = 60,
    skipIntro = true,
    disableEscape = false,
    gameOverCondition = self.GameOverCondition.NONE, 
  }
  self.params = self.defaultParams
end
--- Creates battle elements (Menu, characters, party tiles).
-- @tparam[opt] table state Data about battle state for when the game is loaded mid-battle.
function BattleManager:setUp(state)
  TroopManager:setPartyTiles(self.currentField)
  for tile in FieldManager.currentField:gridIterator() do
    tile:initializeUI()
  end
  TroopManager:createTroops(state and state.troops)
  TurnManager:setUp(state and state.turn)
end
--- Gets the current battle state to save the game mid-battle.
-- @treturn table Battle state data.
function BattleManager:getState()
  return {
    params = self.params,
    troops = TroopManager:getAllPartyData(),
    turn = TurnManager:getState() }
end

-- ------------------------------------------------------------------------------------------------
-- Battle Loop
-- ------------------------------------------------------------------------------------------------

--- Loads a battle field and waits for the battle to finish.
-- It MUST be called from a fiber in FieldManager's fiber list, or else the fiber will be 
-- lost in the field transition. At the end of the battle, it reloads the previous field.
-- @coroutine
-- @tparam[opt] table state Data about battle state for when the game is loaded mid-battle.
function BattleManager:loadBattle(state)
  assert(not self.battleFiber, "Two battle instances running at once.")
  self.battleFiber = _G.Fiber
  self.saveData = state
  TroopManager:reset()
  FieldManager:loadField(self.params.fieldID or self.currentField.id)
  -- Run battle
  while true do
    FieldManager:playFieldBGM()
    self:setUp(self.saveData)
    local result = self:runBattle(self.saveData and self.saveData.turn ~= nil)
    self:clear()
    if result == self.PostDefeatChoice.CONTINUE then
      break
    elseif result == self.PostDefeatChoice.RETRY then
      FieldManager:loadField(self.params.fieldID or self.currentField.id)
      self.saveData = nil
    elseif result == self.PostDefeatChoice.EXIT then
      GameManager.restartRequested = true
      return
    end
  end
  self.saveData = nil
  FieldManager:loadTransition(FieldManager.playerState.transition, FieldManager.playerState.field)
  self.battleFiber = nil
end
--- Runs until battle finishes.
-- @coroutine
-- @tparam boolean skipIntro If true, the camera does not present the parties
--  and the field's load scripts are not executed.
-- @treturn number The result of the end Menu.
function BattleManager:runBattle(skipIntro)
  self.result = nil
  self.winner = nil
  self:battleStart(skipIntro)
  if not skipIntro then
    MenuManager:showMenuForResult(IntroMenu(nil))
    TroopManager:onBattleStart()
  end
  repeat
    self.result, self.winner = TurnManager:runTurn(skipIntro)
    skipIntro = false
  until self.result
  return self:battleEnd()
end
--- Runs before battle loop.
-- @coroutine
-- @tparam boolean skipIntro If true, the camera does not present the parties
--  and the field's load scripts are not executed.
function BattleManager:battleStart(skipIntro)
  self.onBattle = true
  if self.params.fade then
    FieldManager.renderer:fadeout(0)
    FieldManager.renderer:fadein(self.params.fade, true)
  end
  if skipIntro then
    return
  end
  if not self.params.skipIntro then
    self:battleIntro()
  end
  FieldManager:runLoadScripts()
end
--- Player intro animation, to show each party.
-- @coroutine
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
--- Runs after winner was determined and battle loop ends.
-- @coroutine
-- @treturn PostDefeatChoice The code dictating what to do next.
function BattleManager:battleEnd()
  local result = 1
  if self:playerWon() then
    MenuManager:showMenuForResult(RewardMenu(nil))
  elseif self:enemyWon() or self:drawed() then
    result = MenuManager:showMenuForResult(GameOverMenu(nil))
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
--- Clears batte information from characters and field.
function BattleManager:clear()
  for tile in FieldManager.currentField:gridIterator() do
    tile.ui:destroy()
    tile.ui = nil
  end
  if self.cursor then
    self.cursor:destroy()
  end
  TroopManager:clear()
end

-- ------------------------------------------------------------------------------------------------
-- Battle results
-- ------------------------------------------------------------------------------------------------

--- Whether the player party won the battle.
-- @treturn boolean Whether the player party won the battle.
function BattleManager:playerWon()
  return self.result >= TurnManager.BattleResult.WIN 
end
--- Whether the player party escaped.
-- @treturn boolean Whether the player party escaped.
function BattleManager:playerEscaped()
  return self.result == TurnManager.BattleResult.ESCAPE
end
--- Whether the enemy party won battle.
-- @treturn boolean Whether the enemy party won battle.
function BattleManager:enemyWon()
  return self.result == TurnManager.BattleResult.LOSE
end
--- Whether the enemy party escaped.
-- @treturn boolean Whether the enemy party escaped.
function BattleManager:enemyEscaped()
  return self.result == TurnManager.BattleResult.WALKOVER
end
--- Whether both parties lost.
-- @treturn boolean Whether both parties lost.
function BattleManager:drawed()
  return self.result == TurnManager.BattleResult.DRAW
end
--- Checks if the player received a game over or is allowed to continue,
-- according to the battle's game over conditions.
-- @treturn boolean True if the player must retry, false if it's possible to continue.
function BattleManager:isGameOver()
  if self:drawed() then
    return self.params.gameOverCondition >= self.GameOverCondition.NOWIN
  elseif self:enemyWon() then
    return self.params.gameOverCondition >= self.GameOverCondition.LOSE
  else
    return false
  end
end

-- ------------------------------------------------------------------------------------------------
-- Rewards
-- ------------------------------------------------------------------------------------------------

--- Creates a table of reward from the current state of the battle field.
-- @tparam number winnerParty The ID of the party to get the rewards for.
-- @treturn table Table with exp per battler, items and money.
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
