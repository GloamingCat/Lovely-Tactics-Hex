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

new_type("conf","Config Tables",true)
new_type("plugin","Plugins",true)
new_type("event","Events",true)

new_type("enum","Constants",false,"Types")
new_type("tags","Parameters",false,"Tags")
new_type("override_func","Overrides",false)
new_type("rewrite_func","Rewrites",false)

custom_tags = { 
  { "coroutine", hidden = false },
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

kind_names = {
   topic = "Manual",
   script = "Loaders"
}

local require = import("require")
local print = import("print")
local type = import("type")
local ldoc = require("ldoc.doc")

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