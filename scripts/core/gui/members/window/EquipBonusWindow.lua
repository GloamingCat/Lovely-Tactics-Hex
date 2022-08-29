
--[[===============================================================================================

EquipBonusWindow
---------------------------------------------------------------------------------------------------
A window that shows the attribute and element bonus of the equip item.

=================================================================================================]]

-- Imports
local EquipSet = require('core/battle/battler/EquipSet')
local List = require('core/datastruct/List')
local SimpleImage = require('core/gui/widget/SimpleImage')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

-- Alias
local round = math.round

local EquipBonusWindow = class(Window)

----------------------------------------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------------------------------------

-- Overrides Window:init.
-- @param(member : table) Troop unit data.
function EquipBonusWindow:init(gui, w, h, pos, member)
  self.member = member or gui:currentMember()
  self.bonus = List()
  Window.init(self, gui, w, h, pos)
end
-- Prints a list of attributes to receive a bonus.
-- @param(att : table) Array of attributes bonus (with key, oldValue and newValue).
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
-- Creates the list of text components for each attribute bonus.
-- @param(att : table) Array of attributes bonus (with key, oldValue and newValue).
-- @param(x : number) Position x of the list.
-- @param(y : number) Position y of the list.
-- @param(width : number) Width of the list.
function EquipBonusWindow:createBonusText(att, x, y, w)
  local font = Fonts.gui_small
  for i = 1, #att do
    local key = att[i].key
    local valueW = 30
    local arrowW = 15
    local namePos = Vector(x, y, 0)
    local name = SimpleText(Config.attributes[key].shortName, namePos, w / 2, 'left', font)
    self.content:add(name)
    self.bonus:add(name)
    local valuePos1 = Vector(x + w / 2, y, 0)
    local value1 = SimpleText(round(att[i].oldValue), valuePos1, valueW, 'left', font)
    self.content:add(value1)
    self.bonus:add(value1)
    local arrowIcon = {id = Config.animations.arrow, col = 0, row = 0}
    local arrowImg = ResourceManager:loadIcon(arrowIcon, GUIManager.renderer)
    local arrow = SimpleImage(arrowImg, x + w / 2 + valueW, y, 0, arrowW, value1.sprite:getHeight())
    self.content:add(arrow)
    self.bonus:add(arrow)
    local valuePos2 = Vector(x + w / 2 + valueW + arrowW, y, 0)
    local value2 = SimpleText(round(att[i].newValue), valuePos2, valueW, 'left', font)
    self.content:add(value2)
    self.bonus:add(value2)
    if att[i].newValue > att[i].oldValue then
      value2.sprite:setColor(Color.green)
    else
      value2.sprite:setColor(Color.red)
    end
    y = y + 10
  end
end
-- Shows the bonus for this item when equipped in the given slot.
-- @param(slotKey : string) Key of the slot to be changed.
-- @param(newEquip : table) Item's data from Database (nil to unequip).
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
-- @param(member : Battler) The owner of the current equipment set.
--  It is necessary so the attribute to calculate the attribute bonus.
function EquipBonusWindow:setMember(member)
  self.member = member
  self:setEquip(self.slotKey, member.equipSet:getEquip(self.slotKey))
end

----------------------------------------------------------------------------------------------------
-- Properties
----------------------------------------------------------------------------------------------------

-- @ret(string) String representation (for debugging).
function EquipBonusWindow:__tostring()
  return 'Equip Bonus Window'
end

return EquipBonusWindow