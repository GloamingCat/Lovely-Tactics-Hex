
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
--- Overrides `Component:createContent`. 
-- @override
function MemberInfo:createContent(w, h, battler)
  local topLeft = Vector(0, 1, -2)
  local margin = 4
  -- Icon
  local charData = Database.characters[battler.charID]
  local icon = findByName(charData.portraits, "SmallIcon")
  if icon then
    local sprite = ResourceManager:loadIcon(icon, MenuManager.renderer)
    sprite.texture:setFilter('linear', 'linear')
    sprite:applyTransformation(charData.transform)
    self.icon = ImageComponent(sprite, topLeft.x, topLeft.y, topLeft.z, nil, h)   
    local ix, iy, iw, ih = sprite:totalBounds()
    topLeft.x = topLeft.x + iw + margin
    w = w - iw - margin
    self.content:add(self.icon)
  end
  local rw = (w - margin) / 2
  local small = Fonts.menu_small
  local tiny = Fonts.menu_tiny
  local medium = Fonts.menu_medium
  -- Name
  local txtName = TextComponent(battler.name, topLeft, rw, 'left', medium)
  txtName:setTerm('data.battler.' .. battler.key, battler.name) 
  txtName:redraw()
  self.content:add(txtName)
  -- HP
  local middleLeft = Vector(topLeft.x, topLeft.y + 17, topLeft.z)
  local txtHP = TextComponent(Vocab.hp, middleLeft, rw, 'left', small)
  txtHP:setTerm('hp', '') 
  txtHP:redraw()
  self.content:add(txtHP)
  -- SP
  local bottomLeft = Vector(middleLeft.x, middleLeft.y + 11, middleLeft.z)
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
  -- Status
  local topRight = Vector(topLeft.x + rw + margin + 8, topLeft.y + 8, topLeft.z - 20)
  local status = IconList(topRight, rw, 20)
  status:setIcons(battler.statusList:getIcons())
  self.content:add(status)
  -- Level / Class
  local middleRight = Vector(topRight.x - 7, topRight.y + 8, topRight.z)
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
  local bottomRight = Vector(middleRight.x, middleRight.y + 11, middleRight.z)
  local txtEXP = TextComponent('', bottomRight, rw, 'left', small)
  txtEXP:setTerm('exp', '')
  txtEXP:redraw()
  self.content:add(txtEXP)
  -- EXP gauge
  local gaugeEXP = Gauge(bottomRight, rw, Color.barEXP, 2 + txtEXP.sprite:getWidth())
  gaugeEXP:setValues(battler.job:nextLevelEXP())
  self.content:add(gaugeEXP)
end

return MemberInfo
