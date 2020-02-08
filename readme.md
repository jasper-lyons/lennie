# lennie

A web framework in lua named after Lennie Small from Of Mice and Men. Beware,
while cute, it may cuase more trouble that it's worth.

The goal is to use as few external libraries as possible because it's a fun
way to learn all of the fundemental aspects of a http application server.

It includes:

1. A http server library.
2. A template rendering library.
3. A unit testing library.

You can see a simple example server in app.lua.

This project is not yet ready for others to use for learning or in
production.

## Notes:
* This needs a way to manager persistent state. I'm a fan of repository
  pattern data access returning domain objects. This is the approach I will
  take for the data access library.
