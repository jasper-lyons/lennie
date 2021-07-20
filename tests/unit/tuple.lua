require('relative_require')

local describe = require('lennie.lspec')
local Tuple = require('../../source/core/tuple')

describe('Tuple', function (it, describe)
  describe(':__id', function (it)
    it('should return concatenation of all of the keys / values', function ()
      local t = Tuple:new({ id=0, name='Jasper'})
      assert(id(t) == 'id0nameJasper')
    end)
  end)
end)
