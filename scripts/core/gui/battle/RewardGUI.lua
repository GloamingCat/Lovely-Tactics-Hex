
--[[===============================================================================================

RewardGUI
---------------------------------------------------------------------------------------------------
The GUI that is shown in the end of the battle.

=================================================================================================]]

-- Imports
local GUI = require('core/gui/GUI')
local Inventory = require('core/battle/Inventory')
local RewardEXPWindow = require('core/gui/battle/window/RewardEXPWindow')
local RewardItemWindow = require('core/gui/battle/window/RewardItemWindow')
local Vector = require('core/math/Vector')
local Text = require('core/graphics/Text')

-- Alias
local floor = math.floor

local RewardGUI = class(GUI)

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Implements GUI:createWindows.
function RewardGUI:createWindows()
  self.name = 'Reward GUI'
  self:createTopText()
  -- Reward windows
  local w = (ScreenManager.width - self:windowMargin() * 3) / 2
  local h = ScreenManager.height - self.topText:getHeight() - self:windowMargin() * 3
  local x = ScreenManager.width / 2 - w / 2 - self:windowMargin()
  local y = ScreenManager.height / 2 - h / 2 - self:windowMargin()
  self.troop = TroopManager:getPlayerTroop()
  self.rewards = self:getBattleRewards()
  self:createEXPWindow(x, y, w, h)
  self:createItemWindow(x, y, w, h)
  self:setActiveWindow(self.expWindow)
  -- Gold / items
  self.troop.money = self.troop.money + self.rewards.money
  self.troop.inventory:addAllItems(self.rewards.items)
end
-- Creates the text at the top of the screen to show that the player won.
function RewardGUI:createTopText()
  local prop = { ScreenManager.width,
    'center', Fonts.gui_huge }
  self.topText = Text(Vocab.win, prop, GUIManager.renderer)
  local x = -ScreenManager.width / 2
  local y = -ScreenManager.height / 2 + self:windowMargin() * 2
  self.topText:setXYZ(x, y)
  self.topText:setVisible(false)
  self.topTextSpeed = 2
end
-- Creates the window that shows battle results.
function RewardGUI:createEXPWindow(x, y, w, h)
  local pos = Vector(-x, y)
  local window = RewardEXPWindow(self, w, h, pos)
  self.expWindow = window
end
-- Creates the window that shows battle results.
function RewardGUI:createItemWindow(x, y, w, h)
  local pos = Vector(x, y)
  local window = RewardItemWindow(self, w, h, pos)
  self.itemWindow = window
end

---------------------------------------------------------------------------------------------------
-- Rewards
---------------------------------------------------------------------------------------------------

-- Creates a table of reward from the current state of the battle field.
-- @ret(table) Table with exp per battler, items and money.
function RewardGUI:getBattleRewards()
  local r = { exp = {},
    items = Inventory(),
    money = 0 }
  -- List of living party members
  local characters = TroopManager:currentCharacters(self.troop.party, true)
  -- Rewards per troop
  for party, troop in pairs(TroopManager.troops) do
    if troop ~= self.troop then
      -- Troop items
      r.items:addAllItems(troop.inventory)
      -- Troop money
      r.money = r.money + troop.money
      -- Rewards per enemy
      for enemy in TroopManager:currentCharacters(party, false):iterator() do
        -- Enemy EXP
        for char in characters:iterator() do
          r.exp[char.key] = (r.exp[char.key] or 0) + enemy.battler.data.exp
        end
        -- Enemy items
        r.items:addAllItems(enemy.battler.inventory)
        -- Enemy money
        r.money = r.money + enemy.battler.data.money
      end
    end
  end
  return r
end

---------------------------------------------------------------------------------------------------
-- Show
---------------------------------------------------------------------------------------------------

-- Show top text before openning windows.
function RewardGUI:show(...)
  self:showTopText()
  _G.Fiber:wait(15)
  GUI.show(self, ...)
end
-- Animation that shows the text at the top.
function RewardGUI:showTopText()
  if AudioManager.victoryTheme then
    AudioManager:playBGM(AudioManager.victoryTheme)
  end
  local a = 0
  self.topText:setVisible(true)
  self.topText:setRGBA(nil, nil, nil, 0)
  while a < 1 do
    a = a + GameManager:frameTime() * self.topTextSpeed
    self.topText:setRGBA(nil, nil, nil, a)
    coroutine.yield()
  end
  self.topText:setRGBA(nil, nil, nil, 1)
end

---------------------------------------------------------------------------------------------------
-- Hide
---------------------------------------------------------------------------------------------------

-- Hide top text after closing windows.
function RewardGUI:hide(...)
  GUI.hide(self, ...)
  self:hideTopText()
end
-- Animation that shows the text at the top.
function RewardGUI:hideTopText()
  if AudioManager.victoryTheme then
    AudioManager:pauseBGM(120 / self.topTextSpeed, true)
  end
  local a = 1
  while a > 0 do
    a = a - GameManager:frameTime() * self.topTextSpeed
    self.topText:setRGBA(nil, nil, nil, a)
    coroutine.yield()
  end
  self.topText:setVisible(false)
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

-- Overrides GUI:destroy to destroy top text.
function RewardGUI:destroy(...)
  GUI.destroy(self, ...)
  self.topText:destroy()
end

return RewardGUI
