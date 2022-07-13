
--[[===============================================================================================

EventSheet Utilities
---------------------------------------------------------------------------------------------------
Functions that are loaded from the EventSheet.

=================================================================================================]]

-- Imports
local AIRule = require('core/battle/ai/AIRule')
local TagMap = require('core/datastruct/TagMap')

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
  if args.fade then
    if self.tile and self.tile ~= self.player:getTile() then
      self.root:fork(function()
        -- Character
        if self.player.autoTurn then
          self.player:turnToTile(self.tile.x, self.tile.y)
        end
        self.player:walkToTile(self.tile:coordinates())
      end)
    end
    FieldManager.renderer:fadeout(args.fade, true)
  end
  FieldManager:loadTransition(args)
  if args.fade then
    FieldManager.renderer:fadeout(0)
    FieldManager.renderer:fadein(args.fade)
  end
end

-- Loads battle field.
-- @param(args.fieldID : boolean) Battle field ID (optional).
--  If nil, battle takes place in the current field.
-- @param(args.intro : boolean) Battle introduction animation.
-- @param(args.resetOnEnd : boolean) Resets field state after battle ends.
-- @param(args.escapeEnabled : boolean) True to enable the whole party to escape.
-- @param(args.gameOverCondition : number) GameOver condition:
--  0 => no gameover, 1 => only when lost, 2 => lost or draw.
function EventSheet:startBattle(args)
  if self.char then
    self.char.vars.onBattle = true
  end
  BattleManager.params = args
  SaveManager.current = SaveManager:currentSaveData()
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

function EventSheet:finishBattle(args)
  if args.fade then
    FieldManager.renderer:fadein(args.fade, true)
  end
  if self.char then
    self.char.vars.onBattle = false
  end
end

return EventSheet
