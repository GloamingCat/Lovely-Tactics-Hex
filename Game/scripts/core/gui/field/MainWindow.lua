
--[[===============================================================================================

MainWindow
---------------------------------------------------------------------------------------------------
Main GUI's selectable window.

=================================================================================================]]

-- Imports
local Button = require('core/gui/Button')
local ButtonWindow = require('core/gui/ButtonWindow')

local MainWindow = class(ButtonWindow)

function MainWindow:createButtons()
  Button(self, Vocab.items, nil, self.onItems)
  Button(self, Vocab.skills, nil, self.onSkills)
  Button(self, Vocab.states, nil, self.onStates)
  Button(self, Vocab.party, nil, self.onParty)
  Button(self, Vocab.config, nil, self.onConfig)
  Button(self, Vocab.save, nil, self.onSave)
  Button(self, Vocab.quit, nil, self.onQuit)
end

---------------------------------------------------------------------------------------------------
-- Character
---------------------------------------------------------------------------------------------------

function MainWindow:onItems()
  
end

function MainWindow:onSkills()
  
end

function MainWindow:onStates()
  
end

function MainWindow:selectCharacter()
  
end

---------------------------------------------------------------------------------------------------
-- General
---------------------------------------------------------------------------------------------------

function MainWindow:onParty()
  
end

function MainWindow:onConfig()
  
end

function MainWindow:onSave()
  
end

function MainWindow:onQuit()
  
end

---------------------------------------------------------------------------------------------------
-- Properties
---------------------------------------------------------------------------------------------------

function MainWindow:colCount()
  return 2
end

function MainWindow:rowCount()
  return 4
end

return MainWindow


