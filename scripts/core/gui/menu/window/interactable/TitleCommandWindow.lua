
-- ================================================================================================

--- The small windows with the commands for character management.
---------------------------------------------------------------------------------------------------
-- @windowmod TitleCommandWindow
-- @extend GridWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')
local SettingsMenu = require('core/gui/menu/SettingsMenu')

-- Class table.
local TitleCommandWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function TitleCommandWindow:init(...)
  self.speed = math.huge
  GridWindow.init(self, ...)
  self.currentCol = 1
  self.currentRow = self:loadGameEnabled() and 2 or 1
end
--- Implements `GridWindow:createWidgets`.
-- @implement
function TitleCommandWindow:createWidgets()
  Button:fromKey(self, 'newGame')
  Button:fromKey(self, 'loadGame')
  Button:fromKey(self, 'config')
  if not GameManager:isWeb() then
    Button:fromKey(self, 'quit')
  end
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- New Game button.
function TitleCommandWindow:newGameConfirm()
  self.menu:pauseBGM()
  self.menu:hide()
  self.menu:hideCover(true, false)
  self.menu:hideCover(false, true)
  self.result = 1
  local save = SaveManager:loadSave()
  GameManager:setSave(save)
end
--- Load Game button.
function TitleCommandWindow:loadGameConfirm()
  self.menu.topText:setVisible(false)
  self:hide()
  local result = self.menu:showWindowForResult(self.menu.loadWindow)
  if result ~= '' then
    self.menu:pauseBGM()
    self.menu:hide()
    self.menu:hideCover(false, true)
    self.result = 1
    local save = SaveManager:loadSave(result)
    GameManager:setSave(save)
  else
    self.menu.topText:setVisible(true)
    self:show()
  end
end
--- Settings button.
function TitleCommandWindow:configConfirm()
  self.menu.topText:setVisible(false)
  self:hide()
  MenuManager:showMenuForResult(SettingsMenu(self.menu))
  self.menu.topText:setVisible(true)
  self:show()
end
--- Quit button.
function TitleCommandWindow:quitConfirm()
  self.menu:hide()
  GameManager:quit()
end
--- Cancel button.
function TitleCommandWindow:onButtonCancel()
end

-- ------------------------------------------------------------------------------------------------
-- Enabled Conditions
-- ------------------------------------------------------------------------------------------------

--- Whether the ItemMenu can be open.
-- @treturn boolean
function TitleCommandWindow:loadGameEnabled()
  return self.menu.loadWindow
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function TitleCommandWindow:colCount()
  return 1
end
--- Overrides `GridWindow:rowCount`. 
-- @override
function TitleCommandWindow:rowCount()
  return GameManager:isWeb() and 3 or 4
end
-- For debugging.
function TitleCommandWindow:__tostring()
  return 'Title Command Window'
end

return TitleCommandWindow
