require('relative_require')

local describe = require('lennie.lspec')
local Array = require('../../source/core/array')

describe('Array', function (it, describe)
  describe('.from(object)', function (it)
    it('should return the same array given', function ()
      local a = Array:new({})
      local b = Array.from(a)
      assert(b == a)
    end)

    it('should return a new array with the table as the object passed in', function ()
      local a = {}
      local b = Array.from(a)
      assert(b.table == a)
    end)

    it('should reject objects that are not tables', function ()
      local status, result = pcall(function ()
        local a = 1
        local b = Array.from(a)
      end)

      assert(not status, 'No error was thrown!')
    end)
  end)

  describe('.__sub(other)', function (it)
    it('should return all of the members of self that are not members of other', function ()
      local a = Array:new({1,2,3})
      local b = Array:new({2,3,4})
      local difference = a - b
      assert(#difference == 1)
      assert(difference:get(1) == 1)
    end)
  end)
end)
