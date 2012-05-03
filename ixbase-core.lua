--
-- ixbase-core.lua
--
luatexbase.provides_module({
  name = 'ixbase-core',
  date = '2012/05/02',
  version = '0.2',
  description = '',
})

--------------------

--- Extension to tex.print(). Each argument string may contain
-- newline characters, in which case the string is output (to
-- TeX input stream) as multiple lines.
-- @param ... string to output (string)
function ix_print(...)
  local arg = {...}
  local lines = {}
  if type(arg[1]) == "number" then
    table.insert(lines, arg[1])
    table.remove(arg, 1)
  end
  for _, cnk in ipairs(arg) do
    local ls = cnk:explode("\n")
    if ls[#ls] == "" then
      table.remove(ls, #ls)
    end
    for _, l in ipairs(ls) do
      table.insert(lines, l)
    end
  end
  return tex.print(unpack(lines))
end

local glue_spec_id = node.id("glue_spec")

local function copy_skip(s1, s2)
  if not s1 then
    s1 = node.new(glue_spec_id)
  end
  s1.width = s2.width or 0
  s1.stretch = s2.stretch or 0
  s1.stretch_order = s2.stretch_order or 0
  s1.shrink = s2.shrink or 0
  s1.shrink_order = s2.shrink_order or 0
  return s1
end

function to_dimen(val)
  if val == nil then
    return 0
  elseif type(val) == "number" then
    return val
  else
    return tex.sp(tostring(val))
  end
end

local function parse_dimen(val)
  val = tostring(val):lower()
  local r, fil = val:match("([-.%d]+)fi(l*)")
  if r then
    val, fil = r.."pt", fil:len() + 1
  else
    fil = 0
  end
  return tex.sp(val), fil
end

function to_skip(val)
  if type(val) == "userdata" then
    return val
  end
  local res = node.new(glue_spec_id)
  if val == nil then
    res.width = 0
  elseif type(val) == "number" then
    res.width = val
  elseif type(val) == "table" then
    copy_skip(res, val)
  else
    local t = tostring(val):lower():explode()
    local w, p, m = t[1], t[3], t[5]
    if t[2] == "minus" then
      p, m = nil, t[3]
    end
    res.width = tex.sp(t[1])
    if t[3] then
      res.stretch, res.stretch_order = parse_dimen(t[3])
    end
    if t[5] then
      res.shrink, res.shrink_order = parse_dimen(t[5])
    end
  end
  return res
end

function dump_skip(s)
  print(("%s+%s<%s>-%s<%s>"):format(
    s.width or 0, s.stretch or 0, s.stretch_order or 0,
    s.shrink or 0, s.shrink_order or 0))
end

local length = {}
local mt_length = {}; setmetatable(length, mt_length)
function mt_length.__index(tbl, key)
  return tex.skip[key]
end
function mt_length.__newindex(tbl, key, val)
  tex.skip[key] = to_skip(val)
end

local counter = {}
local mt_counter = {}; setmetatable(counter, mt_counter)
function mt_counter.__index(tbl, key)
  return tex.count['c@'..key]
end
function mt_counter.__newindex(tbl, key, val)
  tex.count['c@'..key] = val
end

-------------------- export
ixbase = ixbase or {}
ixbase.print = ix_print
ixbase.length = length
ixbase.to_dimen = to_dimen
ixbase.to_skip = to_skip
ixbase.counter = counter
ixbase.length = length

-- EOF
