
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
local Vector = require('core/math/Vector')

-- Rewrites
local DialogueWindow_showDialogue = DialogueWindow.showDialogue
local DialogueWindow_setName = DialogueWindow.setName
local MenuEvents_openDialogueWindow = MenuEvents.openDialogueWindow

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
    if char and char.charData.transformPortraits then
      portrait:applyTransformation(char.transform)
    end
    local x1, y1, x2, y2 = portrait:getBoundingBox()
    local w = x2 - x1
    local h = y2 - y1
    local x = -self.width / 2 + w / 2 + self:paddingX()
    local y = self.height / 2 - h / 2 - self:paddingY()
    self.portrait = ImageComponent(portrait, Vector(x, y))
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
--- Rewrites `DialogueWindow:setName`.
-- @rewrite
function DialogueWindow:setName(text, x, ...)
  if self.indent then
    x = (x or 0) + self.indent * 100
  end
  DialogueWindow_setName(self, text, x, ...)
end

-- ------------------------------------------------------------------------------------------------
-- MenuEvents
-- ------------------------------------------------------------------------------------------------

--- Rewrites `MenuEvents:openDialogueWindow`.
-- @rewrite
function MenuEvents:openDialogueWindow(args)
  self:createDialogueWindow(args)
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
  MenuEvents_openDialogueWindow(self, args)
end
