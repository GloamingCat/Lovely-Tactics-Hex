
--[[===============================================================================================

BattlerWindow
---------------------------------------------------------------------------------------------------
Window that shows on each character in the VisualizeAction.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/SimpleText')
local SimpleImage = require('core/gui/SimpleImage')

-- Alias
local round = math.round
local max = math.max

-- Constants
local attConfig = Database.attributes
local font = Font.gui_small

local BattlerWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(character : Character) the character of the battler to be shown
function BattlerWindow:init(GUI, character)
  local simple = {}
  local comp = {}
  for i = 1, #attConfig do
    if attConfig[i].script == '' then
      simple[#simple + 1] = attConfig[i]
    else
      comp[#comp + 1] = attConfig[i]
    end
  end
  self.simple, self.comp = simple, comp
  self.character = character
  local hsw = round(ScreenManager.width * 3 / 4)
  local hsh = max(#simple, #comp) * 10 + 15 + 2 * self:vpadding()
  local margin = 80
  Window.init(self, GUI, hsw, hsh)
end
-- Overrides Window:createContent.
function BattlerWindow:createContent()
  Window.createContent(self)
  -- Portrait
  local sprite = self.character.portraits.status
  if sprite then
    sprite = Sprite.fromQuad(sprite, GUIManager.renderer)
  else
    sprite = self.character.sprite:clone(GUIManager.renderer)
    self.portraitAnim = self.character.animation:clone(sprite)
    self.portraitAnim:setRow(6)
    self.portraitAnim:setCol(0)
    sprite:setXYZ(0, 0, 0)
  end
  local portrait = SimpleImage(sprite, self:hPadding() - self.width / 2, self:vpadding() - self.height / 2, 
      nil, round(self.width / 3) - self:hPadding(), self.height - self:vpadding() * 2)
  self.content:add(portrait)
  portrait:updatePosition(self.position)
  -- Content pos
  local x = round(self.width / 3 - self.width / 2)
  local y = round(self:vpadding() - self.height / 2)
  local w = round((self.width - self:hPadding()) / 3)
  -- Name
  local textName = SimpleText(self.character.battler.name, Vector(x, y), w)
  self.content:add(textName)
  -- Attributes
  self:createAtts(self.simple, x, y + 5, w - self:hPadding())
  self:createAtts(self.comp, x + round(self.width / 3), y + 5, w - self:hPadding())
end
-- Creates the text content from a list of attributes.
-- @param(attList : table) array of attribute data
-- @param(x : number) x of the texts
-- @param(y : number) initial y of the texts
-- @param(w : number) width of the text box
function BattlerWindow:createAtts(attList, x, y, w)
  local attValues = self.character.battler.att
  for i = 1, #attList do
    local pos = Vector(x, y + 10 * i)
    local att = attList[i]
    -- Attribute name
    local textName = SimpleText(att.shortName .. ':', pos, w, 'left', font)
    self.content:add(textName)
    -- Attribute value
    local value = attValues[att.shortName]()
    local textValue = SimpleText(value .. '', pos, w, 'right', font)
    self.content:add(textValue)
  end
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides Window:destroy.
function BattlerWindow:destroy()
  Window.destroy(self)
  if self.portraitAnim then
    self.portraitAnim:destroy()
  end
end

return BattlerWindow
