fs = require 'fs'

express = require 'express'
OpenTok = require 'opentok'
_ = require 'underscore'

ot = null

fs.readFile "api_secret.txt", "UTF-8", (err, data) ->
  api_secret = data.trim()
  api_key = "16664242"
  ot = new OpenTok.OpenTokSDK(api_key, api_secret);



app = express()

app.use(express.static(__dirname + '/public'))

# static index page
app.get '/', (req, res) ->
  res.sendfile(__dirname + '/index.html')

server = app.listen 8080

io = require('socket.io').listen(server)



soloUsers = []
clients = {}



io.sockets.on "connection", (socket) ->
  clients[socket.id] = socket
  ot.create_session "localhost", (sessionId) ->
    data =
      sessionId: sessionId
      token: ot.generateToken(
        sessionId: sessionId
        role: OpenTok.RoleConstants.PUBLISHER
      )

    socket.emit "initial", data

  socket.on "next", (data) ->
    me =
      sessionId: data.sessionId
      socketId: socket.id

    partner = undefined
    partnerSocket = undefined
    i = 0

    while i < soloUsers.length
      tmpUser = soloUsers[i]
      unless socket.partner is tmpUser
        partnerSocket = clients[tmpUser.socketId]
        soloUsers.splice i, 1
        if partnerSocket
          partner = tmpUser
          break
      i++
    if partner
      socket.emit "subscribe",
        sessionId: partner.sessionId
        token: ot.generateToken(
          sessionId: partner.sessionId
          role: OpenTok.RoleConstants.SUBSCRIBER
        )

      partnerSocket.emit "subscribe",
        sessionId: me.sessionId
        token: ot.generateToken(
          sessionId: me.sessionId
          role: OpenTok.RoleConstants.SUBSCRIBER
        )

      socket.partner = partner
      partnerSocket.partner = me
      socket.inlist = false
      partnerSocket.inlist = false
    else
      delete socket.partner  if socket.partner
      unless socket.inlist
        socket.inlist = true
        soloUsers.push me
      socket.emit "empty"

  socket.on "disconnectPartners", ->
    if socket.partner and socket.partner.socketId
      partnerSocket = clients[socket.partner.socketId]
      partnerSocket.emit "disconnectPartner"  if partnerSocket
      socket.emit "disconnectPartner"

  socket.on "disconnect", ->
    delete clients[socket.id]