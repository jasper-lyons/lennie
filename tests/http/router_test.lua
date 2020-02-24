require('relative_require')

local describe = require('../../source/lspec')
local Router = require('../../source/http/router')
local Request = require('../../source/http/request')

describe('Router', function (it, describe)
  describe('.path', function (it)
    it('should return the match data for a matched url', function ()
      local match = Router.path('^/legends/([^/]+)$')(Request:new({
        path = '/legends/user-legends'
      }))

      assert(match)
      assert(match[1] == 'user-legends')
    end)
  end)
end)
