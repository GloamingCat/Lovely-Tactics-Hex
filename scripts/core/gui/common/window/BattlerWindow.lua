
--[[===============================================================================================

BattlerWindow
---------------------------------------------------------------------------------------------------
Window that shows on each character in the VisualizeAction.

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/widget/SimpleText')
local SimpleImage = require('core/gui/widget/SimpleImage')

-- Alias
local max = math.max
local round = math.round
local findByName = util.array.findByName

local BattlerWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Constructor.
-- @param(character : Character) the character of the battler to be shown
function BattlerWindow:init(GUI)
  self.font = Fonts.gui_small
  self.nameFont = Fonts.gui_medium
  local cw, ch = self:preprocess()
  Window.init(self, GUI, cw +  2 * self:paddingX(), ch + 2 * self:paddingY())
end
-- Pre-processes the content that need to be shown and calculates the space needed.
-- @ret(number) 
function BattlerWindow:preprocess()
  local primary = {}
  local secondary = {}
  for _, att in ipairs(Config.attributes) do
    if att.visibility == 1 then
      primary[#primary + 1] = att
    elseif att.visibility == 2 then
      secondary[#secondary + 1] = att
    end
  end
  self.primary, self.secondary = primary, secondary
  local elements = {}
  local eHeight = 0
  for i, e in ipairs(Config.elements) do
    if e.icon.id >= 0 then
      elements[#elements + 1] = {i, e.icon}
      local data = Database.animations[e.icon.id]
      eHeight = eHeight + data.quad.height * data.transform.scaleY / 100 / data.rows
    end
  end
  self.elements = elements
  local hsw = round(ScreenManager.width * 3 / 4)
  local hsh = 15 + max(10 * max(#primary, #secondary), eHeight)
  return hsw, hsh
end
-- Overrides Window:createContent.
function BattlerWindow:createContent(width, height)
  Window.createContent(self, width, height)
  -- Portrait
  self.portrait = SimpleImage(nil, self:paddingX() - self.width / 2, self:paddingY() - self.height / 2, 
      nil, round(self.width / 3) - self:paddingX(), self.height - self:paddingY() * 2)
  self.content:add(self.portrait)
  -- Content pos
  local x = round(self.width / 3 - self.width / 2 + self:paddingX())
  local y = round(self:paddingY() - self.height / 2)
  local w = round((self.width - self:paddingX()) / 4 - self:paddingX())
  -- Name
  self.textName = SimpleText('', Vector(x, y), w * 3, 'left', self.nameFont)
  self.content:add(self.textName)
  -- Attributes
  self.attValues = {}
  self:createAtts(self.primary, x, y + 5, w - self:paddingX())
  self:createAtts(self.secondary, x + w, y + 5, w - self:paddingX())
  -- Elements
  self.elementValues = {}
  self:createElements(self.elements, x + w * 2, y + 5, w - self:paddingX())
end
-- Creates the text content from a list of attributes.
-- @param(list : table) Array of attribute data.
-- @param(x : number) Pixel x of the texts.
-- @param(y : number) Initial pixel y of the texts.
-- @param(w : number) Pixel width of the text box.
function BattlerWindow:createAtts(list, x, y, w)
  for i, att in ipairs(list) do
    -- Attribute name
    local posName = Vector(x, y + 10 * i)
    local textName = SimpleText(att.shortName .. ':', posName, w - 30, 'left', self.font)
    -- Attribute value
    local posValue = Vector(x + 30, y + 10 * i)
    local textValue = SimpleText('', posValue, w, 'left', self.font)
    -- Store
    self.content:add(textName)
    self.content:add(textValue)
    self.attValues[att.key] = textValue
  end
end
-- Creates the text content from the list of elements.
-- @param(list : table) Array of (element id, icon) pairs. 
-- @param(x : number) Pixel x of the texts.
-- @param(y : number) Initial pixel y of the texts.
-- @param(w : number) Pixel width of the text box.
function BattlerWindow:createElements(list, x, y, w)
  local h = 0
  for i, e in ipairs(list) do
    -- Element icon
    local icon = ResourceManager:loadIcon(e[2], GUIManager.renderer)
    local iw, ih = icon:scaledBounds()
    local imgIcon = SimpleImage(icon, x, y + h, 0)
    h = h + ih
    -- Attribute value
    local posValue = Vector(x + iw, y + h - ih / 2 - 5)
    local textValue = SimpleText('', posValue, w - iw, 'left', self.font)
    -- Store
    self.content:add(imgIcon)
    self.content:add(textValue)
    self.elementValues[e[1]] = textValue
  end
end

---------------------------------------------------------------------------------------------------
-- Member
---------------------------------------------------------------------------------------------------

-- Shows the given member stats.
-- @param(member : Battler) The battler shown in the window.
function BattlerWindow:setMember(member)
  self:setPortrait(member)
  self.textName:setText(member.name)
  self.textName:redraw()
  -- Attributes
  for key, text in pairs(self.attValues) do
    -- Attribute value
    local total = round(member.att[key]())
    member.att.bonus = false
    local base = round(member.att:getBase(key))
    member.att.bonus = true
    local value = base .. ''
    if base < total then
      value = value .. ' + ' .. (total - base)
    elseif base > total then
      value = value .. ' - ' .. (base - total)
    end
    text:setText(value)
    text:redraw()
  end
  -- Elements
  for i, text in pairs(self.elementValues) do
    local total = round(member:elementDef(i) * 100) + 100
    if total < 100 then
      text.sprite:setColor(Color.element_strong)
    elseif total > 100 then
      text.sprite:setColor(Color.element_weak)
    else
      text.sprite:setColor(Color.element_neutral)
    end
    text:setText(total .. '%')
    text:redraw()
  end
  if not self.open then
    self:hideContent()
  end
end
-- Shows the graphics of the given member.
-- If they have a full body image, it is used. Otherwise, it uses the idle animation.
-- @param(member : Battler) The battler shown in the window.
function BattlerWindow:setPortrait(member)
  local charData = Database.characters[member.charID]
  local icon = findByName(charData.portraits, "BigIcon")
  if icon then
    local sprite = ResourceManager:loadIcon(icon, GUIManager.renderer)
    sprite.texture:setFilter('linear', 'linear')
    sprite:applyTransformation(charData.transform)
    self.portrait:setSprite(sprite)
  else
    local anim = findByName(charData.animations, "Idle") or 
      findByName(charData.animations, "Battle:Idle")
    self.portraitAnim = ResourceManager:loadAnimation(anim.id, GUIManager.renderer)
    self.portraitAnim:setRow(6)
    self.portraitAnim.sprite:setXYZ(0, 0, 0)
    self.portraitAnim.sprite:applyTransformation(charData.transform)
    self.portrait:setSprite(self.portraitAnim.sprite)
  end
  self.portrait:updatePosition(self.position)
end

---------------------------------------------------------------------------------------------------
-- Input
---------------------------------------------------------------------------------------------------

-- Overrides Window:onConfirm.
function BattlerWindow:onConfirm()
  self:onCancel()
end
-- Overrides Window:onCancel.
function BattlerWindow:onCancel()
  AudioManager:playSFX(Config.sounds.buttonCancel)
  self.result = 0
end
-- Called when player presses "next" key.
function BattlerWindow:onNext()
  if self.GUI.nextMember then
    AudioManager:playSFX(Config.sounds.buttonSelect)
    self.GUI:nextMember()
  end
end
-- Called when player presses "prev" key.
function BattlerWindow:onPrev()
  if self.GUI.prevMember then
    AudioManager:playSFX(Config.sounds.buttonSelect)
    self.GUI:prevMember()
  end
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

-- @ret(string) String representation (for debugging).
function BattlerWindow:__tostring()
  return 'Battler Description Window'
end

return BattlerWindow
