
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

--- Overrides `Component:createContent`. 
-- @override
function SaveInfo:createContent(w, h)
  local margin = 4
  local x, y, z = 2, 0, -2
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
  local topRight = Vector(x, y + 3, z)
  local txtTime = TextComponent('', topRight, w, 'right', small)
  self.content:add(txtTime)
  -- Gold
  local middleLeft = Vector(x, y + 13, z)
  local txtGold = TextComponent('', middleLeft, w , 'right', small)
  self.content:add(txtGold)
  -- Location
  local bottomLeft = Vector(middleLeft.x, middleLeft.y + 10, middleLeft.z)
  local txtLocal = TextComponent('', bottomLeft, w, 'left', small)
  self.content:add(txtLocal)
  -- Chars
  local iconList = IconList(Vector(x + 10, y + 12), w, 20, 20, 20)
  iconList.iconWidth = 18
  iconList.iconHeight = 18
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
    self.content[1]:setTerm('noSave', '')
    self.content[1]:redraw()
    return
  end
  self.content[2]:setText(string.time(save.playTime))
  self.content[2]:redraw()
  self.content[3]:setTerm(save.money .. ' {%g}', save.money .. '')
  self.content[3]:redraw()  
  self.content[4]:setTerm('data.field.' .. (save.field or ''), save.location)
  self.content[4]:redraw()  
  local icons = {}
  for i = 1, Config.troop.maxMembers do
    if save.members[i] then
      local charData = Database.characters[save.members[i]]
      local icon = { col = 0, row = 7,
        id = findByName(charData.animations, "Idle").id }
      local sprite = ResourceManager:loadIcon(icon, MenuManager.renderer)
      sprite:applyTransformation(charData.transform)
      sprite:setCenterOffset()
      icons[i] = sprite
    else
      icons[i] = false
    end
  end
  self.content[5]:setSprites(icons)
end

return SaveInfo
