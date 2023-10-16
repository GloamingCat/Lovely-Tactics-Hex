
--[[===============================================================================================

@classmod FieldHUD
---------------------------------------------------------------------------------------------------
The GUI that is shown when the player chooses a troop member to manage.

=================================================================================================]]

-- Imports
local ButtonWindow = require('core/gui/common/window/interactable/ButtonWindow')
local GUI = require('core/gui/GUI')
local SaveInfo = require('core/gui/widget/data/SaveInfo')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Class table.
local FieldHUD = class(GUI)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

-- @tparam TroopBase troop Current troop (player's troop by default).
-- @tparam table memberList Arra of troop unit tables from current troop.
-- @tparam number memberID Current selected member on the list (first one by default).
function FieldHUD:init()
  self.name = 'Field HUD'
  GUI.init(self)
end
--- Implements GUI:createWindows.
function FieldHUD:createWindows()
  self:createSaveInfoWindow()
  self:createButtonWindow()
end
--- Creates the window with the information of the current save.
function FieldHUD:createSaveInfoWindow()
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
function FieldHUD:createButtonWindow()
  local window = ButtonWindow(self, 'menu', 'center', 60)
  window:setXYZ((ScreenManager.width - window.width) / 2, (window.height - ScreenManager.height) / 2)
  self.buttonWindow = window
end

-- ------------------------------------------------------------------------------------------------
-- Input
-- ------------------------------------------------------------------------------------------------

--- Checks if button was clicked on.
-- @treturn boolean Whether the button was pressed or not.
function FieldHUD:checkInput()
  return self.buttonWindow and self.buttonWindow:checkClick()
end

-- ------------------------------------------------------------------------------------------------
-- Save
-- ------------------------------------------------------------------------------------------------

--- Refresh each member info.
-- @tparam boolean all True to update all info. False to update only playtime.
function FieldHUD:refreshSave(all)
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
--- Overrides GUI:show.
function FieldHUD:show(...)
  if self.buttonWindow then
    self.buttonWindow:refreshLastOpen()
  end
  self.time = GameManager:currentPlayTime()
  GUI.show(self, ...)
  self:refreshSave(true)
end
--- Overrides GUI:update.
function FieldHUD:update(dt)
  GUI.update(self, dt)
  if self.open then
    self:refreshSave()
  end
  if self.buttonWindow then
    self.buttonWindow.active = FieldManager.player and not FieldManager.player:isBusy()
  end
end

return FieldHUD
