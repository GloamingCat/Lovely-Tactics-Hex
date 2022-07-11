
--[[===============================================================================================

SaveInfo
---------------------------------------------------------------------------------------------------
A container for a battler's main information.

=================================================================================================]]

-- Imports
local Component = require('core/gui/Component')
local IconList = require('core/gui/widget/data/IconList')
local SimpleImage = require('core/gui/widget/SimpleImage')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

-- Alias
local findByName = util.array.findByName

local SaveInfo = class(Component)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(file : string) Save file name.
-- @param(width : number) Width of the container.
-- @param(height : number) Height of the container.
-- @param(topLeft : Vector) The position of the top left corner of the container.
function SaveInfo:init(file, width, height, topLeft)
  Component.init(self, topLeft, width, height, SaveManager.saves[file])
  self.file = file
end
-- Overrides Component:createContent.
function SaveInfo:createContent(w, h, save)
  local margin = 4
  local x, y, z = 2, 0, -2
  local small = Fonts.gui_small
  local tiny = Fonts.gui_tiny
  local medium = Fonts.medium
  if save then
    -- PlayTime
    local topRight = Vector(x, y + 3, z)
    local txtTime = SimpleText(string.time(save.playTime), topRight, w, 'right', small)
    self.content:add(txtTime)
    -- Gold
    local middleLeft = Vector(x, y + 13, z)
    local txtGold = SimpleText(save.money .. ' ' .. Vocab.g, middleLeft, w , 'right', small)
    self.content:add(txtGold)
    -- Location
    local bottomLeft = Vector(middleLeft.x, middleLeft.y + 10, middleLeft.z)
    local txtLocal = SimpleText(save.location, bottomLeft, w, 'left', small)
    self.content:add(txtLocal)
    -- Chars
    local icons = {}
    for i = 1, Config.troop.maxMembers do
      if save.members[i] then
        local charData = Database.characters[save.members[i]]
        local icon = { col = 0, row = 7,
          id = findByName(charData.animations, "Idle").id }
        local sprite = ResourceManager:loadIcon(icon, GUIManager.renderer)
        sprite:applyTransformation(charData.transform)
        sprite:setCenterOffset()
        icons[i] = sprite
      else
        icons[i] = false
      end
    end
    local iconList = IconList(Vector(x + 10, y + 12), w, 20, 20, 20)
    iconList.iconWidth = 18
    iconList.iconHeight = 18
    iconList:setSprites(icons)
    self.content:add(iconList)
  else
    local txtName = SimpleText(Vocab.noSave, Vector(x, y, z), w, 'left', medium)
    txtName.sprite.alignX = 'center'
    txtName.sprite.alignY = 'center'
    txtName.sprite.maxHeight = h
    self.content:add(txtName)
  end
end

return SaveInfo
