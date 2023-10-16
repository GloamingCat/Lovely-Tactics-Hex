
--[[===============================================================================================

@script EquipSkills
---------------------------------------------------------------------------------------------------
Add skills and change attack skill when item is equipped.

-- Item parameters:
Set <attack> to a skill's ID or key to set it as the attack skill of the item.
Add a <skill> tag with a skill's ID or key to make it available for the character with this item
equipped. You may also add a second number to indicate a minimum level, and a third to replace
another skill.

=================================================================================================]]

-- Imports
local Battler = require('core/battle/battler/Battler')
local EquipSet = require('core/battle/battler/EquipSet')
local SkillAction = require('core/battle/action/SkillAction')
local SkillList = require('core/battle/battler/SkillList')

-- ------------------------------------------------------------------------------------------------
-- EquipSet
-- ------------------------------------------------------------------------------------------------

--- Override. Creates the list of skills 
local EquipSet_init = EquipSet.init
function EquipSet:init(...)
  self.skills = {}
  EquipSet_init(self, ...)
end
--- Override. Updates the skills for each slot.
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
  for i, tag in ipairs(data.tags) do 
    if tag.key == 'skill' then
      local skill = tag.value:split()
      local lvl = tonumber(skill[2]) or 1
      local replace = tonumber(skill[3]) or skill[3]
      skill = self.skills[key]:learn(tonumber(skill[1]) or skill[1])
      skill.minLevel = lvl
      skill.replace = replace
    elseif tag.key == 'attack' then
      local skill = Database.skills[tonumber(tag.value) or tag.value]
      self.skills[key][0] = SkillAction:fromData(skill.id)
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Battler
-- ------------------------------------------------------------------------------------------------

--- Override. Adds equip skills.
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
--- Override. Check if there's an equip attack skill.
local Battler_getAttackSkill = Battler.getAttackSkill
function Battler:getAttackSkill()
  for k, skills in pairs(self.equipSet.skills) do
    if skills[0] then
      return skills[0]
    end
  end
  return Battler_getAttackSkill(self)
end
