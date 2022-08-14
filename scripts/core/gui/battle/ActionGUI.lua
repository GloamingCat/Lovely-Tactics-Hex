
--[[===============================================================================================

ActionGUI
---------------------------------------------------------------------------------------------------
The GUI that is open when player selects an action.
It does not have windows, and instead it implements its own "waitForResult" 
and "checkInput" methods.
Its result is the action time that the character spent.

=================================================================================================]]

-- Imports
local BattleCursor = require('core/battle/BattleCursor')
local GUI = require('core/gui/GUI')
local ConfirmWindow = require('core/gui/common/window/interactable/ConfirmWindow')
local StepWindow = require('core/gui/battle/window/StepWindow')
local TargetWindow = require('core/gui/battle/window/TargetWindow')

-- Alias
local yield = coroutine.yield

local ActionGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
function ActionGUI:init(parent, input)
  self.name = 'Action GUI'
  self.slideMargin = 16
  self.slideSpeed = 3
  GUI.init(self, parent)
  self.confirmSound = Config.sounds.buttonConfirm
  self.cancelSound = Config.sounds.buttonCancel
  self.selectSound = Config.sounds.buttonSelect
  self.errorSound = Config.sounds.buttonError
  self.input = input
  input.GUI = self
end

---------------------------------------------------------------------------------------------------
-- Auxiliary Windows
---------------------------------------------------------------------------------------------------

-- Creates the GUI's windows and sets the first active window.
function ActionGUI:createConfirmWindow()
  if not self.confirmWindow then
    local window = ConfirmWindow(self)
    self.confirmWindow = window
    local x = -ScreenManager.width / 2 + window.width / 2 + self.slideMargin
    local y = -ScreenManager.height / 2 + window.height / 2 + self.slideMargin
    window:setXYZ(x, y)
    window.offBoundsCancel = false
    window:setVisible(false)
  end
  return self.confirmWindow
end
-- Creates step window if not created yet.
-- @ret(StepWindow) This GUI's step window.
function ActionGUI:createStepWindow()
  if not self.stepWindow then
    local window = StepWindow(self)
    self.stepWindow = window
    window:setVisible(false)
  end
  return self.stepWindow
end
-- Creates target window if not created yet.
-- @ret(TargetWindow) This GUI's target window.
function ActionGUI:createTargetWindow()
  if not self.targetWindow then
    local window = TargetWindow(self)
    self.targetWindow = window
    window:setVisible(false)
  end
  return self.targetWindow
end
-- Updates the battler shown in the target window.
function ActionGUI:updateTargetWindow(char)
  self.targetWindow:setBattler(char.battler)
  self.targetWindow:setVisible(false)
  self.targetWindow:show()
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- [COROUTINE] Overrides GUI:waitForResult.
function ActionGUI:waitForResult()
  self.result = self.input.action:onActionGUI(self.input)
  while self.result == nil do
    if self.cursor then
      self.cursor:update()
    end
    yield()
    self:checkInput()
  end
  if self.cursor then
    self.cursor:destroy()
  end
  return self.result
end
-- Verifies player's input. Stores result of action in self.result.
function ActionGUI:checkInput()
  if self.confirmWindow then
    self.confirmWindow:checkInput()
    if self.confirmWindow.result == 1 then
      self.confirmWindow.result = nil
      self.result = self.input:execute()
      return
    elseif self.confirmWindow.result == 0 then
      self.confirmWindow.result = nil
      self.result = self.input.action:onCancel(self.input)
      return
    end
  end
  return self:mouseInput() or self:keyboardInput()
end
-- Sets given tile as current target.
-- @param(target : ObjectTile)
function ActionGUI:selectTarget(target)
  target = target or self.input.target
  if self.cursor then
    self.cursor:setTile(target)
  end
  self.input.action:onDeselectTarget(self.input)
  self.input.target = target
  self.input.action:onSelectTarget(self.input)
  if self.targetWindow then
    local char = target:getFirstBattleCharacter()
    if char then
      GUIManager.fiberList:fork(self.updateTargetWindow, self, char)
    else
      GUIManager.fiberList:fork(self.targetWindow.hide, self.targetWindow)
    end
  end
  if self.confirmWindow then
    self.confirmWindow.matrix[1]:setEnabled(self.input.target.gui.selectable)
  end
end

---------------------------------------------------------------------------------------------------
-- Keyboard
---------------------------------------------------------------------------------------------------

-- Checks the keyboard input.
function ActionGUI:keyboardInput()
  if InputManager.keys['confirm']:isTriggered() then
    if self.input.target.gui.selectable then
      self:playConfirmSound()
      self.result = self.input:execute()
    else
      self:playErrorSound()
    end
  elseif InputManager.keys['cancel']:isTriggered() then
    self:playCancelSound()
    self.result = self.input.action:onCancel(self.input)
  elseif InputManager.keys['next']:isTriggered() then
    local target = self.input.action:nextLayer(self.input, 1)
    if target and target ~= self.input.target then
      FieldManager.renderer:moveToTile(target)
      self:playSelectSound()
      self:selectTarget(target)
    end
  elseif InputManager.keys['prev']:isTriggered() then
    local target = self.input.action:nextLayer(self.input, -1)
    if target and target ~= self.input.target then
      FieldManager.renderer:moveToTile(target)
      self:playSelectSound()
      self:selectTarget(target)
    end
  else
    local dx, dy = InputManager:axis(0.5, 0.0625)
    if dx ~= 0 or dy ~= 0 then
      local target = self.input.action:nextTarget(self.input, dx, dy)
      if target and target ~= self.input.target then
        FieldManager.renderer:moveToTile(target)
        self:playSelectSound()
        self:selectTarget(target)
      end
    else
      return false
    end
  end
  return true
end

---------------------------------------------------------------------------------------------------
-- Mouse Input
---------------------------------------------------------------------------------------------------

-- Check the mouse input.
function ActionGUI:mouseInput()
  self:checkSlide()
  if InputManager.mouse.moved then
    local target = self:mouseTarget()
    if target and target ~= self.input.target then
      self:selectTarget(target)
    end
  elseif InputManager.keys['touch']:isReleased() then
    local target = self:mouseTarget()
    if target and target ~= self.input.target then
      self:selectTarget(target)
      FieldManager.renderer:moveToTile(target)
    end
  elseif InputManager.keys['mouse1']:isTriggered() then
    local target = self:mouseTarget()
    if target then
      if target ~= self.input.target then
        self:selectTarget(target)
      end
      if self.input.target.gui.selectable then
        self:playConfirmSound()
        self.result = self.input:execute()
      else
        self:playErrorSound()
      end
    else
      self:playErrorSound()
    end
  elseif InputManager.keys['mouse2']:isTriggered() then
    self:playCancelSound()
    self.result = self.input.action:onCancel(self.input)
  else
    return false
  end
  return true
end
-- @ret(ObjectTile) The tile that the mouse is over.
function ActionGUI:mouseTarget()
  local field = FieldManager.currentField
  for l = field.maxh, field.minh, -1 do
    local x, y = InputManager.mouse:fieldCoord(l)
    if not field:exceedsBorder(x, y) and field:isGrounded(x, y, l) then
      return field:getObjectTile(x, y, l)
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Screen Slide
---------------------------------------------------------------------------------------------------

-- Checks if the mouse pointer in the slide area.
function ActionGUI:checkSlide()
  if not InputManager.mouse.active or InputManager.usingKeyboard then
    return
  end
  if GameManager.platform == 1 and not InputManager.keys.touch:isPressing() then
    return
  end
  local w = ScreenManager.width / 2 - self.slideMargin
  local h = ScreenManager.height / 2 - self.slideMargin
  local x, y = InputManager.mouse:guiCoord()
  if x > w or x < -w then
    self:slideX(math.sign(x))
  end
  if y > h or y < -h then
    self:slideY(math.sign(y))
  end
end
-- Slides the screen horizontally.
-- @param(d : number) Direction (1 or -1).
function ActionGUI:slideX(d)
  local camera = FieldManager.renderer
  local speed = self.slideSpeed * GUIManager.fieldScroll * 2 / 100
  local x = camera.position.x + d * speed * GameManager:frameTime() * 60
  local field = FieldManager.currentField 
  if x >= field.minx and x <= field.maxx then
    camera:setXYZ(x, nil)
    InputManager.mouse:show()
  end
end
-- Slides the screen vertically.
-- @param(d : number) Direction (1 or -1).
function ActionGUI:slideY(d)
  local camera = FieldManager.renderer
  local speed = self.slideSpeed * GUIManager.fieldScroll * 2 / 100
  local y = camera.position.y + d * speed * GameManager:frameTime() * 60
  local field = FieldManager.currentField 
  if y >= field.miny and y <= field.maxy then
    camera:setXYZ(nil, y)
    InputManager.mouse:show()
  end
end

---------------------------------------------------------------------------------------------------
-- Grid selecting
---------------------------------------------------------------------------------------------------

-- Shows grid and cursor.
function ActionGUI:startGridSelecting(target)
  if self.stepWindow then
    GUIManager.fiberList:fork(self.stepWindow.show, self.stepWindow)
  end
  if self.confirmWindow then
    self.confirmWindow.result = nil
    GUIManager.fiberList:fork(self.confirmWindow.show, self.confirmWindow)
  end
  FieldManager:showGrid()
  FieldManager.renderer:moveToTile(target)
  self.cursor = self.cursor or BattleCursor()
  self:selectTarget(target)
  self.gridSelecting = true
end
-- Hides grid and cursor.
function ActionGUI:endGridSelecting()
  if self.confirmWindow then
    GUIManager.fiberList:fork(self.confirmWindow.hide, self.confirmWindow)
  end
  if self.stepWindow then
    GUIManager.fiberList:fork(self.stepWindow.hide, self.stepWindow)
  end
  if self.targetWindow then
    GUIManager.fiberList:fork(self.targetWindow.hide, self.targetWindow)
  end
  while (self.targetWindow and not self.targetWindow.closed 
      or self.confirmWindow and not self.confirmWindow.closed
      or self.stepWindow and not self.stepWindow.closed) do
    yield()
  end
  FieldManager:hideGrid()
  if self.cursor then
    self.cursor:hide()
  end
  self.gridSelecting = false
end

---------------------------------------------------------------------------------------------------
-- Sound
---------------------------------------------------------------------------------------------------

-- Confirm a tile.
function ActionGUI:playConfirmSound()
  if self.confirmSound then
    AudioManager:playSFX(self.confirmSound)
  end
end
-- Cancel action.
function ActionGUI:playCancelSound()
  if self.cancelSound then
    AudioManager:playSFX(self.cancelSound)
  end
end
-- Select a tile.
function ActionGUI:playSelectSound()
  if self.selectSound then
    AudioManager:playSFX(self.selectSound)
  end
end
-- Confirm a non-selectable tile.
function ActionGUI:playErrorSound()
  if self.errorSound then
    AudioManager:playSFX(self.errorSound)
  end
end

return ActionGUI
