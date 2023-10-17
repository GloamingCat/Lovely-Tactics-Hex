
-- ================================================================================================

--- A window that contains options after game over.
-- Result codes:
--  * 1 -> continue
--  * 2 -> retry
--  * 3 -> title screen
-- ------------------------------------------------------------------------------------------------
-- @classmod GameOverWindow

-- ================================================================================================

-- Imports
local Button = require('core/gui/widget/control/Button')
local GridWindow = require('core/gui/GridWindow')

-- Class table.
local GameOverWindow = class(GridWindow)

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Constructor.
function GameOverWindow:createWidgets()
  Button:fromKey(self, 'continue')
  Button:fromKey(self, 'retry')
  Button:fromKey(self, 'title')
end

-- ------------------------------------------------------------------------------------------------
-- Buttons
-- ------------------------------------------------------------------------------------------------

--- Check if the game mey the continued even if the player lost.
function GameOverWindow:continueEnabled()
  return not BattleManager:isGameOver()
end
--- Prevents player from returning the window.
function GameOverWindow:onCancel()
end

-- ------------------------------------------------------------------------------------------------
-- Properties
-- ------------------------------------------------------------------------------------------------

--- Overrides GridWindow:colCount.
function GameOverWindow:colCount()
  return 1
end
--- Overrides GridWindow:rowCount.
function GameOverWindow:rowCount()
  return 3
end
-- @treturn string String representation (for debugging).
function GameOverWindow:__tostring()
  return 'Game Over Window'
end

return GameOverWindow
