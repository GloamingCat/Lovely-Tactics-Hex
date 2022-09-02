
--[[===============================================================================================

FieldHUD
---------------------------------------------------------------------------------------------------
The GUI that is shown when the player chooses a troop member to manage.

=================================================================================================]]

-- Imports
local ButtonWindow = require('core/gui/common/window/interactable/ButtonWindow')
local GUI = require('core/gui/GUI')
local SaveInfo = require('core/gui/widget/data/SaveInfo')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

local FieldHUD = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(troop : TroopBase) Current troop (player's troop by default).
-- @param(memberList : table) Arra of troop unit tables from current troop.
-- @param(memberID : number) Current selected member on the list (first one by default).
function FieldHUD:init()
  self.name = 'Field HUD'
  GUI.init(self)
end
-- Implements GUI:createWindows.
function FieldHUD:createWindows()
  self:createSaveInfoWindow()
  self:createButtonWindow()
end
-- Creates the window with the information of the chosen member.
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
-- Creates the window with the menu button, for mobile.
function FieldHUD:createButtonWindow()
  local window = ButtonWindow(self, Vocab.menu)
  window:setXYZ((ScreenManager.width - window.width) / 2, (window.height - ScreenManager.height) / 2)
  window.offBoundsCancel = false
  self.buttonWindow = window
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- Checks if button was clicked on.
-- @ret(boolean) Whether the button was pressed or not.
function FieldHUD:checkInput()
  if self.buttonWindow then
    self.buttonWindow:checkInput()
    if self.buttonWindow.result then
      self.buttonWindow.result = nil
      return true
    end
  end
  return false
end

---------------------------------------------------------------------------------------------------
-- Save
---------------------------------------------------------------------------------------------------

-- Refresh each member info.
-- @param(all : boolean) True to update all info. False to update only playtime.
function FieldHUD:refreshSave(all)
  local save = SaveManager:getHeader()
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

function FieldHUD:show(...)
  self.time = GameManager:currentPlayTime()
  GUI.show(self, ...)
  self:refreshSave(true)
end

function FieldHUD:update(...)
  GUI.update(self, ...)
  if self.open then
    self:refreshSave()
  end
end

return FieldHUD
