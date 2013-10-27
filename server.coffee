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
io = require("socket.io")
Runner = require("./static/js/runner.js")
Spaces = require("spaces-client")
XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest
xhr = new XMLHttpRequest()
xhr.setDisableHeaderCheck(true)

port = (process.env.PORT or 8081)

server = express.createServer()
server.configure ->
  server.set "views", __dirname + "/views"
  server.set "view options",
    layout: false

  server.use express.logger('dev')
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
io = io.listen(server)
io.sockets.on "connection", (socket) ->
  console.log "Client Connected"
  socket.on "message", (data) ->
    socket.broadcast.emit "server_message", data
    socket.emit "server_message", data

  socket.on "disconnect", ->
    console.log "Client Disconnected."

server.get "/", (req, res) ->
  res.render "index.jade",
    locals:
      title: "Your Page Title"
      description: "Your Page Description"
      author: "Your Name"
      analyticssiteid: "XXXXXXX"

server.post "/run", (req, res) ->
  Runner.createSite()

server.post "/login", (req, res) ->
  site = req.body.site
  Runner.login(site)

server.post "/createuser", (req, res) ->
  site = req.body.site
  Runner.createUser(site, null)

server.get "/500", (req, res) ->
  throw new Error("This is a 500 Error")

server.get "/*", (req, res) ->
  throw new NotFound

console.log "Listening on http://0.0.0.0:" + port
