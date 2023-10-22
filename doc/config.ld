
-- ------------------------------------------------------------------------------------------------
-- General
-- ------------------------------------------------------------------------------------------------

project = 'LTH Docs'
description = 'Lovely Tactics Hex 1.2 Documentation'
full_description = [[
The Lovely Tactics Hex project is a framework for development of tactical role-playing games (TRPG), built using the LÖVE2D engine.
The main games used as inspiration for this project are Final Fantasy Tactics Advance (for GBA), Jeanne D'arc, and Trails in the Sky (both for PSP).
The "Hex" in the name is because the battle grid is hexagonal, but isometric and orthogonal tiles are also available.
Visit the <a href="https://gitlab.com/gloamingcat/Lovely-Tactics-Hex">GitLab repository.</a>
]]
title = 'Lovely Tactics Hex Documentation'

style = '!fixed'
use_markdown_titles = true
format = 'discount'
sort_modules = true
merge = true
global_lookup = true
multimodule = true
no_space_before_args = true

local require = import("require")
local print = import("print")
local type = import("type")
local ldoc = require("ldoc.doc")
local List = require('pl.List')

-- ------------------------------------------------------------------------------------------------
-- Kinds
-- ------------------------------------------------------------------------------------------------

new_type("conf","ConfigTables",true)
new_type("manager","Managers",true)
new_type("iomod","IO",true)
new_type("animmod","Graphics",true)
new_type("fieldmod","Field",true)
new_type("battlemod","Battle",true)
new_type("uimod","UI",true)
new_type("basemod","Base",true)
new_type("plugin","Plugins",true)
new_type("event","Events",true)

kind_names = {
   topic = "Manual",
   script = "Loaders"
}

-- ------------------------------------------------------------------------------------------------
-- Function Tags
-- ------------------------------------------------------------------------------------------------

new_type("enum","Constants",false,"Types")
new_type("tags","Parameters",false,"Tags")
new_type("override_func","Overrides",false)
new_type("rewrite_func","Rewrites",false)

custom_tags = { 
  { "coroutine", hidden = false }
}

alias('override',{'class',value='override_func'})
alias('rewrite',{'class',value='rewrite_func'})

alias("implement",{'class',value='override_func'})
alias("reopen", "type")
alias("reopenclass", "classmod")

custom_display_name_handler = function(item, default_handler)
  if item.type == 'tags' then
    return item.names_hierarchy[#item.names_hierarchy]
  elseif item.type == 'override_func' then
    return "(override) " .. default_handler(item)
  elseif item.type == "rewrite_func" then
    return "(rewrite) " .. default_handler(item):gsub("rewrite_", "")
  elseif item.tags.coroutine then
    return "(coroutine) " .. default_handler(item)
  end
  return default_handler(item)
end
local original_init = ldoc.Item._init
function ldoc.Item._init(self, ...)
  original_init(self, ...)
  if self.tags.class == "rewrite_func" then
    self.tags.name = 'rewrite_' .. self.tags.name
    if self.formal_args then self.formal_args:clear() end
  elseif self.tags.class == "override_func" then
    if self.formal_args then self.formal_args:clear() end
  end
end
local original_set_tag = ldoc.Item.set_tag
function ldoc.Item.set_tag(self, tag, value)
  if type(value) == 'table' and value.append and tag == 'class' then
    original_set_tag(self, tag, value[1])
  else
    original_set_tag(self, tag, value)
  end
end

-- ------------------------------------------------------------------------------------------------
-- Class Tags
-- ------------------------------------------------------------------------------------------------

ldoc.add_tag("extend", "M", true)
add_section ("extend", "Superclasses")
ldoc.add_tag("derive", "M", true)
add_section ("derive", "Subclasses")
local module_info = {'extend','derive','copyright','release','license','author'}

function ldoc.module_info_tags()
  return List.iter(module_info)
end

local original_resolve_references = ldoc.Module.resolve_references
function ldoc.Module.resolve_references(self, modules)
  original_resolve_references(self, modules)
  if self.tags.extend then
    for c in self.tags.extend:iter() do
      local mod = modules.by_name[c]
      if mod then
        if not mod.tags.derive then
          mod.tags.derive = List()
        end
        mod.tags.derive:append('`' .. self.name .. '`')
      else
        self:warning('module not found: ' .. c)
      end
    end
    for i = 1, #self.tags.extend do
      self.tags.extend[i] = '`' .. self.tags.extend[i] .. '`'
    end
  end
end

postprocess_html = function(out, module)
  if module then
    out = out:gsub("<h1>Basemod", "<h1>Class")
    out = out:gsub("<h1>Iomod", "<h1>Class")
    out = out:gsub("<h1>Uimod", "<h1>Class")
    out = out:gsub("<h1>Fieldmod", "<h1>Class")
    out = out:gsub("<h1>Manager", "<h1>Class")
    out = out:gsub("<h1>Battlemod", "<h1>Class")
    out = out:gsub("<h1>Conf", "<h1>Table")
    out = out:gsub("Derive</strong>:", "Subclasses</strong>:")
    out = out:gsub("Extend</strong>:", "Superclasses</strong>:")
  end
  out = out:gsub("<h2>ConfigTables", "<h2>Config Tables")
  out = out:gsub("<h2>IO", "<h2>I/O")
  return out
end