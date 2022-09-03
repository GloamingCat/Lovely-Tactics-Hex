
--[[===============================================================================================

BattleGUI
---------------------------------------------------------------------------------------------------
The GUI that is openned in the start of a character turn.
Its result is the action time that the character spent.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local TurnWindow = require('core/gui/battle/window/interactable/TurnWindow')
local ActionSkillWindow = require('core/gui/battle/window/interactable/ActionSkillWindow')
local ActionItemWindow = require('core/gui/battle/window/interactable/ActionItemWindow')
local DescriptionWindow = require('core/gui/common/window/DescriptionWindow')
local Vector = require('core/math/Vector')

local BattleGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides GUI:init.
function BattleGUI:init(...)
  self.troop = TurnManager:currentTroop()
  GUI.init(self, ...)
end
-- Implements GUI:createWindows.
function BattleGUI:createWindows()
  self.name = 'Battle GUI'
  self:createTurnWindow()
  self:createSkillWindow(2 / 3)
  self:createItemWindow(2 / 3)
  self:createDescriptionWindow(1 / 3)
  -- Initial state
  self:setActiveWindow(self.turnWindow)
end
-- Creates window with main commands.
function BattleGUI:createTurnWindow()
  self.turnWindow = TurnWindow(self)
  local m = self:windowMargin()
  self.turnWindow:setPosition(Vector(-ScreenManager.width / 2 + self.turnWindow.width / 2 + m, 
      -ScreenManager.height / 2 + self.turnWindow.height / 2 + m))
end
-- Creates window to use skill.
function BattleGUI:createSkillWindow(heightFraction)
  local character = TurnManager:currentCharacter()
  local skillList = character.battler.skillList
  if not skillList:isEmpty() then
    local h = heightFraction * (ScreenManager.height - self:windowMargin() * 3)
    self.skillWindow = ActionSkillWindow(self, skillList, h)
    self.skillWindow.lastOpen = false
  end
end
-- Creates window to use item.
function BattleGUI:createItemWindow(heightFraction)
  local inventory = TurnManager:currentTroop().inventory
  local itemList = inventory:getUsableItems(1)
  if #itemList > 0 then
    local h = heightFraction * (ScreenManager.height - self:windowMargin() * 3)
    self.itemWindow = ActionItemWindow(self, inventory, itemList, h)
    self.itemWindow.lastOpen = false
  end
end
-- Creates window that shows item and skill descriptions.
function BattleGUI:createDescriptionWindow(heightFraction)
  local mainWindow = self.skillWindow or self.itemWindow 
  if not mainWindow then
    return
  end
  local w = ScreenManager.width - self:windowMargin() * 2
  local h = ScreenManager.height - mainWindow.height / 2 - (ScreenManager.height / 2 + mainWindow.position.y) - self:windowMargin() * 2
  h = math.min(h, (ScreenManager.height - self:windowMargin() * 3) * heightFraction)
  local pos = Vector(0, ScreenManager.height / 2 - h / 2 - self:windowMargin())
  self.descriptionWindow = DescriptionWindow(self, w, h, pos)
  self.descriptionWindow.lastOpen = false
end
-- Shows the description below the given window.
-- @param(window : Window) the window with the items with descriptions.
function BattleGUI:showDescriptionWindow(window)
  if self.descriptionWindow then
    local text = window:currentWidget().description
    self.descriptionWindow:updateText(text)
    self.descriptionWindow:insertSelf()
    GUIManager.fiberList:fork(self.descriptionWindow.show, self.descriptionWindow)
  end
end
-- Hides the description window.
function BattleGUI:hideDescriptionWindow()
  if self.descriptionWindow then
    GUIManager.fiberList:fork(function()
      self.descriptionWindow:hide()
      self.descriptionWindow:removeSelf()
    end)
  end
end

---------------------------------------------------------------------------------------------------
-- Camera focus
---------------------------------------------------------------------------------------------------

-- Overrides GUI:show.
function BattleGUI:show(...)
  FieldManager.renderer:moveToObject(TurnManager:currentCharacter())
  GUI.show(self, ...)
end

return BattleGUI
