
--[[===============================================================================================

BattlerWindow
---------------------------------------------------------------------------------------------------
Window that shows on each character in the VisualizeAction.
TODO

=================================================================================================]]

-- Imports
local Vector = require('core/math/Vector')
local Sprite = require('core/graphics/Sprite')
local Window = require('core/gui/Window')
local SimpleText = require('core/gui/SimpleText')

-- Alias
local round = math.round
local max = math.max

-- Constants
local attConfig = Config.attributes

local BattlerWindow = class(Window)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

local old_init = BattlerWindow.init
function BattlerWindow:init(GUI, skin)
  local hsw = round(ScreenManager.width / 2)
  local hsh = round(ScreenManager.height / 2)
  old_init(self, GUI, hsw, hsh, hsw * 2 - 80, hsh * 2 - 80, skin)
end

-- Overrides Window:createContent.
local old_createContent = BattlerWindow.createContent
function BattlerWindow:createContent()
  old_createContent(self)
  local battler = BattleManager.currentAction.currentTarget.characterList[1].battler
  
  local lineCount = 0
  
  for i = 1, #attConfig do
    local att = attConfig[i]
    if att.script == '' then
      local str1 = att.shortName .. ': ' .. att[att.shortName]()
      local text = SimpleText(str1)
      lineCount = lineCount + 1
    end
  end
  self.width = self.paddingw * 2 + 100
  self.height = max(lineCount * 20, self.portrait:getHeight()) + self.paddingh * 2
  old_createContent(self)
end

return BattlerWindow