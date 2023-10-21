
-- ================================================================================================

--- Add skills and change attack skill when item is equipped.
---------------------------------------------------------------------------------------------------
-- @plugin EquipSkills

--- Parameters in the Item tags.
-- @tags Item
-- @tfield string|number attack The ID or key of new attack skill of the character when it equips this
--  item (optional).
-- @tfield string|number|table skill The ID or key of a skill that will be  available for the 
--  character with this item equipped. You may also add a second number (and make it a `table`)
--  to indicate a minimum level, and a third to replace another skill instead of just adding it.

-- ================================================================================================

-- Imports
local Battler = require('core/battle/battler/Battler')
local EquipSet = require('core/battle/battler/EquipSet')
local SkillAction = require('core/battle/action/SkillAction')
local SkillList = require('core/battle/battler/SkillList')

-- ------------------------------------------------------------------------------------------------
-- EquipSet
-- ------------------------------------------------------------------------------------------------

--- Rewrites `EquipSet:init`.
-- @override EquipSet_init
local EquipSet_init = EquipSet.init
function EquipSet:init(...)
  self.skills = {}
  EquipSet_init(self, ...)
end
--- Rewrites `EquipSet:updateSlotBonus`.
-- @override EquipSet_updateSlotBonus
local EquipSet_updateSlotBonus = EquipSet.updateSlotBonus
function EquipSet:updateSlotBonus(key)
  EquipSet_updateSlotBonus(self, key)
  if not self.battler then
    return
  end
  local slot = self.slots[key]
  local data = slot.id >= 0 and Database.items[slot.id]
  if not data then
    self.skills[key] = nil
    return
  end
  self.skills[key] = SkillList()
  local tags = Database.loadTags(data.tags)
  if tags and tags.skill then
    for _, tag in ipairs(tags:getAll('skill')) do
      local skill, lvl, replace = tag, 1, nil
      if type(skill) == 'table' then
        skill = tag[1]
        lvl = tag[2]
        replace = tag[3]
      end
      skill = self.skills[key]:learn(skill)
      skill.minLevel = lvl
      skill.replace = replace
    end
  end
  if tags and tags.attack then
    local skill = Database.skills[tags.attack]
    self.skills[key][0] = SkillAction:fromData(skill.id)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Battler
-- ------------------------------------------------------------------------------------------------

--- Rewrites `Battler:getSkillList`.
-- @override Battler_getSkillList
local Battler_getSkillList = Battler.getSkillList
function Battler:getSkillList()
  local list = Battler_getSkillList(self)
  for k, skills in pairs(self.equipSet.skills) do
    for skill in skills:iterator() do
      if self.job.level >= skill.minLevel then
        if skill.replace then
          local i = list:containsSkill(skill.replace)
          if i then
            list[i] = skill
          end
        else
          list:learn(skill)
        end
      end
    end
  end
  return list
end
--- Rewrites `Battler:getAttackSkill`.
-- @override Battler_getAttackSkill
local Battler_getAttackSkill = Battler.getAttackSkill
function Battler:getAttackSkill()
  for k, skills in pairs(self.equipSet.skills) do
    if skills[0] then
      return skills[0]
    end
  end
  return Battler_getAttackSkill(self)
end
