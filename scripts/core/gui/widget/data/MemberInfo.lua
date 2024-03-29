
--[[===============================================================================================

MemberInfo
---------------------------------------------------------------------------------------------------
A container for a battler's main information.

=================================================================================================]]

-- Imports
local Component = require('core/gui/Component')
local Gauge = require('core/gui/widget/Gauge')
local IconList = require('core/gui/widget/data/IconList')
local SimpleImage = require('core/gui/widget/SimpleImage')
local SimpleText = require('core/gui/widget/SimpleText')
local Vector = require('core/math/Vector')

-- Alias
local findByName = util.array.findByName

local MemberInfo = class(Component)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- @param(battler : table) Battler's data.
-- @param(width : number) Width of the container.
-- @param(height : number) Height of the container.
-- @param(topLeft : Vector) The position of the top left corner of the container.
function MemberInfo:init(battler, width, height, topLeft)
  Component.init(self, topLeft, width, height, battler)
  self.battler = battler
end
-- Overrides Component:createContent.
function MemberInfo:createContent(w, h, battler)
  local topLeft = Vector(0, 1, -2)
  local margin = 4
  -- Icon
  local charData = Database.characters[battler.charID]
  local icon = findByName(charData.portraits, "SmallIcon")
  if icon then
    local sprite = ResourceManager:loadIcon(icon, GUIManager.renderer)
    sprite.texture:setFilter('linear', 'linear')
    sprite:applyTransformation(charData.transform)
    self.icon = SimpleImage(sprite, topLeft.x, topLeft.y, topLeft.z, nil, h)   
    local ix, iy, iw, ih = sprite:totalBounds()
    topLeft.x = topLeft.x + iw + margin
    w = w - iw - margin
    self.content:add(self.icon)
  end
  local rw = (w - margin) / 2
  local small = Fonts.gui_small
  local tiny = Fonts.gui_tiny
  local medium = Fonts.gui_medium
  -- Name
  local txtName = SimpleText(battler.name, topLeft, rw, 'left', medium)
  txtName:setTerm('data.battler.' .. battler.key, battler.name) 
  txtName:redraw()
  self.content:add(txtName)
  -- HP
  local middleLeft = Vector(topLeft.x, topLeft.y + 17, topLeft.z)
  local txtHP = SimpleText(Vocab.hp, middleLeft, rw, 'left', small)
  txtHP:setTerm('hp', '') 
  txtHP:redraw()
  self.content:add(txtHP)
  -- SP
  local bottomLeft = Vector(middleLeft.x, middleLeft.y + 11, middleLeft.z)
  local txtSP = SimpleText(Vocab.sp, bottomLeft, rw, 'left', small)
  txtSP:setTerm('sp', '') 
  txtSP:redraw()
  self.content:add(txtSP)
  -- HP gauge
  local gaugeX = 2 + math.max(txtSP.sprite:getWidth(), txtHP.sprite:getWidth())
  local gaugeHP = Gauge(middleLeft, rw, Color.barHP, gaugeX)
  gaugeHP:setValues(battler.state.hp, battler.mhp())
  self.content:add(gaugeHP)
  -- SP gauge
  local gaugeSP = Gauge(bottomLeft, rw, Color.barSP, gaugeX)
  gaugeSP:setValues(battler.state.sp, battler.msp())
  self.content:add(gaugeSP)
  -- Status
  local topRight = Vector(topLeft.x + rw + margin + 8, topLeft.y + 8, topLeft.z - 20)
  local status = IconList(topRight, rw, 20)
  status:setIcons(battler.statusList:getIcons())
  self.content:add(status)
  -- Level / Class
  local middleRight = Vector(topRight.x - 7, topRight.y + 8, topRight.z)
  local job = battler.job.data
  local txtLevel = SimpleText('', middleRight, rw, 'left', small)
  txtLevel:setTerm('{%level} ' .. battler.job.level)
  txtLevel:redraw()
  local txtJob = SimpleText('', middleRight, rw, 'right', small)
  txtJob:setTerm('data.job.' .. job.key, job.name)
  txtJob:redraw()
  self.content:add(txtLevel)
  self.content:add(txtJob)
  -- EXP
  local bottomRight = Vector(middleRight.x, middleRight.y + 11, middleRight.z)
  local txtEXP = SimpleText('', bottomRight, rw, 'left', small)
  txtEXP:setTerm('exp', '')
  txtEXP:redraw()
  self.content:add(txtEXP)
  -- EXP gauge
  local gaugeEXP = Gauge(bottomRight, rw, Color.barEXP, 2 + txtEXP.sprite:getWidth())
  gaugeEXP:setValues(battler.job:nextLevelEXP())
  self.content:add(gaugeEXP)
end

return MemberInfo
