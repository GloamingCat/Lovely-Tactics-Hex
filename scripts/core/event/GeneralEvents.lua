
--[[===============================================================================================

General Events
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

=================================================================================================]]

local EventSheet = {}

---------------------------------------------------------------------------------------------------
-- Field
---------------------------------------------------------------------------------------------------

-- General parameters:
-- @param(args.fade : number) Duration of the fading in frames.
-- @param(args.fieldID : number) Field to loaded's ID.

-- Teleports player to other field.
-- @param(args.x : number) Player's destination x.
-- @param(args.y : number) Player's destination y.
-- @param(args.h : number) Player's destination height.
-- @param(args.direction : number) Player's destination direction (in degrees).
function EventSheet:moveToField(args)
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
-- Loads battle field.
-- @param(args.fieldID : boolean) Battle field ID (optional).
--  If nil, battle takes place in the current field.
-- @param(args.intro : boolean) Battle introduction animation.
-- @param(args.fade : boolean) Fade out/in effect when exiting/returning to previous field.
-- @param(args.escapeEnabled : boolean) True to enable the whole party to escape.
-- @param(args.gameOverCondition : number) GameOver condition:
--  0 => no gameover, 1 => only when lost, 2 => lost or draw.
function EventSheet:startBattle(args)
  args.gameOverCondition = args.gameOverCondition or 1
  if type(args.gameOverCondition) == 'string' then
    local conditionName = args.gameOverCondition:trim():lower()
    if conditionName == 'survive' then
      args.gameOverCondition = 2 -- Must win.
    elseif conditionName == 'kill' then
      args.gameOverCondition = 1 -- Must win or draw.
    elseif conditionName == 'none' then
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
-- Loads battle field.
-- @param(args.fade : boolean) Fade out/in effect when exiting/returning to previous field.
function EventSheet:finishBattle(args)
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

return EventSheet
