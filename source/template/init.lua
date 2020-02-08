local require_relative = require('require_relative')
local StringScanner = require_relative('string_scanner')
local iterator = require_relative('iterator')

-- utility function to merge two objects
function table.merge(t1, t2)
  local function merge_key(reciever, value, key)
    if type(reciever[key]) == "table" then
      reciever[key] = table.merge(reciever[key], value)
    else
      reciever[key] = value
    end
    return reciever
  end

  return iterator.reduce(t2, merge_key, iterator.reduce(t1, merge_key, {}))
end


function string.split(str, delimiter)
  parser = StringScanner:new(str)

  local array = {}
  while parser:find(delimiter) do
    local before, match, line = parser:scan(delimiter)
    table.insert(array, { before, line })
  end

  if not parser:finished() then
    local before, match, line = parser:scan('.*')
    table.insert(array, { match, line })
  end

  return array
end

-- An object that represents a template. We use an object to collect state
-- and functionality around error checking more than anything else.
Template = {}
function Template:new(filename, template)
  base = {
    filename=filename or "",
    template=template or io.open(filename):read("a"),
    context={},
    compiled="",
    compiled_func=function () return "" end
  }
  setmetatable(base, self)
  self.__index = self
  return base
end

-- Template.parse(string) -> iterator.
--    iterator:next() -> content, code, kind, line.
--      content -> the text between the last }} and latest {{.
--      code -> the text between the latest {{ and }}.
--      kind -> the latest {{ including it's "type" identifier, one of:
--              * '#'
--              * '>'
--      line -> the line of the template that this peice of code is found on.
function Template.parse(template)
  parser = StringScanner:new(template)
  
  return function ()
    if parser:find("{{#?>?") then
      local content, kind, _ = parser:scan("{{#?>?")
      local code, _, line = parser:scan("}}")
      return content, code, kind, line
    elseif not parser:finished() then
      local _, content, line = parser:scan(".*")
      return content, nil, nil, line
    else
      return nil, nil, nil, nil
    end
  end
end

local compiled_template = [[
%s

local body = table.concat(
  iterator.filter(
    iterator.map(
      lines,
      function (l) return l:gsub("^\n+", ""):gsub("\n+$", "") end
    ),
    function (l) return l ~= '' end
  ),
  "\n"
)

local result = string.format(
  body,
  table.unpack(iterator.map(lazy_values, function (lv)
    current_line = lv[2]  
    return lv[1]()
  end))
)

return result
]]

local error_template = [[
%s
Template:
%s
Compiled:
%s
]]

-- template.render(template, context) -> string
--    template -> a string with lua code between multiple '{{' and '}}' pairs.
--    context ->  a table of functions and variables that are made available
--                to the code inside of the template.
--    string -> the string produced by evaulating the template in the given
--              context
function Template:render(context)
  self.context = table.merge(context or { }, table.merge({
      iterator = iterator,
      lines = setmetatable({}, {
        __index = function (table, key)
          table[key] = {}
          return table[key]
        end
      }),
      lazy_values = {},
      current_line = 1
    }, _G))

  body = {}
  for content, code, kind, line in Template.parse(self.template) do
    table.insert(body, string.format("current_line = %s\n", line))
    table.insert(
      body,
      string.format(
        "table.insert(lines, \"%s\")\n",
        content:gsub("\n", "\\n"):gsub("\"", "\\\"")
        )
      )

    if kind == "{{>" then
      table.insert(body, "table.insert(lines,\"%s\")\n")
      table.insert(
        body,
        string.format(
          "table.insert(lazy_values, { function () return %s end, %s })\n",
          code,
          line
        )
      )
    elseif kind == "{{#" then
      table.insert(body, string.format("%s\n", code))
    elseif kind == "{{" then
      table.insert(
        body,
        string.format("table.insert(lines, tostring(%s))\n", code)
      )
    end
  end

  self.compiled = string.format(compiled_template, table.concat(body))

  local func, err = load(self.compiled, nil, nil, self.context)
  if err then
    return err
  end
  self.compiled_func = func

  local status, result = xpcall(self.compiled_func, function (err)
    local compiled_line_no, err_message = string.match(err, ":(%d+):(.-)")
    compiled_line_no = tonumber(compiled_line_no) or 0
    local template_line_no = tonumber(self.context["current_line"])

    local function line_with_context(line_number, context_size)
      return function (line_data)
        local line, index = table.unpack(line_data)
        if line_number == index then
          return string.format("> %s: %s\n", index, line)
        elseif index > line_number - context_size and line_number + context_size > index then
          return string.format("  %s: %s\n", index, line)
        end
      end
    end

    local template_lines = iterator.map(
      string.split(self.template, "\n"),
      line_with_context(template_line_no, 2)
    )

    local compiled_lines = iterator.map(
      string.split(self.compiled, "\n"),
      line_with_context(compiled_line_no, 2)
    )

    error_string = string.format(error_template, 
      err,
      table.concat(template_lines),
      table.concat(compiled_lines)
    )

    return error_string
  end)

  return result
end

return Template
