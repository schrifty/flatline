#setup Dependencies

#Setup Express

#setup the errors

#Setup Socket.IO

#/////////////////////////////////////////
#              Routes                   //
#/////////////////////////////////////////

#///// ADD ALL YOUR ROUTES HERE  /////////

#A Route for Creating a 500 Error (Useful to keep around)

#The 404 Route (ALWAYS Keep this as the last route)
NotFound = (msg) ->
  @name = "NotFound"
  Error.call this, msg
  Error.captureStackTrace this, arguments_.callee
connect = require("connect")
express = require("express")
$ = require("jquery")
Runner = require("./static/js/runner")
Spaces = require("spaces-client")

logger = require("./static/js/logger")
Spaces.setLogger(logger)

Config = require("./static/js/config")
Spaces.setMothershipURL(Config.mothershipUrl)
Spaces.setApiKey(Config.apiKey)

port = (process.env.PORT or 8081)

server = express.createServer()
server.configure ->
  server.set "views", __dirname + "/views"
  server.set "view options",
    layout: false

#  server.use express.logger('dev')
  server.use express.favicon()
  server.use connect.bodyParser()
  server.use express.cookieParser()
  server.use express.session(secret: "shhhhhhhhh!")
  server.use connect.static(__dirname + "/static")
  server.use server.router

server.error (err, req, res, next) ->
  if err instanceof NotFound
    res.render "404.jade",
      locals:
        title: "404 - Not Found"
        description: ""
        author: ""
        analyticssiteid: "XXXXXXX"
      status: 404
  else
    res.render "500.jade",
      locals:
        title: "The Server Encountered an Error"
        description: ""
        author: ""
        analyticssiteid: "XXXXXXX"
        error: err
      status: 500
server.listen port

# socket.io
io = require("socket.io")
io = io.listen(server)
io.set('log level', 1)
io.sockets.on "connection", (socket) ->
  Spaces.setSocket(socket)
#  logger.debug("Client Connected")
#  socket.on "message", (data) ->
#    socket.broadcast.emit "server_message", data
#    socket.emit "server_message", data
#
#  socket.on "disconnect", ->
#    logger.debug("Client Disconnected.")

server.get "/", (req, res) ->
  res.render "index.jade",
    locals:
      title: "Your Page Title"
      description: "Your Page Description"
      author: "Your Name"
      analyticssiteid: "XXXXXXX"

server.post "/run", (req, res) ->
  Runner.start()
  res.send 200

server.post "/login", (req, res) ->
  site = req.body.site
  Runner.login(site)
  res.send 200

server.post "/createuser", (req, res) ->
  site = req.body.site
  Runner.createUser(site, null)
  res.send 200

server.get "/500", (req, res) ->
  throw new Error("This is a 500 Error")

server.get "/*", (req, res) ->
  throw new NotFound

logger.debug("Listening on http://0.0.0.0:%d", port)
