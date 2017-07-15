
--[[===============================================================================================

MainWindow
---------------------------------------------------------------------------------------------------
Main GUI's selectable window.

=================================================================================================]]

local ButtonWindow = require('core/gui/ButtonWindow')

local MainWindow = class(ButtonWindow)

function MainWindow:createButtons()
  self:addButton(Vocab.items, nil, self.onItems)
  self:addButton(Vocab.skills, nil, self.onSkills)
  self:addButton(Vocab.states, nil, self.onStates)
  self:addButton(Vocab.party, nil, self.onParty)
  self:addButton(Vocab.config, nil, self.onConfig)
  self:addButton(Vocab.save, nil, self.onSave)
  self:addButton(Vocab.quit, nil, self.onQuit)
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


