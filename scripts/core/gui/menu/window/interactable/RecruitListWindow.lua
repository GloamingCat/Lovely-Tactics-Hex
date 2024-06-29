
-- ================================================================================================

--- Window with the list of items available to hire.
---------------------------------------------------------------------------------------------------
-- @windowmod RecruitListWindow
-- @extend ListWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local ListWindow = require('core/gui/common/window/interactable/ListWindow')

-- Class table.
local RecruitListWindow = class(ListWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam RecruitMenu menu Parent Menu.
function RecruitListWindow:init(menu)
  self.visibleRowCount = 4
  ListWindow.init(self, menu, {})
end
--- Implements `ListWindow:createListButton`.
-- @implement
function RecruitListWindow:createListButton(entry)
  local battler, price, char, member
  if self.hire then
    char = Database.characters[entry.id]
    assert(char, 'Character does not exist: ' .. tostring(entry.id))
    battler = Database.battlers[char.battlerID]
    assert(battler, 'Character does not have a battler: ' .. tostring(char.id))
    price = entry.value or battler.money
  else
    member = self.menu.troop.members[entry.key]
    assert(member, 'Member not in troop: ' .. entry.key)
    battler = self.menu.troop.battlers[entry.key]
    assert(battler, 'Member has no battler: ' .. entry.key)
    battler = battler.data
    assert(battler, 'Battler has no data: ' .. tostring(battler))
    price = -(math.floor(battler.money / 2))
  end
  local button = Button(self)
  button:setIcon(battler.icon)
  button:createText('data.battler.' .. battler.key, battler.name, 'menu_button')
  button.price = price
  button.battler = battler
  if self.hire then
    button.char = char
    button:createInfoText(price .. ' {%g}', nil, 'menu_button')
  else
    button.member = member
    button:createInfoText(-price .. ' {%g}', nil, 'menu_button')
  end
  return button
end

-- ------------------------------------------------------------------------------------------------
-- Mode
-- ------------------------------------------------------------------------------------------------

--- Use this window to hire battlers.
function RecruitListWindow:setHireMode()
  self.hire = true
  self:refreshButtons(self.menu.chars)
end
--- Use this window to dismiss battlers.
function RecruitListWindow:setDismissMode()
  self.hire = false
  self:refreshButtons(self.menu.troop:visibleMembers())
end

-- ------------------------------------------------------------------------------------------------
-- Enable Conditions
-- ------------------------------------------------------------------------------------------------

--- In hire mode, checks if at least one battler of this type can be recruited.
-- In dismiss mode, checks if the battler is dismissable.
-- @tparam Button button Button to check, containing the battler's information.
-- @treturn boolean Whether the hire/dismiss button should be enabled.
function RecruitListWindow:buttonEnabled(button)
  if self.hire then
    return self.menu.troop.money >= button.price
  else
    return button.battler.recruit
  end
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Shows the window to select the quantity.
-- @tparam Button button Selected button.
function RecruitListWindow:onButtonConfirm(button)
  local w = self.menu.countWindow
  local w2 = self.menu.descriptionWindow
  self:hide()
  _G.Fiber:forkMethod(w2, 'hide')
  w:show()
  if self.hire then
    w:setChar(button.char, button.price)
  else
    w:setMember(button.member, button.price)
  end
  w:activate()
end
--- Closes hire Menu.
-- @tparam Button button Selected button.
function RecruitListWindow:onButtonCancel(button)
  self.menu:hideRecruitMenu()
end
--- Updates item description.
-- @tparam Button button Selected button.
function RecruitListWindow:onButtonSelect(button)
  self.menu.descriptionWindow:updateTerm('data.battler.' .. button.battler.key .. '_desc', button.battler.description)
end

-- ------------------------------------------------------------------------------------------------
-- Confirm Callbacks
-- ------------------------------------------------------------------------------------------------

--- Overrides `ListWindow:cellWidth`. 
-- @override
function RecruitListWindow:cellWidth()
  return ListWindow.cellWidth(self) * 4 / 5
end
-- For debugging.
function RecruitListWindow:__tostring()
  return 'Recruit List Window'
end

return RecruitListWindow
