
--[[===============================================================================================

TargetWindow
---------------------------------------------------------------------------------------------------
Window that shows when the battle cursor is over a character.

=================================================================================================]]

-- Imports
local Gauge = require('core/gui/widget/Gauge')
local IconList = require('core/gui/widget/data/IconList')
local SimpleText = require('core/gui/widget/SimpleText')
local Sprite = require('core/graphics/Sprite')
local Vector = require('core/math/Vector')
local Window = require('core/gui/Window')

local TargetWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Overrides Window:init.
function TargetWindow:init(GUI)
  local w = 120
  local h = self:computeHeight()
  local margin = GUI:windowMargin()
  Window.init(self, GUI, w, h, Vector(ScreenManager.width / 2 - w / 2 - margin, 
      -ScreenManager.height / 2 + h / 2 + margin))
end
-- Initializes name and status texts.
function TargetWindow:createContent(width, height)
  Window.createContent(self, width, height)
  local font = Fonts.gui_small
  -- Top-left position
  local x = -self.width / 2 + self:paddingX()
  local y = -self.height / 2 + self:paddingY()
  local w = self.width - self:paddingX() * 2
  -- Name text
  local posName = Vector(x, y - 1)
  self.textName = SimpleText('', posName, w, 'center')
  self.content:add(self.textName)
  -- Class text
  local posJob = Vector(x, y + 15)
  self.txtJob = SimpleText('', posJob, w, 'right', font)
  self.content:add(self.txtJob)
  -- Level text
  self.txtLevel = SimpleText('', posJob, w, 'left', font)
  self.content:add(self.txtLevel)
  -- State values texts
  local posHP = Vector(x, y + 25, -2)
  self.gaugeHP = self:addStateVariable('hp', posHP, w, Color.barHP)
  local posSP = Vector(x, y + 35, -2)
  self.gaugeSP = self:addStateVariable('sp', posSP, w, Color.barSP)
  -- Icon List
  local posIcons = Vector(x + 8, y + 55)
  self.iconList = IconList(posIcons, w, 16)
  self.content:add(self.iconList)
  collectgarbage('collect')
end
-- Creates texts for the given state variable.
-- @param(name : string) the name of the variable
-- @param(pos : Vector) the position of the text
-- @param(w : width) the max width of the text
function TargetWindow:addStateVariable(name, pos, w, barColor)
  local textName = SimpleText('', pos, w, 'left', Fonts.gui_small)
  textName:setTerm(name, name)
  textName:redraw()
  self.content:add(textName)
  local gauge = Gauge(pos, w, barColor, 30)
  self.content:add(gauge)
  return gauge
end

---------------------------------------------------------------------------------------------------
-- Content
---------------------------------------------------------------------------------------------------

-- Changes the window's content to show the given battler's stats.
-- @param(battler : Battler)
function TargetWindow:setBattler(battler)
  local icons = battler.statusList:getIcons()
  local height = self:computeHeight(#icons > 0)
  local job = battler.job.data
  local y = (height - self.height) / 2
  self.background.position.y = self.background.position.y + y
  self.frame.position.y = self.frame.position.y + y
  self:resize(nil, height)
  -- Name text
  self.textName:setTerm('data.battler.' .. battler.data.key, battler.name)
  self.textName:redraw()
  -- Class text
  self.txtJob:setTerm('data.job.' .. job.key, job.name)
  self.txtJob:redraw()
  -- Level text
  self.txtLevel:setTerm('{%level} ' .. battler.job.level, battler.job.level)
  self.txtLevel:redraw()
  -- HP Gauge
  self.gaugeHP:setValues(battler.state.hp, battler.mhp())
  -- SP Gauge
  self.gaugeSP:setValues(battler.state.sp, battler.msp())
  -- Status icons
  self.iconList:setIcons(icons)
  self.iconList:updatePosition(self.position)
  if not self.open then
    self.iconList:hide()
  end
  collectgarbage('collect')
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Calculates the height given the shown variables.
function TargetWindow:computeHeight(showStatus)
  -- Margin + name + job/level + HP + SP
  local h = self:paddingY() * 2 + 15 + 10 + 10 + 10
  return showStatus and h + 16 or h
end
-- String representation.
function TargetWindow:__tostring()
  return 'Battle Target Window'
end

return TargetWindow
