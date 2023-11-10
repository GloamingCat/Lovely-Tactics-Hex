
-- ================================================================================================

--- Indents the dialogue text to fit the speaker's portrait, shown above window.
---------------------------------------------------------------------------------------------------
-- @plugin DialoguePortrait

--- Plugin parameters.
-- @tags Plugin
-- @tfield number indent Fixes an indentation length `indent` instead of using portrait's width.

-- ================================================================================================

-- Imports
local DialogueWindow = require('core/gui/common/window/interactable/DialogueWindow')
local MenuEvents = require('core/event/MenuEvents')
local ImageComponent = require('core/gui/widget/ImageComponent')

-- Rewrites
local DialogueWindow_showDialogue = DialogueWindow.showDialogue
local MenuEvents_showDialogue = MenuEvents.showDialogue

-- Parameters
local indent = args.indent

-- ------------------------------------------------------------------------------------------------
-- DialogueWindow
-- ------------------------------------------------------------------------------------------------

--- Shows the portrait of the speaker.
-- @tparam table icon Table with id, col and row values. It may also contain char and name 
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
    local portrait = ResourceManager:loadIcon(icon, MenuManager.renderer)
    portrait.texture:setFilter('linear', 'linear')
    if char then
      portrait:applyTransformation(char.transform)
    end
    local ox, oy = portrait.offsetX, portrait.offsetY
    portrait:setOffset(0, 0)
    local x, y, w, h = portrait:totalBounds()
    x = -self.width / 2 + x + w / 2 + self:paddingX() - ox
    y = self.height / 2 - h / 2 - self:paddingY() - oy
    portrait:setOffset(ox, oy)
    self.portrait = ImageComponent(portrait, x - w / 2, y - h / 2, 1)
    self.portrait:updatePosition(self.position)
    self.content:add(self.portrait)
    self.indent = (indent or w) / self.width * 2
  end
end
--- Rewrites `DialogueWindow:showDialogue`.
-- @rewrite
function DialogueWindow:showDialogue(...)
  local x = self.portrait and (self.indent * self.width / 2) or 0
  self.dialogue:setMaxWidth(self.width - self:paddingX() * 2 - x)
  self.dialogue.position.x = x - self.width / 2 + self:paddingX()
  self.dialogue:updatePosition(self.position)
  DialogueWindow_showDialogue(self, ...)
end
local DialogueWindow_setName = DialogueWindow.setName
--- Rewrites `DialogueWindow:setName`.
-- @rewrite
function DialogueWindow:setName(text, x, ...)
  x = (x or -0.7) + (self.indent or 0)
  DialogueWindow_setName(self, text, x, ...)
end

-- ------------------------------------------------------------------------------------------------
-- MenuEvents
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MenuEvents:showDialogue`.
-- @rewrite
function MenuEvents:showDialogue(args)
  self:openDialogueWindow(args)
  local window = self.menu.dialogues[args.id]
  if args.character then -- Change portrait
    local portrait = nil
    if type(args.character) == 'number' then
      local char = Database.characters[args.character]
      portrait = util.array.findByName(char.portraits, args.portrait)
      args.name = args.name or Vocab.data.char[char.key] or char.name
    elseif args.character ~= '' then -- Change to other image
      local char = self:findCharacter(args.character)
      portrait = { char = char, name = args.portrait }
      args.name = args.name or Vocab.data.char[char.key] or char.name
    end
    window:setPortrait(portrait)
  elseif args.portrait then -- Change portrait
    local portrait = nil
    if args.portrait >= 0 then
      portrait = { id = args.portrait, col = args.portraitCol or 0, row = args.portraitRow or 0 }
    end
    window:setPortrait(portrait)
  end
  MenuEvents_showDialogue(self, args)
end
