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
      ["lennie.lspec"] = "source/lspec.lua",
      ["lennie.template"] = "source/template/init.lua",
      ["lennie.template.iterator"] = "source/template/iterator.lua",
      ["lennie.template.string_scanner"] = "source/template/string_scanner.lua",
      ["lennie.template.extensions.table"] = "source/template/extensions/table.lua"
   },
   copy_directories = {
      "tests"
   }
}
