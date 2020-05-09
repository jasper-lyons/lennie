package = "lennie"
version = "dev-1"
source = {
   url = "git+ssh://git@github.com/jasper-lyons/lennie.git"
}
description = {
   summary = "A web framework in lua named after Lennie Small from Of Mice and Men.",
   detailed = [[
A web framework in lua named after Lennie Small from Of Mice and Men. Beware,
while cute, it may cuase more trouble that it's worth.]],
   homepage = "*** please enter a project homepage ***",
   license = "MIT"
}
build = {
   type = "builtin",
   dependencies = {
    'relative_require'
   },
   modules = {
      ["lennie.http.request"] = "source/http/request.lua",
      ["lennie.http.response"] = "source/http/response.lua",
      ["lennie.http.router"] = "source/http/router.lua",
      ["lennie.http.server"] = "source/http/server.lua",
      ["lennie.http.formdata"] = "source/http/formdata.lua",
      ["lennie.http.percent_encoding"] = "source/http/percent_encoding.lua",

      ["lennie.concurrent.fiber"] = "source/concurrent/fiber.lua",
      ["lennie.concurrent.fiber_runner"] = "source/concurrent/fiber_runner.lua",
      ["lennie.concurrent.channel"] = "source/concurrent/channel.lua",
      ["lennie.concurrent.implementation"] = "source/concurrent/implementation.lua",
      ["lennie.concurrent.operation"] = "source/concurrent/operation.lua",
      ["lennie.concurrent.queue"] = "source/concurrent/queue.lua",
      ["lennie.concurrent.suspension"] = "source/concurrent/suspension.lua",

      ["lennie.core.array"] = "source/core/array.lua",
      ["lennie.core.map"] = "source/core/map.lua",
      ["lennie.core.class"] = "source/core/class.lua",
      ["lennie.core.compile_with_env"] = "source/core/compile_with_env.lua",


      ["lennie.lspec"] = "source/lspec.lua",

      ["lennie.extension.string"] = "source/extension/string.lua",

      ["lennie.template"] = "source/template/init.lua",
      ["lennie.template.iterator"] = "source/template/iterator.lua",
      ["lennie.template.string_scanner"] = "source/template/string_scanner.lua",
      ["lennie.template.extensions.table"] = "source/template/extensions/table.lua"
   },
   copy_directories = {
      "tests"
   }
}
