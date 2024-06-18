
-- ================================================================================================

--- General event functions that are loaded from the EventSheet.
---------------------------------------------------------------------------------------------------
-- @module GeneralEvents

-- ================================================================================================

local GeneralEvents = {}

-- ------------------------------------------------------------------------------------------------
-- Tables
-- ------------------------------------------------------------------------------------------------

--- Arguments for variable controlling.
-- @table VariableAguments
-- @tfield string key The key of the variable.
-- @tfield number VarScope The scope of the variable (global/local/object).
-- @field value The new value of the variable.

--- Arguments for field transition.
-- @table TransitionArguments
-- @tfield[opt] number fieldID Field to loaded's ID. When nil, stays in the same field.
-- @tfield number fade Duration of the fading in frames.
-- @tfield number x Player's destination x.
-- @tfield number y Player's destination y.
-- @tfield number h Player's destination height.
-- @tfield number direction Player's destination direction (in degrees).

--- Arguments for battle commands.
-- @table BattleArguments
-- @tfield[opt] boolean fieldID Battle field ID. If nil, the battle takes place in the current field.
-- @tfield[opt] number fade Duration of the fade out/in effect when exiting/returning to previous field.
-- @tfield[opt] boolean skipIntro Flag to skip the intro animation showing the parties.
-- @tfield[opt] boolean disableEscape Flag to disable the escape action for the player.
-- @tfield[opt=NONE] GameOverCondition|VictoryCondition gameOverCondition The condition to block the
--  "Continue" option from the Game Over screen. Either a number value from
--  `BattleManager.GameOverCondition` or a string value from `VictoryCondition`.

--- The conditions to enable the "Continue" button on the `GameOverWindow`.
-- @enum VictoryCondition
-- @field none Always enabled regardless of who wins.
-- @field survive Enabled as long as the player is still alive.
-- @field kill Never enabled.
GeneralEvents.VictoryCondition = {
  NONE = 'none',
  SURVIVE = 'survive',
  KILL = 'kill'
}

--- Types of scope for script variables.
-- @enum VarScope
-- @field global Global variables.
-- @field script Variables that are only accessible within the same script.
-- @field object Variables associated with the script's object/character.
GeneralEvents.VarScope = {
  global = 0,
  script = 1,
  object = 2,
  field = 3
}

-- ------------------------------------------------------------------------------------------------
-- Variable
-- ------------------------------------------------------------------------------------------------

--- Sets the value of a variable.
-- @tparam VariableArguments args
function GeneralEvents:setVariable(args)
  local scope = self.VarScope[args.scope] or args.scope
  if scope == self.VarScope.global then
    scope = GameManager
  elseif scope == self.VarScope.script then
    scope = self
  elseif scope == self.VarScope.field then
    scope = FieldManager.currentField
  elseif self.char then
    scope = self.char
  else
    return
  end
  scope.vars[args.key] = args.value
end
--- Sets the value of a local (script) variable.
-- @tparam VariableArguments args
function GeneralEvents:setLocalVar(args)
  self.vars[args.key] = args.value
end
--- Sets the value of a global variable.
-- @tparam VariableArguments args
function GeneralEvents:setGlobalVar(args)
  GameManager.vars[args.key] = args.value
end
--- Sets the value of a global variable.
-- @tparam VariableArguments args
function GeneralEvents:setFieldVar(args)
  FieldManager.currentField.vars[args.key] = args.value
end
--- Sets the value of a global variable.
-- @tparam VariableArguments args
function GeneralEvents:setCharVar(args)
  assert(self.char, "Script was not called from a character")
  self.char.vars[args.key] = args.value
end

-- ------------------------------------------------------------------------------------------------
-- Field
-- ------------------------------------------------------------------------------------------------

--- Teleports player to other field.
-- @tparam TransitionArguments args
function GeneralEvents:moveToField(args)
  FieldManager.playerInput = false
  if args.fade then
    if self.char.tile and self.char.tile ~= FieldManager.player:getTile() then
      FieldManager.player.fiberList:fork(function()
        -- Character
        if FieldManager.player.autoTurn then
          FieldManager.player:turnToTile(self.char.tile.x, self.char.tile.y)
        end
        FieldManager.player:playMoveAnimation()
        FieldManager.player:walkToTile(self.char.tile:coordinates())
      end)
    end
    FieldManager.renderer:fadeout(args.fade, true)
  end
  FieldManager:loadTransition(args)
  FieldManager.playerInput = true
end
--- Loads battle field.
-- @tparam BattleArguments args
function GeneralEvents:startBattle(args)
  args.gameOverCondition = args.gameOverCondition or 1
  if type(args.gameOverCondition) == 'string' then
    local conditionName = args.gameOverCondition:trim():lower()
    if conditionName == self.VictoryCondition.SURVIVE then
      args.gameOverCondition = BattleManager.GameOverCondition.NOWIN -- Must win.
    elseif conditionName == self.VictoryCondition.KILL then
      args.gameOverCondition = 1 -- Must win or draw.
    elseif conditionName == self.VictoryCondition.NONE then
      args.gameOverCondition = 0 -- Never gets a game over.
    else
      args.gameOverCondition = 1 -- Default.
    end
  end
  self.vars.hudOpen = FieldManager.hud.visible
  FieldManager.currentField.vars.onBattle = true
  if self.char then
    self.char.vars.onBattle = true
  end
  self.vars.onBattle = true
  FieldManager.hud:hide()
  BattleManager.params = args
  FieldManager:storePlayerState()
  -- Openning
  if Config.sounds.battleIntro then
    AudioManager:playSFX(Config.sounds.battleIntro)
  end
  if args.fade then
    FieldManager.renderer:fadeout(args.fade, true)
  end
  local fiber = FieldManager.fiberList:fork(BattleManager.loadBattle, BattleManager)
  fiber:waitForEnd()
end
--- Loads battle field.
-- @tparam BattleArguments args
function GeneralEvents:finishBattle(args)
  if BattleManager:playerEscaped() then
    self.battleLog = 'You escaped!'
  elseif BattleManager:enemyEscaped() then
    self.battleLog = 'The enemy escaped...'
  elseif BattleManager:enemyWon() then
    assert(BattleManager.params.gameOverCondition < 2, "Player shouldn't have the option to continue.")
    self.battleLog = 'You lost...'
  elseif BattleManager:drawed() then
    assert(BattleManager.params.gameOverCondition < 1, "Player shouldn't have the option to continue.")
    self.battleLog = 'Draw.'
  elseif BattleManager:playerWon() then
    self.battleLog = 'You won!'
  end
  if args.fade then
    FieldManager.renderer:fadein(args.fade, args.wait)
  end
  if self.vars.hudOpen then
    FieldManager.hud:show()
  end
  self.vars.onBattle = nil
  if self.char then
    self.char.vars.onBattle = nil
  end
  FieldManager.currentField.vars.onBattle = false
end

return GeneralEvents
