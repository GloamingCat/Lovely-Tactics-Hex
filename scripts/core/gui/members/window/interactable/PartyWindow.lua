
--[[===============================================================================================

PartyWindow
---------------------------------------------------------------------------------------------------
A button window that shows all the visibles members in the troop.
It selected one of the member to manage with MemberGUI.

=================================================================================================]]

-- Imports
local Button = require('core/gui/widget/control/Button')
local List = require('core/datastruct/List')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local MemberInfo = require('core/gui/widget/data/MemberInfo')
local Vector = require('core/math/Vector')

local PartyWindow = class(ListWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Gets the member list from the troop.
-- @param(troop : Troop)
function PartyWindow:init(gui, troop)
  self.visibleRowCount = GameManager:isMobile() and 3 or 4
  local list = troop:visibleBattlers()
  self.troop = troop
  ListWindow.init(self, gui, list)
end
-- Overrides GridWindow:setProperties.
-- Initialized tooltip.
function PartyWindow:setProperties()
  ListWindow.setProperties(self)
  self.tooltipTerm = ''
end
-- Overrides ListWindow:createListButton.
-- Creates a button for the given member.
-- @param(battler : Battler)
-- @ret(Button)
function PartyWindow:createListButton(battler)
  local button = Button(self)
  button.battler = battler
  return button
end

---------------------------------------------------------------------------------------------------
-- Member Info
---------------------------------------------------------------------------------------------------

-- Refresh each member info.
function PartyWindow:refreshMembers()
  for i = 1, #self.matrix do
    local button = self.matrix[i]
    if button.memberInfo then
      button.memberInfo:destroy()
      button.content:removeElement(button.memberInfo)
    end
    local w, h = self:cellWidth(), self:cellHeight()
    button.memberInfo = MemberInfo(button.battler, w - self:paddingX(), h)
    button.content:add(button.memberInfo)
    button:updatePosition(self.position)
  end
end
-- Overrides Window:show.
function PartyWindow:show(...)
  if not self.open then
    self:refreshMembers()
    self:hideContent()
  end
  ListWindow.show(self, ...)
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:colCount.
function PartyWindow:colCount()
  return 1
end
-- Overrides ListWindow:cellWidth.
function PartyWindow:cellWidth()
  return 240
end
-- Overrides GridWindow:cellHeight.
function PartyWindow:cellHeight()
  return (ListWindow.cellHeight(self) * 2 + self:rowMargin() * 2)
end
-- @ret(string) String representation (for debugging).
function PartyWindow:__tostring()
  return 'Member List Window'
end

return PartyWindow
