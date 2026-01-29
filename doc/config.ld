
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
local unpack = import("unpack")
local pairs = import("pairs")
local print = import("print")
local type = import("type")
local ldoc = require("ldoc.doc")
local markup = require("ldoc.markup")
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
new_type("menumod","Menu",true)
new_type("windowmod","Window",true)
new_type("uimod","UIComponents",true)
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
  { "coroutine", hidden = true }
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
    -- Rewrites
    local file = self.file.filename:gsub("%w+:", "") -- Remove disk name
    file = file:gsub("%w+/", ""):gsub("%w+\\", "") -- Remone directory names
    file = file:gsub("/", ""):gsub("\\", "") -- Remove remaining bars
    self.tags.name = file:gsub(".lua", "") .. ':' .. self.tags.name:gsub(":", "_")
    if self.formal_args then self.formal_args:clear() end -- Omit parameters
  elseif self.tags.class == "override_func" then
    -- Overrides
    if self.formal_args then self.formal_args:clear() end -- Omit parameters
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
-- Subclasses
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
function ldoc.Module.resolve_references(class, modules)
  original_resolve_references(class, modules)
  -- Add subclasses
  if class.tags.extend then
    for c in class.tags.extend:iter() do
      local mod = modules.by_name[c]
      if mod then
        if not mod.tags.derive then
          mod.tags.derive = List()
        end
        mod.tags.derive:append('`' .. class.name .. '`')
      else
        class:warning('module not found: ' .. c)
      end
    end
    for i = 1, #class.tags.extend do
      class.tags.extend[i] = '`' .. class.tags.extend[i] .. '`'
    end
  end
end

-- ------------------------------------------------------------------------------------------------
-- Type refs
-- ------------------------------------------------------------------------------------------------

local isclass = {
  conf = true,
  manager = true,
  iomod = true,
  animmod = true,
  fieldmod = true,
  battlemod = true,
  menumod = true,
  windowmod = true,
  uimod = true,
  basemod = true,
  plugin = true,
  event = true,
  module = true
}
local isnative = {
  number=true,
  string=true,
  boolean=true,
  table=true,
  ["function"]=true
}
local islove = {
  Font="https://love2d.org/wiki/Font",
  Source="https://love2d.org/wiki/Source",
  Image="https://love2d.org/wiki/Image",
  Quad="https://love2d.org/wiki/Quad",
  Texture="https://love2d.org/wiki/Texture",
  Shader="https://love2d.org/wiki/Shader",
  Canvas="https://love2d.org/wiki/Canvas"
}
local modules_as_class = nil
local original_process_see_reference = ldoc.Module.process_see_reference
function ldoc.Module:process_see_reference (s, modules, istype)
  if isnative[s] then
    return nil, "Native type"
  end
  if islove[s] then
    return {href = islove[s]}
  end
  if not istype then
    return original_process_see_reference(self, s, modules, istype)
  end
  if not modules_as_class then
    modules_as_class = {}
    for name, mod in pairs(modules.by_name) do
      if isclass[mod.type] then
        local mod2 = {}
        -- Copy everything
        for k, v in pairs(mod) do
          mod2[k] = v
        end
        mod2.type = 'classmod'
        mod2.get_fun_ref = mod.get_fun_ref
        modules_as_class[name] = mod2
      end
    end
  end
  local mods = modules.by_name
  modules.by_name = modules_as_class
  local ref, err = original_process_see_reference(self, s, modules, istype)
  modules.by_name = mods
  if not ref then
    print(err, self.name)
  end
  return ref, err
end

-- ------------------------------------------------------------------------------------------------
-- Post-process
-- ------------------------------------------------------------------------------------------------

postprocess_html = function(out, module)
  if module then
    out = out:gsub("<h1>Basemod", "<h1>Class")
    out = out:gsub("<h1>Animod", "<h1>Class")
    out = out:gsub("<h1>Iomod", "<h1>Class")
    out = out:gsub("<h1>Uimod", "<h1>Class")
    out = out:gsub("<h1>Windowmod", "<h1>Class")
    out = out:gsub("<h1>Menumod", "<h1>Class")
    out = out:gsub("<h1>Fieldmod", "<h1>Class")
    out = out:gsub("<h1>Manager", "<h1>Class")
    out = out:gsub("<h1>Battlemod", "<h1>Class")
    out = out:gsub("<h1>Conf", "<h1>Table")
    out = out:gsub("Derive</strong>:", "Subclasses</strong>:")
    out = out:gsub("Extend</strong>:", "Superclasses</strong>:")
  end
  out = out:gsub("<h2>ConfigTables", "<h2>Config Tables")
  out = out:gsub("<h2>UIComponents", "<h2>Window Components")
  out = out:gsub("<h2>IO", "<h2>I/O")
  return out
end