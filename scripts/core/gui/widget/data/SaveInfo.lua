
-- ================================================================================================

--- A container for a battler's main information.
---------------------------------------------------------------------------------------------------
-- @uimod SaveInfo
-- @extend Component

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local IconList = require('core/gui/widget/data/IconList')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')

-- Alias
local findByName = util.array.findByName

-- Class table.
local SaveInfo = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Implements `Component:setProperties`. 
-- @implement
function SaveInfo:setProperties()
  self.paddingX = 2
  self.paddingY = 3
  self.iconSize = 20
  self.lineHeight = 10
  self.iconBorder = 2
end
--- Implements `Component:createContent`. 
-- @implement
function SaveInfo:createContent(w, h)
  local x, y, z = self.paddingX, 0, -2
  local small = Fonts.menu_small
  local tiny = Fonts.menu_tiny
  local medium = Fonts.medium
  -- No save
  local txtName = TextComponent('', Vector(x, y, z), w, 'left', medium)
  txtName.sprite.alignX = 'center'
  txtName.sprite.alignY = 'center'
  txtName.sprite.maxHeight = h
  self.content:add(txtName)
  -- PlayTime
  local top = Vector(x, y + self.paddingY, z)
  local txtTime = TextComponent('', top, w, 'right', small)
  self.content:add(txtTime)
  -- Gold
  local middle = Vector(x, top.y + self.lineHeight, z)
  local txtGold = TextComponent('', middle, w , 'right', small)
  self.content:add(txtGold)
  -- Location
  local bottom = Vector(x, middle.y + self.lineHeight, middle.z)
  local txtLocal = TextComponent('', bottom, w, 'left', small)
  self.content:add(txtLocal)
  -- Chars
  local iconPos = Vector(x + self.iconSize / 2, y + self.iconSize / 2 + self.paddingX, z)
  local iconList = IconList(iconPos, w, self.iconSize, self.iconSize, self.iconSize)
  iconList.iconWidth = self.iconSize - self.iconBorder
  iconList.iconHeight = self.iconSize - self.iconBorder
  self.content:add(iconList)
end

-- ------------------------------------------------------------------------------------------------
-- Refresh
-- ------------------------------------------------------------------------------------------------

--- Sets text and icons according to given save header.
-- @tparam table save Save header. Nil if no save.
function SaveInfo:refreshInfo(save)
  assert(self.content.size == 5, 'Save info content not initialized.')
  if not save then
    for i = 2, 4 do
      self.content[i]:setText('')
      self.content[i]:redraw()
    end
    self.content[5]:setSprites({})
    self.content[1]:setTerm('{%noSave}', '')
    self.content[1]:redraw()
    return
  end
  self.content[2]:setText(string.time(save.playTime))
  self.content[2]:redraw()
  self.content[3]:setTerm(save.money .. ' {%g}', save.money .. '')
  self.content[3]:redraw()  
  self.content[4]:setTerm('{%data.field.' .. (save.field or '') .. '}', save.location)
  self.content[4]:redraw()
  local icons = {}
  for i = 1, Config.troop.maxMembers do
    if save.members[i] then
      local charData = Database.characters[save.members[i]]
      local applyTransform = charData.transformPortraits
      local icon = findByName(charData.portraits, "TinyIcon")
      if not icon then
        icon = { col = 0, row = 7, id = findByName(charData.animations, "Idle").id }
        applyTransform = charData.transformAnimations
      end
      local sprite = ResourceManager:loadIcon(icon, MenuManager.renderer)
      if applyTransform then
        sprite:applyTransformation(charData.transform)
      end
      sprite:setCenterOffset()
      icons[i] = sprite
    else
      icons[i] = false
    end
  end
  self.content[5]:setSprites(icons)
end

return SaveInfo
