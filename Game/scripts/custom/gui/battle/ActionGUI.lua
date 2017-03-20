
local Callback = require('core/callback/Callback')
local Vector = require('core/math/Vector')
local Animation = require('core/graphics/Animation')
local GUI = require('core/gui/GUI')
local TurnWindow = require('custom/gui/battle/TurnWindow')
local StepWindow = require('custom/gui/battle/StepWindow')
local BattleCursor = require('core/battle/BattleCursor')

--[[===========================================================================

The GUI that is open when player selects an action.
It does not have windows, and instead it implements its own "waitForResult" 
and "checkInput" methods.

=============================================================================]]

local ActionGUI = GUI:inherit()

-- Overrides GUI:createWindows.
function ActionGUI:createWindows()
  self.name = 'Action GUI'
  self.cursor = BattleCursor()
  self.action = BattleManager.currentAction
end

-- [COROUTINE] Overrides GUI:waitForResult.
function ActionGUI:waitForResult()
  self.action:onActionGUI(self)
  self:checkInput()
  while self.result == nil do
    if self.cursor then
      self.cursor:update()
    end
    coroutine.yield()
    self:checkInput()
  end
  self.cursor:destroy()
  return self.result
end

-- Verifies player's input. Stores result of action in self.result.
function ActionGUI:checkInput()
  if InputManager.keys['confirm']:isTriggered() then
    if self.action.currentTarget.selectable then
      self.result = self.action:onConfirm(self)
    end
  elseif InputManager.keys['cancel']:isTriggered() then
    self.result = self.action:onCancel(self)
  else
    local dx, dy = InputManager:axis(0.5, 0.0625)
    if dx ~= 0 or dy ~= 0 then
      local target = BattleManager.currentAction:nextTarget(dx, dy)
      if target then
        self.cursor:setTile(target)
        BattleManager:selectTarget(target)
      end
    end
  end
end

-- Creates step window.
-- @ret(StepWindow) newly created window
function ActionGUI:createStepWindow()
  if not self.stepWindow then
    self.stepWindow = StepWindow(self)
    self.stepWindow:setVisible(false)
  end
  return self.stepWindow
end

-- Shows grid and cursor.
function ActionGUI:startGridSelecting(target)
  if self.stepWindow then
    Callback.current:fork(function()
      self.stepWindow:show()
    end)
  end
  FieldManager:showGrid()
  BattleManager:selectTarget(target or self.action.currentTarget)
  self.cursor:setTile(target or self.action.currentTarget)
end

-- Hides grid and cursor.
function ActionGUI:endGridSelecting()
  if self.stepWindow then
    Callback.current:fork(function()
      self.stepWindow:hide()
    end)
  end
  FieldManager:hideGrid()
  self.cursor:hide()
end

return ActionGUI
