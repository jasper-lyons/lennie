Router = {}

function Router:new(base)
  base = base or { routes={} }
  setmetatable(base, self)
  self.__index = self
  return base
end

function Router:toFunction()
  return function (state, req)
    local res = req
    for predicate, middleware in pairs(self.routes) do
      if predicate(req) then
        state, res = middleware(state, req)
        break
      end
    end
    return state, res
  end
end

function Router:route(predicate, middleware)
  self.routes[predicate] = middleware
end

function Router.land(func1, func2)
  return function (req)
    return func1(req) and func2(req)
  end
end

function Router.lor(func1, func2)
  return function (req)
    return func1(req) or func2(req)
  end
end

function Router.method(method)
  return function (req)
    return req.method == method
  end
end

function Router.path(pattern)
  return function (req)
    return req.path:find(pattern)
  end
end

function Router.host(pattern)
  return function (req)
    return req.headers['Host']:find(pattern)
  end
end

function Router:get(path, middleware)
  predicate = Router.land(Router.method('GET'), Router.path(path))
  self:route(predicate, middleware)
end

function Router:post(path, middleware)
  predicate = Router.land(Router.method('POST'), Router.path(path))
  self:route(predicate, middleware)
end

function Router:put(path, middleware)
  predicate = Router.land(Router.method('PUT'), Router.path(path))
  self:route(predicate, middleware)
end

function Router:delete(path, middleware)
  predicate = Router.land(Router.method('DELETE'), Router.path(path))
  self:route(predicate, middleware)
end

function Router:patch(path, middleware)
  predicate = Router.land(Router.method('PATCH'), Router.path(path))
  self:route(predicate, middleware)
end

function Router:trace(path, middleware)
  predicate = Router.land(Router.method('TRACE'), Router.path(path))
  self:route(predicate, middleware)
end

function Router:head(path, middleware)
  predicate = Router.land(Router.method('HEAD'), Router.path(path))
  self:route(predicate, middleware)
end

function Router:options(path, middleware)
  predicate = Router.land(Router.method('OPTIONS'), Router.path(path))
  self:route(predicate, middleware)
end

function Router:connect(path, middleware)
  predicate = Router.land(Router.method('CONNECT'), Router.path(path))
  self:route(predicate, middleware)
end

return Router
