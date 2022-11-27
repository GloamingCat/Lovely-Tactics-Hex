
--[[===============================================================================================

Credits
---------------------------------------------------------------------------------------------------
Adds a new command to show credits.

=================================================================================================]]

-- Imports
local GUIEvents = require('core/event/GUIEvents')
local Text = require('core/graphics/Text')
local Vector = require('core/math/Vector')

-- Parameters
local pages = args.pages:split(' ')
for i = 1, #pages do
  pages[i] = { name = pages[i], lines = args[pages[i]]:split(' ') }
end
local speed = tonumber(args.speed) or 2
local pause = tonumber(args.pause) or 60
local font = args.font or Fonts.gui_big

---------------------------------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------------------------------

-- Auxiliary.
-- @param(y : number) Space from the top of the screen, in pixels.
local function createText(y)
  local prop = { ScreenManager.width, 'center', font }
  local titleText = Text('', prop, GUIManager.renderer)
  local x = -ScreenManager.width / 2
  y = y - ScreenManager.height / 2
  titleText.wrap = true
  titleText:setXYZ(x, y, 0)
  titleText:setRGBA(nil, nil, nil, 0)
  return titleText
end

---------------------------------------------------------------------------------------------------
-- Execution
---------------------------------------------------------------------------------------------------

-- Credits animation.
-- @param(titleText : Text)
-- @param(bodyText : Text)
local function showCredits(titleText, bodyText)
  local previousPage = nil
  local time = 0
  for _, page in ipairs(pages) do
    titleText:setText(Vocab.dialogues.credits[page.name] or page.name)
    local body = '\n'
    for _, line in ipairs(page.lines) do 
      body = body .. (Vocab.dialogues.credits[line] or line) .. '\n'
    end
    bodyText:setText(body)
    while time < 1 do
      time = math.min(1, time + GameManager:frameTime() * speed)
      if previousPage ~= page.name then
        titleText.colorTime = time
        titleText:setRGBA(nil, nil, nil, time)
      end
      bodyText.colorTime = time
      bodyText:setRGBA(nil, nil, nil, time)
      Fiber:wait()
    end
    Fiber:wait(pause * #page.lines)
    while time > 0 do
      time = math.max(0, time - GameManager:frameTime() * speed)
      if previousPage ~= page.name then
        titleText.colorTime = time
        titleText:setRGBA(nil, nil, nil, time)
      end
      bodyText.colorTime = time
      bodyText:setRGBA(nil, nil, nil, time)
      Fiber:wait()
    end
    previousPage = page.name
  end
end
-- Shows credits animation and listens to player input.
function GUIEvents:showCredits(args)
  self:createGUI()
  local titleText = createText(self.gui:windowMargin() * 2)
  local bodyText = createText(self.gui:windowMargin() * 2 + font[3])
  local fiber = self:fork(showCredits, titleText, bodyText)
  while fiber:running() do
    if InputManager.keys['confirm']:isTriggered() then
      fiber:interrupt()
      local time = math.max(titleText.colorTime, bodyText.colorTime)
      local titleTime = titleText.colorTime / time
      local bodyTime = bodyText.colorTime / time
      while time > 0 do
        time = math.max(0, time - GameManager:frameTime() * speed)
        titleText:setRGBA(nil, nil, nil, time * titleTime)
        bodyText:setRGBA(nil, nil, nil, time * bodyTime)
        self:wait()
      end
      break
    end
    self:wait()
  end
  titleText:destroy()
  bodyText:destroy()
end
