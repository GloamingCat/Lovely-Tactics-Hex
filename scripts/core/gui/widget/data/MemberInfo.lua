
-- ================================================================================================

--- A container for a battler's main information.
---------------------------------------------------------------------------------------------------
-- @uimod MemberInfo
-- @extend Component

-- ================================================================================================

-- Imports
local Component = require('core/gui/Component')
local Gauge = require('core/gui/widget/Gauge')
local IconList = require('core/gui/widget/data/IconList')
local ImageComponent = require('core/gui/widget/ImageComponent')
local TextComponent = require('core/gui/widget/TextComponent')
local Vector = require('core/math/Vector')

-- Alias
local findByName = util.array.findByName

-- Class table.
local MemberInfo = class(Component)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
-- @tparam table battler Battler's data.
-- @tparam number width Width of the container.
-- @tparam number height Height of the container.
-- @tparam Vector topLeft The position of the top left corner of the container.
function MemberInfo:init(battler, width, height, topLeft)
  Component.init(self, topLeft, width, height, battler)
  self.battler = battler
end
--- Implements `Component:setProperties`.
-- @implement
function MemberInfo:setProperties()
  self.margin = 4
  self.nameHeight = 17
  self.barHeight = 11
  self.statusMargin = 8
  self.statusHeight = 20
end
--- Overrides `Component:createContent`. 
-- @override
function MemberInfo:createContent(w, h, battler)
  local topLeft = Vector(0, 1, -2)
  -- Icon
  local charData = Database.characters[battler.charID]
  local icon = findByName(charData.portraits, "SmallIcon")
  if icon then
    local sprite = ResourceManager:loadIcon(icon, MenuManager.renderer)
    sprite.texture:setFilter('linear', 'linear')
    sprite:applyTransformation(charData.transform)
    local x1, y1, x2, y2 = sprite:getBoundingBox()
    local iconW = x2 - x1
    self.icon = ImageComponent(sprite, Vector(0, 0, -2), iconW, h)   
    topLeft.x = topLeft.x + iconW + self.margin
    w = w - iconW - self.margin
    self.content:add(self.icon)
  end
  local rw = w / 2 - self.margin
  local small = Fonts.menu_small
  local tiny = Fonts.menu_tiny
  local medium = Fonts.menu_medium
  -- Name
  local txtName = TextComponent(battler.name, topLeft, rw, 'left', medium)
  txtName:setTerm('data.battler.' .. battler.key, battler.name) 
  txtName:redraw()
  self.content:add(txtName)
  -- HP
  local middleLeft = Vector(topLeft.x, topLeft.y + self.nameHeight, topLeft.z)
  local txtHP = TextComponent(Vocab.hp, middleLeft, rw, 'left', small)
  txtHP:setTerm('hp', '') 
  txtHP:redraw()
  self.content:add(txtHP)
  -- SP
  local bottomLeft = Vector(middleLeft.x, middleLeft.y + self.barHeight, middleLeft.z)
  local txtSP = TextComponent(Vocab.sp, bottomLeft, rw, 'left', small)
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
  -- Level / Class
  local middleRight = Vector(middleLeft.x + rw + self.margin, middleLeft.y, middleLeft.z)
  local job = battler.job.data
  local txtLevel = TextComponent('', middleRight, rw, 'left', small)
  txtLevel:setTerm('{%level} ' .. battler.job.level)
  txtLevel:redraw()
  local txtJob = TextComponent('', middleRight, rw, 'right', small)
  txtJob:setTerm('data.job.' .. job.key, job.name)
  txtJob:redraw()
  self.content:add(txtLevel)
  self.content:add(txtJob)
  -- EXP
  local bottomRight = Vector(middleRight.x, middleRight.y + self.barHeight, middleRight.z)
  local txtEXP = TextComponent('', bottomRight, rw, 'left', small)
  txtEXP:setTerm('exp', '')
  txtEXP:redraw()
  self.content:add(txtEXP)
  -- EXP gauge
  local gaugeEXP = Gauge(bottomRight, rw, Color.barEXP, 2 + txtEXP.sprite:getWidth())
  gaugeEXP:setValues(battler.job:nextLevelEXP())
  self.content:add(gaugeEXP)
  -- Status
  local topRight = Vector(topLeft.x + rw + self.margin + self.statusMargin, topLeft.y + self.statusMargin, topLeft.z - 20)
  local status = IconList(topRight, rw, self.statusHeight)
  status:setIcons(battler.statusList:getIcons())
  self.content:add(status)
end

return MemberInfo
