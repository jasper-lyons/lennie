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

    function it(spec_line, spec)
      local status = xpcall(spec, function (err)
        table.insert(errors, string.format(
          "%s  %s\n%s    %s\n",
          indentation,
          spec_line,
          indentation,
          err))
      end)

      if status then
        table.insert(successes, string.format("%s  %s\n", indentation, spec_line))
      end
    end

    print(string.format('%s%s%s',indentation, prefix, name))

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
