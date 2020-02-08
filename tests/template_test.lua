package.path = package.path .. ";../?.lua"

local describe = require('source/lspec');
local StringScanner = require('source/template/string_scanner')
local iterator = require('source/template/iterator')
local Template = require('source/template')

describe('StringScanner', function (it, describe)
  describe(':finished()', function (it)
    it('should be finished when passed an empty string', function ()
      assert(StringScanner:new(''):finished() == true)
    end)

    it('should not be finished when passed a non empty string', function ()
      assert(StringScanner:new('a'):finished() == false)
    end)
  end)

  describe(':find()', function (it)
    it('should return true if the pattern exists in the string', function ()
      assert(StringScanner:new('a'):find('a') == true)
    end)

    it('should return false if the pattern isn\'t in the string', function ()
      assert(StringScanner:new('a'):find('b') == false)
    end)
  end)

  describe(':scan()', function (it)
    it('should return the content before a matched string', function ()
      local before = StringScanner:new('abc'):scan('b')
      assert(before == 'a')
    end)

    it('should return the matched string it\'s self', function ()
      local _, match = StringScanner:new('abc'):scan('b')
      assert(match == 'b')
    end)

    it('should return the line that the match was made on', function ()
      local _, _, line = StringScanner:new('abc\nd\ne'):scan('e')
      assert(line == 3)
    end)

    it('should be finished after matching the last part of a string', function ()
      local scanner = StringScanner:new('abc\nd\ne')
      scanner:scan('e')
      assert(scanner:finished() == true)
    end)

    it('should scan new lines and finish once the last is reached', function ()
      local scanner = StringScanner:new('\n\n')
      scanner:scan('\n')
      scanner:scan('\n')
      assert(scanner:finished() == true)
    end)

    it('should no longer be able to find delimiter after scanning', function ()
      local scanner = StringScanner:new('a,b')
      scanner:scan(',')
      assert(scanner:find(',') == false)
    end)

    it('should be finished after collecting the rest of the string', function ()
      local scanner = StringScanner:new('a,b')
      scanner:scan(',')
      local _, match = scanner:scan('.*')
      assert(match == 'b')
      assert(scanner:finished() == true)
    end)
  end)
end)

local function equals(a, b)
  if #a ~= #b then
    return false
  end

  for _, index in pairs(a) do
    if a[index] ~= b[index] then
      return false
    end
  end

  return true
end

describe('iterator', function (it, describe)

  describe('.map(iter, func)', function (it)
    it('should return and empty table given an empty table', function ()
      assert(equals(iterator.map({}), {}))
    end)

    it('should return the same values', function ()
      local list = { 1, 2, 3 }
      assert(equals(iterator.map(list, function (i) return i end), list))
    end)

    it('should return values + 1', function ()
      assert(
        equals(
          iterator.map({ 1, 2, 3 }, function (i) return i + 1 end),
          { 2, 3, 4 }
        )
      )
    end)
  end)

  describe('.filter(iter, pred)', function (it)
    it('should return an empty list', function ()
      assert(equals(iterator.filter({}), {})) 
    end)

    it('should return an empty list', function ()
      assert(equals(iterator.filter({ 1 }, function () return false end), {})) 
    end)

    it('should return a list of 1', function ()
      assert(
        equals(
          iterator.filter({ 1, 2 }, function (i) return i < 2 end),
          { 1 }
        )
      )
    end)
  end)
end)

describe('table.merge', function (it)
  it('should merge two tables', function ()
    assert(equals(table.merge({ a=1 }, { b=2 }), { a=1, b=2 }))
  end)
end)

describe(' string.split', function (it)
  it('should split a string by delimiter', function ()
    assert(equals(string.split('a;b;c', ';'), { 'a', 'b', 'c' }))
  end)
end)

describe('Template', function (it, describe)
  describe(':parse(template)', function (it)
    it('should not return anything for empty template', function ()
      assert(Template:new(nil, ''):render({}) == '')
    end)

    it('should render the text provided', function ()
      assert(Template:new(nil, 'Hello!'):render() == 'Hello!')
    end)

    it('should render a value from the given context', function ()
      local result = Template:new(nil, '{{ message }}'):render({ message='Hello' })
      assert(result == 'Hello')
    end)

    it('should render surrounding template in the correct order', function ()
      local template = Template:new(nil, 'Why\n{{ message }}\nthere!')
      local result = template:render({ message='hello' })
      assert(result == 'Why\nhello\nthere!')
    end)
  end)
end)
