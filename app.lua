local Server = require("source/http/server")
local Router = require("source/http/router")
local Template = require("source/template")

router = Router:new()

landing_page = Template:new("landing_page.html.elua")

router:get('^/$', function (state, req)
  state.visits = state.visits + 1
  return state, Response:new({
    status=200,
    headers={},
    body=landing_page:render(state)
  })
end)

domain = Router:new()

-- equally, you could just use different nginx.conf files...
domain:route(Router.host('localhost'), router:toFunction())

server = Server:new({
  state={visits=0},
  middlewares={
    domain:toFunction(),
    Server.notFound
  }
})

server:run(9292)
