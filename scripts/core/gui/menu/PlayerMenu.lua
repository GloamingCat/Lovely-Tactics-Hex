
-- ================================================================================================

--- A HUD shown when the `Player` explores the field.
---------------------------------------------------------------------------------------------------
-- @menumod PlayerMenu
-- @extend Menu

-- ================================================================================================

-- Imports
local ButtonWindow = require('core/gui/common/window/interactable/ButtonWindow')
local Menu = require('core/gui/Menu')
local SaveInfo = require('core/gui/widget/data/SaveInfo')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Class table.
local PlayerMenu = class(Menu)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Overrides `Menu:init`.
function PlayerMenu:init()
  self.name = 'Field HUD'
  Menu.init(self)
end
--- Implements `Menu:createWindows`.
-- @implement
function PlayerMenu:createWindows()
  self:createSaveInfoWindow()
  self:createButtonWindow()
end
--- Creates the window with the information of the current save.
function PlayerMenu:createSaveInfoWindow()
  local width = Config.troop.maxMembers * 20 + 60
  local height = 44
  local wpos = Vector((width - ScreenManager.width) / 2, (height - ScreenManager.height) / 2)
  local window = Window(self, width, height, wpos)
  local ipos = Vector((window:paddingX() - width) / 2, (window:paddingY() - height) / 2)
  window.info = SaveInfo(ipos, width - window:paddingX() * 2, height - window:paddingY() * 2)
  window.content:add(window.info)
  self.saveInfoWindow = window
end
--- Creates the window with the menu button, for mobile.
function PlayerMenu:createButtonWindow()
  local window = ButtonWindow(self, 'menu', 'center', 60)
  window:setXYZ((ScreenManager.width - window.width) / 2, (window.height - ScreenManager.height) / 2)
  self.buttonWindow = window
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Checks if button was clicked on.
-- @treturn boolean Whether the button was pressed or not.
function PlayerMenu:checkInput()
  return self.buttonWindow and self.buttonWindow:checkClick()
end

-- ------------------------------------------------------------------------------------------------
-- Save
-- ------------------------------------------------------------------------------------------------

--- Refresh each member info.
-- @tparam boolean all True to update all info. False to update only playtime.
function PlayerMenu:refreshSave(all)
  local save = SaveManager:createHeader()
  if all then
    self.saveInfoWindow.info:refreshInfo(save)
    self.saveInfoWindow.info:updatePosition(self.saveInfoWindow.position)
  end
  local time = string.time(GameManager:currentPlayTime())
  if self.time ~= time then
    self.time = time
    self.saveInfoWindow.info.content[2]:setText(time)
    self.saveInfoWindow.info.content[2]:redraw()
  end
  if not self.saveInfoWindow.open then
    self.saveInfoWindow:hideContent()
  end
end
--- Overrides `Menu:show`. 
-- @override
function PlayerMenu:show(...)
  if self.buttonWindow then
    self.buttonWindow:refreshLastOpen()
  end
  self.time = GameManager:currentPlayTime()
  Menu.show(self, ...)
  self:refreshSave(true)
end
--- Overrides `Menu:update`. 
-- @override
function PlayerMenu:update(dt)
  Menu.update(self, dt)
  if self.open then
    self:refreshSave()
  end
  if self.buttonWindow then
    self.buttonWindow.active = FieldManager.player and not FieldManager.player:isBusy()
  end
end

return PlayerMenu
