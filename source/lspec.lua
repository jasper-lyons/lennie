local function colourise(ansicode, string)
  return string.char(27) .. '[' .. ansicode .. 'm' .. string .. string.char(27) .. '[0m'
end

local function multiply(self, times)
  for i = 1,times do
    self = self .. self
  end

  return self
end

local function buildDescriber(prefix, depth)
  prefix = prefix or ""
  depth = depth or 0
  local indentation = multiply('  ', depth)

  local function describe(name, descriptor)
    local errors = {}
    local successes = {}
    local before = nil
    local after = nil

    function it(spec_line, spec)
      if before then before() end

      local status = xpcall(spec, function (err)
        table.insert(errors, string.format(
          "%s  %s\n%s    %s\n",
          indentation,
          spec_line,
          indentation,
          -- TODO: Move this to a full args parser etc.
          arg[1] == '--trace' and debug.traceback(err, 2) or err
          ))
      end)

      if status then
        table.insert(successes, string.format("%s  %s\n", indentation, spec_line))
      end

      if after then after() end
    end

    print(string.format('%s%s%s', indentation, prefix, name))

    function setBefore(beforeHandler)
      before = beforeHandler
    end

    function setAfter(afterHandler)
      after = afterHandler
    end

    local status = xpcall(descriptor, function (err)
      table.insert(errors, err)
    end, it, buildDescriber(name, depth + 1), setBefore, setAfter)

    if #errors > 0 then
      print(colourise(31, table.concat(errors)))
    end

    if #successes > 0 then
      print(colourise(32, table.concat(successes)))
    end
  end

  return describe
end

return buildDescriber('')
