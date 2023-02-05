
--[[===============================================================================================

RecruitConfirmWindow
---------------------------------------------------------------------------------------------------
Window that shows the total price to be paidin the Recruit GUI.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/battler/Battler')
local Button = require('core/gui/widget/control/Button')
local BattlerWindow = require('core/gui/common/window/BattlerWindow')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

local RecruitConfirmWindow = class(BattlerWindow)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides CountWindow:createWidgets. Adds "hire" button.
function RecruitConfirmWindow:createContent(...)
  BattlerWindow.createContent(self, ...)
  local w = self.width - self:paddingX() * 2
  local h = self.height - self:paddingY() * 2
  local confirm = SimpleText(Vocab.confirm, Vector(-w/2, -h/2), w, 'center', Fonts.gui_button)
  confirm:setMaxWidth(w)
  confirm:setMaxHeight(h)
  confirm:setAlign('center', 'bottom')
  confirm:redraw()
  self.content:add(confirm)
end

---------------------------------------------------------------------------------------------------
-- Item
---------------------------------------------------------------------------------------------------

-- @param(char : table) Character data from database,
-- @param(price : number) Price to hire.
function RecruitConfirmWindow:setChar(char, price)
  local key = 'ally' .. #self.GUI.troop.members
  local member = { key = key, battlerID = char.battlerID, charID = char.id }
  local battler = Battler(self.GUI.troop, member)
  self:setBattler(battler)
  self.battler = battler
  self.member = member
  self.char = char
  self.price = price
end
-- @param(member : table) Member data from troop.
-- @param(price : number) Money received to dismiss.
function RecruitConfirmWindow:setMember(member, price)
  self:setBattler(self.GUI.troop.battlers[member.key])
  self.member = member
  self.price = price
end

---------------------------------------------------------------------------------------------------
-- Confirm Callbacks
---------------------------------------------------------------------------------------------------

function RecruitConfirmWindow:onConfirm()
  AudioManager:playSFX(Config.sounds.buy)
  self:apply()
end
-- Cancels the hire action.
function RecruitConfirmWindow:onCancel()
  AudioManager:playSFX(Config.sounds.buttonCancel)
  self:returnWindow()
end

---------------------------------------------------------------------------------------------------
-- Finish
---------------------------------------------------------------------------------------------------

-- Buys / dismisss the selected quantity.
function RecruitConfirmWindow:apply()
  local troop = self.GUI.troop
  troop.money = troop.money - self.price
  if self.hire then
    troop:addMember(self.member, self.battler)
  else
    troop:removeMember(self.member.key)
    self.GUI.listWindow:setDismissMode()
  end
  self.GUI.goldWindow:setGold(troop.money)
  self:returnWindow()
end
-- Hides this window and returns to the window with the item list.
function RecruitConfirmWindow:returnWindow()
  local w = self.GUI.listWindow
  local w2 = self.GUI.descriptionWindow
  self:hide()
  _G.Fiber:fork(w2.show, w2)
  w:show()
  w:refreshButtons()
  w:activate()
end

---------------------------------------------------------------------------------------------------
-- Mode
---------------------------------------------------------------------------------------------------

-- Use this window to hire items.
function RecruitConfirmWindow:setHireMode()
  self.hire = true
end
-- Use this window to dismiss items.
function RecruitConfirmWindow:setDismissMode()
  self.hire = false
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- Overrides GridWindow:rowCount.
function RecruitConfirmWindow:rowCount()
  return 2
end
-- Overrides GridWindow:cellWidth.
function RecruitConfirmWindow:cellWidth()
  return 100
end
-- @ret(string) String representation (for debugging).
function RecruitConfirmWindow:__tostring()
  return 'Recruit Count Window'
end

return RecruitConfirmWindow
