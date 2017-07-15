
--[[===============================================================================================

Test script
---------------------------------------------------------------------------------------------------
An example of usage of an eventsheet for a Field.

=================================================================================================]]

-- Imports
local Window = require('core/gui/Window')

local function testBattle()
  local party, result = FieldManager:loadBattle(1)
  if BattleManager:playerWon() then
    print 'You won!'
  elseif BattleManager:enemyWon() then
    print 'You lost...'
  elseif BattleManager:drawed() then
    print 'Draw.'
  elseif BattleManager:playerEscaped() then
    print 'You escaped!'
  elseif BattleManager:enemyEscaped() then
    print 'The enemy escaped...'
  end
end

return function(param, event, ...)
 --[[ local transition = FieldManager:getPlayerTransition()
  transition.fieldID = 1
  self:wait(90)
  transition.tileX = transition.tileX + 10
  --FieldManager:loadBattle(1)
  FieldManager:loadTransition(transition)
  self:wait(90)
  transition.tileY = transition.tileY + 10
  FieldManager:loadTransition(transition)
  self:wait(90)]]
  --testBattle()
end
