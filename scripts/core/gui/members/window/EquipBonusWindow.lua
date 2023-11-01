
-- ================================================================================================

--- A window that shows the attribute and element bonus of the equip item.
---------------------------------------------------------------------------------------------------
-- @windowmod EquipBonusWindow
-- @extend Window

-- ================================================================================================

-- Imports
local EquipSet = require('core/battle/battler/EquipSet')
local List = require('core/datastruct/List')
local ImageComponent = require('core/gui/widget/ImageComponent')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Alias
local round = math.round

-- Class table.
local EquipBonusWindow = class(Window)

-- -------------------------------------------------------------------------------------------------
-- Initialization
-- -------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam Menu menu Parent Menu.
-- @tparam number w Window's width in pixels.
-- @tparam number h Window's height in pixels.
-- @tparam Vector pos The position of the window's center.
-- @tparam table member The troop unit data of the character.
function EquipBonusWindow:init(menu, w, h, pos, member)
  self.member = member or menu:currentMember()
  self.bonus = List()
  Window.init(self, menu, w, h, pos)
end
--- Prints a list of attributes to receive a bonus.
-- @tparam table att Array of attributes bonus (with key, oldValue and newValue).
function EquipBonusWindow:updateBonus(att)
  for i = 1, #self.bonus do
    self.bonus[i]:destroy()
    self.content:removeElement(self.bonus[i])
  end
  self.bonus = List()
  local x = self:paddingX() - self.width / 2
  local y = self:paddingY() - self.height / 2
  local w = self.width - self:paddingX() * 2
  self:createBonusText(att, x, y, w)
  for i = 1, #self.bonus do
    self.bonus[i]:updatePosition(self.position)
  end
end
--- Creates the list of text components for each attribute bonus.
-- @tparam table att Array of attributes bonus (with key, oldValue and newValue).
-- @tparam number x Position x of the list.
-- @tparam number y Position y of the list.
-- @tparam number w Width of the list.
function EquipBonusWindow:createBonusText(att, x, y, w)
  local font = Fonts.menu_small
  for i = 1, #att do
    local key = att[i].key
    local valueW = 25
    local arrowW = 12
    local nameW = 30
    local namePos = Vector(x, y, 0)
    local txtName = TextComponent(key, namePos, nameW, 'left', font)
    txtName:setTerm('data.conf.' .. key, Config.attributes[key].shortName)
    txtName:redraw()
    self.content:add(txtName)
    self.bonus:add(txtName)
    local valuePos1 = Vector(x + nameW, y, 0)
    local value1 = TextComponent(round(att[i].oldValue), valuePos1, valueW, 'left', font)
    self.content:add(value1)
    self.bonus:add(value1)
    local arrowIcon = {id = Config.animations.arrow, col = 0, row = 0}
    local arrowImg = ResourceManager:loadIcon(arrowIcon, MenuManager.renderer)
    local arrow = ImageComponent(arrowImg, x + nameW + valueW, y, 0, arrowW, value1.sprite:getHeight())
    self.content:add(arrow)
    self.bonus:add(arrow)
    local valuePos2 = Vector(x + nameW + valueW + arrowW, y, 0)
    local value2 = TextComponent(round(att[i].newValue), valuePos2, valueW, 'left', font)
    self.content:add(value2)
    self.bonus:add(value2)
    if att[i].newValue > att[i].oldValue then
      value2.sprite:setColor(Color.positive_bonus)
    else
      value2.sprite:setColor(Color.negative_bonus)
    end
    y = y + 10
  end
end
--- Shows the bonus for this item when equipped in the given slot.
-- @tparam string slotKey Key of the slot to be changed.
-- @tparam table newEquip Item's data from Database (nil to unequip).
function EquipBonusWindow:setEquip(slotKey, newEquip)
  self.equip = newEquip
  self.slotKey = slotKey
  -- Attribute Bonus
  local currentSet = self.member.equipSet
  local save = { equips = currentSet:getState() }
  local simulationSet = EquipSet(nil, save)
  simulationSet:setEquip(slotKey, newEquip)
  local bonusList = {}
  for i, att in ipairs(Config.attributes) do
    local oldValue = round(self.member.att[att.key]())
    self.member.equipSet = simulationSet
    local newValue = round(self.member.att[att.key]())
    self.member.equipSet = currentSet
    if oldValue ~= newValue then
      bonusList[#bonusList + 1] = {
        oldValue = oldValue,
        newValue = newValue,
        key = att.key }
    end
  end
  self:updateBonus(bonusList)
end
--- Sets the current character. It is necessary to calculate the attribute bonus.
-- @tparam Battler battler The owner of the current equipment set.
function EquipBonusWindow:setBattler(battler)
  self.member = battler
  self:setEquip(self.slotKey, battler.equipSet:getEquip(self.slotKey))
end
-- For debugging.
function EquipBonusWindow:__tostring()
  return 'Equip Bonus Window'
end

return EquipBonusWindow
