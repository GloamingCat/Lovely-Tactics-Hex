
-- ================================================================================================

--- Adds a new command to show credits.
---------------------------------------------------------------------------------------------------
-- @plugin Credits

--- Plugin parameters.
-- @tags Plugin
-- @tfield number speed The speed in which the text shows on screen (optional, 2 by default).
-- @tfield number pause The pause in frames between pages (optional, 60 by default).
-- @tfield string font The font name (optional, uses `'menu_big'` by default).
-- @tfield string pages The page names, separated by spaces.
-- @tfield string pageX For each page `pageX`, there should be a tag `pageX` that contains the text
--  in this page. The text contains the lines separated by spaces. Each line is a term that should
-- be present in the `Vocab.dialogues.credits` table.

-- ================================================================================================

-- Imports
local MenuEvents = require('core/event/MenuEvents')
local Text = require('core/graphics/Text')
local Vector = require('core/math/Vector')

-- Parameters
local pages = args.pages:split(' ')
for i = 1, #pages do
  pages[i] = { name = pages[i], lines = args[pages[i]]:split(' ') }
end
local speed = args.speed or 2
local pause = args.pause or 60
local font = args.font and Fonts[args.font] or Fonts.menu_big

-- ------------------------------------------------------------------------------------------------
-- Initialization
-- ------------------------------------------------------------------------------------------------

--- Auxiliary.
-- @tparam number y Space from the top of the screen, in pixels.
local function createText(y)
  local prop = { ScreenManager.width, 'center', font }
  local titleText = Text('', prop, MenuManager.renderer)
  local x = -ScreenManager.width / 2
  y = y - ScreenManager.height / 2
  titleText.wrap = true
  titleText:setXYZ(x, y, 0)
  titleText:setRGBA(nil, nil, nil, 0)
  return titleText
end

-- ------------------------------------------------------------------------------------------------
-- Execution
-- ------------------------------------------------------------------------------------------------

--- Credits animation.
-- @tparam Text titleText
-- @tparam Text bodyText
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
--- Shows credits animation and listens to player input.
-- @coroutine showCredits
function MenuEvents:showCredits(args)
  self:createMenu()
  local titleText = createText(self.menu:windowMargin() * 2)
  local bodyText = createText(self.menu:windowMargin() * 2 + font[3])
  local fiber = self:fork(showCredits, titleText, bodyText)
  while fiber:running() do
    if InputManager.keys['confirm']:isTriggered() or InputManager.keys['cancel']:isTriggered() or
        InputManager.keys['touch']:isTriggered() or InputManager.keys['mouse1']:isTriggered() then
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
