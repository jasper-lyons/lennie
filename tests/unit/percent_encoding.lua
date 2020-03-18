require('relative_require')

local describe = require('lennie.lspec')
local PercentEncoding = require('../../source/http/percent_encoding')

describe('PercentEncoding', function (it, describe)
  describe('.encode(string)', function (it) 
    it('should encode @ symbols as %40', function ()
      assert(PercentEncoding.encode('test@test.com') == 'test%40test.com')
    end)

    it('should encode \' \' as %20', function ()
      assert(PercentEncoding.encode('ab c') == 'ab%20c')
    end)
  end)

  describe('.decode(string)', function (it)
    it('should decode %20 into \' \'', function ()
      assert(PercentEncoding.decode('%20') == ' ')
    end)

    it('should decode %40 into @', function ()
      assert(PercentEncoding.decode('%40') == '@')
    end)
  end)
end)
