
--[[===============================================================================================

DialoguePortrait
---------------------------------------------------------------------------------------------------
Indents the dialogue text to fit the speaker's portrait, shown above window.

-- Plugin parameters:
Use <indent> to fix an indentation length instead of using portrait's width.

=================================================================================================]]

-- Parameters
local indent = tonumber(args.indent)

-- Imports
local DialogueWindow = require('core/gui/common/window/interactable/DialogueWindow')
local EventSheet = require('core/fiber/EventSheet')
local SimpleImage = require('core/gui/widget/SimpleImage')

---------------------------------------------------------------------------------------------------
-- DialogueWindow
---------------------------------------------------------------------------------------------------

-- Shows the portrait of the speaker.
-- @param(icon : table) Table with id, col and row values. It may also contain char and name 
--   values, which indicates a portrait of the given character.
function DialogueWindow:setPortrait(icon)
  if self.portrait then
    self.portrait:destroy()
    self.content:removeElement(self.portrait)
    self.portrait = nil
  end
  self.indent = 0
  local char = nil
  if icon and not icon.id and icon.char then
    char = icon.char
    icon = char.portraits[icon.name]
  end
  if icon and icon.id >= 0 then
    local portrait = ResourceManager:loadIcon(icon, GUIManager.renderer)
    if char then
      portrait:applyTransformation(char.data.transform)
    end
    local ox, oy = portrait.offsetX, portrait.offsetY
    portrait:setOffset(0, 0)
    local x, y, w, h = portrait:totalBounds()
    x = -self.width / 2 + x + w / 2 + self:paddingX() - ox
    y = self.height / 2 - h / 2 - self:paddingY() - oy
    portrait:setOffset(ox, oy)
    self.portrait = SimpleImage(portrait, x - w / 2, y - h / 2, 1)
    self.portrait:updatePosition(self.position)
    self.content:add(self.portrait)
    self.indent = w
  end
end
-- Override. Sets default name window position.
local DialogueWindow_createContent = DialogueWindow.createContent
function DialogueWindow:createContent(width, height)
  DialogueWindow_createContent(self, width, height)
  local nameX = self.position.x - 0.45 * self.width / 2
  local nameY = self.position.y - 1.25 * self.height / 2
  self.nameWindow:setXYZ(nameX, nameY)
end
-- Override. Adjusts name window position.
local DialogueWindow_setXYZ = DialogueWindow.setXYZ
function DialogueWindow:setXYZ(...)
  DialogueWindow_setXYZ(self, ...)
  local nameX = self.position.x - 0.45 * self.width / 2
  local nameY = self.position.y - 1.25 * self.height / 2
  self.nameWindow:setXYZ(nameX, nameY)
end
-- Override. Adjusts name window position.
local DialogueWindow_resize = DialogueWindow.resize
function DialogueWindow:resize(...)
  DialogueWindow_resize(self, ...)
  local nameX = self.position.x - 0.45 * self.width / 2
  local nameY = self.position.y - 1.25 * self.height / 2
  self.nameWindow:setXYZ(nameX, nameY)
end
-- Override. Adjusts text position and width.
local DialogueWindow_showDialogue = DialogueWindow.showDialogue
function DialogueWindow:showDialogue(...)
  local x = self.portrait and (indent or self.indent) or 0
  self.dialogue:setMaxWidth(self.width - self:paddingX() * 2 - x)
  self.dialogue.position.x = x - self.width / 2 + self:paddingX()
  self.dialogue:updatePosition(self.position)
  DialogueWindow_showDialogue(self, ...)
end
-- Override. Adjusts name window position.
local DialogueWindow_setName = DialogueWindow.setName
function DialogueWindow:setName(text, x, ...)
  if self.indent then
    x = self.indent - self.width / 2 + self.nameWidth / 2
  end
  DialogueWindow_setName(self, text, x, ...)
end

---------------------------------------------------------------------------------------------------
-- GUIEvents
---------------------------------------------------------------------------------------------------

-- Override. Sets portrait.
local EventSheet_showDialogue = EventSheet.showDialogue
function EventSheet:showDialogue(args)
  self:openDialogueWindow(args)
  local window = self.gui.dialogues[args.id]
  if args.character then -- Change portrait
    local portrait = nil
    if type(args.character) == 'number' then
      local char = Database.characters[args.character]
      portrait = util.array.findByName(char.portraits, args.portrait)
      args.name = args.name or char.name
    elseif args.character ~= '' then -- Change to other image
      local char = self:findCharacter(args.character)
      portrait = { char = char, name = args.portrait }
      args.name = args.name or char.name
    end
    window:setPortrait(portrait)
  elseif args.portrait then -- Change portrait
    local portrait = nil
    if args.portrait >= 0 then
      portrait = { id = args.portrait, col = args.portraitCol or 0, row = args.portraitRow or 0 }
    end
    window:setPortrait(portrait)
  end
  EventSheet_showDialogue(self, args)
end
