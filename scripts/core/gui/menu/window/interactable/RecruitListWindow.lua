
-- ================================================================================================

--- Window with the list of items available to hire.
---------------------------------------------------------------------------------------------------
-- @classmod RecruitListWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')

-- Class table.
local RecruitListWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

function RecruitListWindow:init(gui)
  self.visibleRowCount = 4
  ListWindow.init(self, gui, {})
end
--- Implements `ListWindow:createListButton`.
-- @implement createListButton
function RecruitListWindow:createListButton(entry)
  local battler, price, char, member
  if self.hire then
    char = Database.characters[entry.id]
    assert(char, 'Character does not exist: ' .. tostring(entry.id))
    battler = Database.battlers[char.battlerID]
    assert(battler, 'Character does not have a battler: ' .. tostring(char.id))
    price = entry.price or battler.money
  else
    member = self.GUI.troop.members[entry.key]
    assert(member, 'Member not in troop: ' .. entry.key)
    battler = self.GUI.troop.battlers[entry.key]
    assert(member, 'Member has no battler: ' .. entry.key)
    battler = battler.data
    price = -(math.floor(battler.money / 2))
  end
  local button = Button(self)
  local icon = battler.icon and battler.icon.id >= 0 and 
    ResourceManager:loadIconAnimation(battler.icon, GUIManager.renderer)
  if icon then
    button:createIcon(icon)
  end
  button:createText('data.battler.' .. battler.key, battler.name, 'gui_button')
  button.price = price
  button.battler = battler
  if self.hire then
    button.char = char
    button:createInfoText(price .. ' {%g}', nil, 'gui_button')
  else
    button.member = member
    button:createInfoText(-price .. ' {%g}', nil, 'gui_button')
  end
  return button
end

-- ------------------------------------------------------------------------------------------------
-- Mode
-- ------------------------------------------------------------------------------------------------

--- Use this window to hire items.
function RecruitListWindow:setHireMode()
  self.hire = true
  self:refreshButtons(self.GUI.chars)
end
--- Use this window to sell items.
function RecruitListWindow:setDismissMode()
  self.hire = false
  self:refreshButtons(self.GUI.troop:visibleMembers())
end

-- ------------------------------------------------------------------------------------------------
-- Enable Conditions
-- ------------------------------------------------------------------------------------------------

-- @treturn boolean True if at least one item of this type can be bought.
function RecruitListWindow:buttonEnabled(button)
  if self.hire then
    return self.GUI.troop.money >= button.price
  else
    return button.battler.recruit
  end
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Shows the window to select the quantity.
function RecruitListWindow:onButtonConfirm(button)
  local w = self.GUI.countWindow
  local w2 = self.GUI.descriptionWindow
  self:hide()
  _G.Fiber:fork(w2.hide, w2)
  w:show()
  if self.hire then
    w:setChar(button.char, button.price)
  else
    w:setMember(button.member, button.price)
  end
  w:activate()
end
--- Closes hire GUI.
function RecruitListWindow:onButtonCancel(button)
  self.GUI:hideRecruitGUI()
end
--- Updates item description.
function RecruitListWindow:onButtonSelect(button)
  self.GUI.descriptionWindow:updateTerm('data.battler.' .. button.battler.key .. '_desc', button.battler.description)
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Overrides `ListWindow:cellWidth`. 
-- @override cellWidth
function RecruitListWindow:cellWidth()
  return ListWindow.cellWidth(self) * 4 / 5
end
-- @treturn string String representation (for debugging).
function RecruitListWindow:__tostring()
  return 'Recruit List Window'
end

return RecruitListWindow
