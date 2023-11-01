
-- ================================================================================================

--- A button window that shows all the visibles members in the troop.
-- It selected one of the member to manage with MemberGUI.
---------------------------------------------------------------------------------------------------
-- @uimod PartyWindow
-- @extend ListWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local List = require('core/datastruct/List')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')
local MemberInfo = require('core/gui/widget/data/MemberInfo')
local Vector = require('core/math/Vector')

-- Class table.
local PartyWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor. Gets the member list from the troop.
-- @tparam GUI gui Parent GUI.
-- @tparam Troop troop
function PartyWindow:init(gui, troop)
  self.visibleRowCount = GameManager:isMobile() and 3 or 4
  local list = troop:visibleBattlers()
  self.troop = troop
  ListWindow.init(self, gui, list)
end
--- Overrides `GridWindow:setProperties`. Initialized tooltip.
-- @override
function PartyWindow:setProperties()
  ListWindow.setProperties(self)
  self.tooltipTerm = ''
end
--- Overrides `ListWindow:createListButton`. Creates a button for the given member.
-- @override
-- @tparam Battler battler
-- @treturn Button
function PartyWindow:createListButton(battler)
  local button = Button(self)
  button.battler = battler
  return button
end

-- ------------------------------------------------------------------------------------------------
-- Member Info
-- ------------------------------------------------------------------------------------------------

--- Refresh each member info.
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
--- Overrides `Window:show`. 
-- @override
function PartyWindow:show(...)
  if not self.open then
    self:refreshMembers()
    self:hideContent()
  end
  ListWindow.show(self, ...)
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides `GridWindow:colCount`. 
-- @override
function PartyWindow:colCount()
  return 1
end
--- Overrides `ListWindow:cellWidth`. 
-- @override
function PartyWindow:cellWidth()
  return 240
end
--- Overrides `GridWindow:cellHeight`. 
-- @override
function PartyWindow:cellHeight()
  return (ListWindow.cellHeight(self) * 2 + self:rowMargin() * 2)
end
-- For debugging.
function PartyWindow:__tostring()
  return 'Member List Window'
end

return PartyWindow
