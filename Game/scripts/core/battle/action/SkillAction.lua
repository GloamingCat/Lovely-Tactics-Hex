
local Callback = require('core/callback/Callback')
local BattleAction = require('core/battle/action/BattleAction')
local SkillMoveAction = require('core/battle/action/SkillMoveAction')
local PathFinder = require('core/algorithm/PathFinder')
local max = math.max
local isnan = math.isnan
local mathf = math.field
local time = love.timer.getDelta
local now = love.timer.getTime

--[[===========================================================================

The BattleAction that is executed when players chooses a skill to use.

=============================================================================]]

local SkillAction = BattleAction:inherit()

local old_init = SkillAction.init
function SkillAction:init(initialTile, user, skill)
  old_init(self, initialTile, user)
  self.data = skill
  if skill.type == 0 then
    self.type = 'attack'
  elseif skill.type == 1 then
    self.type = 'support'
  elseif skill.type == 2 then
    self.type = 'general'
  end
end

-------------------------------------------------------------------------------
-- Grid navigation
-------------------------------------------------------------------------------

-- Overrides BattleAction:selectTarget.
function SkillAction:selectTarget(tile)
  if self.currentTargets then
    for i = #self.currentTargets, 1, -1 do
      self.currentTargets[i]:setSelected(false)
    end
  end
  self.currentTarget = tile
  self.currentTargets = self:getAllAffectedTiles(tile)
  for i = #self.currentTargets, 1, -1 do
    self.currentTargets[i]:setSelected(true)
  end
end

-------------------------------------------------------------------------------
-- Selectable Tiles
-------------------------------------------------------------------------------

function SkillAction:resetTargetTiles(selectMovable, selectBorder)
  self:resetAllTiles(false)
  self:resetMovableTiles(selectMovable)
  local matrix = BattleManager.distanceMatrix
  local field = FieldManager.currentField
  local charTile = BattleManager.currentCharacter:getTile()
  local h = charTile.layer.height
  for i = 1, self.field.sizeX do
    for j = 1, self.field.sizeY do
       -- If this tile is reachable
      if not isnan(matrix:get(i, j)) then
        
        local tile = self.field:getObjectTile(i, j, h)
        local isBorder = false
        for neighbor in tile.neighborList:iterator() do
          -- If this tile has any non-reachable neighbors
          if isnan(matrix:get(neighbor.x, neighbor.y)) then
            isBorder = true
            break
          end
        end
        if isBorder then
          for i, j in mathf.radiusIterator(self.data.range + 1, 
              tile.x, tile.y, field.sizeX, field.sizeY) do
            local n = field:getObjectTile(i, j, h) 
            if isnan(matrix:get(n.x, n.y)) then
              n.selectable = selectBorder and self:isSelectable(n)
              n:setColor(self.type)
            end
          end
        end
        
      end
    end
    for i, j in mathf.radiusIterator(self.data.range + 1, 
        charTile.x, charTile.y, field.sizeX, field.sizeY) do
      if isnan(matrix:get(i, j)) then
        local n = field:getObjectTile(i, j, h)
        n.selectable = selectBorder and self:isSelectable(n)
        n:setColor(self.type)
      end
    end
  end
  
end

-------------------------------------------------------------------------------
-- Effect
-------------------------------------------------------------------------------

function SkillAction:effect()
  local originTile = self.user:getTile()
  local startTime = now()
  local minTime = 0
  minTime = minTime + self:effectIntro(originTile)
  minTime = minTime + self:effectCenter(originTile)
  minTime = minTime + self:effectFinish(originTile)
  Callback.current:wait(max (0, startTime + minTime - now()) + 1)
end

-- Gets all tiles that will be affected by skill's effect.
-- @ret(table) an array of tiles
function SkillAction:getAllAffectedTiles()
  local tiles = {}
  local field = FieldManager.currentField
  local height = self.currentTarget.layer.height
  for i, j in mathf.radiusIterator(self.data.radius, self.currentTarget.x,
    self.currentTarget.y, field.sizeX, field.sizeY) do
    tiles[#tiles + 1] = field:getObjectTile(i, j, height)
  end
  return tiles
end

function SkillAction:calculateResult()
  
end

-------------------------------------------------------------------------------
-- Animation
-------------------------------------------------------------------------------

-- Animation for the start of the skill.
function SkillAction:effectIntro()
  local start = now()
  local introTime = 22.5
  Callback.current:wait(introTime)
  self.user:startSkill(self.currentTarget, self.data)
  return now() - start
end

-- Animation for the center of the targets.
function SkillAction:effectCenter()
  FieldManager.renderer:moveToTile(self.currentTarget)
  if self.data.centerAnimID >= 0 then
    local targetTime = 7.5
    local mirror = self.user.direction > 90 and self.user.direction <= 270
    local x, y, z = mathf.tile2Pixel(self.currentTarget:coordinates())
    local animation = BattleManager:playAnimation(self.data.centerAnimID)
    Callback.current:wait(targetTime)
    return animation.duration - targetTime
  end
  return 0
end

-- Animation for the end of the skill.
function SkillAction:effectFinish(originTile)
  local start = now()
  self.allTargetsAnimation(originTile)
  self.user:finishSkill(originTile)
  return now() - start
end

function SkillAction:allTargetsAnimation(originTile)
  for i = #self.currentTargets, 1, -1 do
    local tile = self.currenTargets[i]
    for char in tile.characterList:iterator() do
      self:singleTargetAnimation(char, originTile)
    end
  end
end

function SkillAction:singleTargetAnimation(char, originTile)
  local result = self:calculateResult(char)
  if result == 0 then
    -- Pop-up 'miss'
  elseif result > 0 then
    if self.data.radius > 0 then
      originTile = self.currentTarget
    end
    char:damage(originTile, self.individualAnimID, result)
  else
    char:heal(self.individualAnimID, -result)
  end
  local targetTime = 2
  Callback.current:wait(targetTime)
end

-------------------------------------------------------------------------------
-- Event handlers
-------------------------------------------------------------------------------

-- Overrides BattleAction:onConfirm.
function SkillAction:onConfirm(GUI)
  GUI:endGridSelecting()
  FieldManager.renderer:moveToObject(self.user, true)
  FieldManager.renderer.focusObject = self.user
  local moveAction = SkillMoveAction(self.data.range, self.currentTarget, self.user)
  local path = PathFinder.findPath(moveAction)
  if path then -- Target was reached
    self.user:walkPath(path)
    self:effect()
  else -- Target was not reached
    path = PathFinder.findPathToUnreachable(moveAction)
    path = path or PathFinder.estimateBestTile(moveAction)
    self.user:walkPath(path)
  end
  if path.lastStep:isControlZone(self.user.battler) then
    self.user.battler.currentSteps = 0
  else
    self.user.battler.currentSteps = self.user.battler.currentSteps - path.totalCost
  end
  return 1
end

return SkillAction
