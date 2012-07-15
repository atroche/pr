express = require('express')
app = express()

app.use(express.static(__dirname + '/public'))

# static index page
app.get '/', (req, res) ->
  res.sendfile(__dirname + '/index.html')

server = app.listen 3000

io = require('socket.io').listen(server)

_ = require 'underscore'

waitingUsers = []


removeFromWaitingList = (id) ->
  waitingUsers = [u for u in waitingUsers where u.uid != id]


logWaitingRoom = ->
  console.log "waiting users: " + waitingUsers

io.sockets.on 'connection', (newUser) ->
  newUser.uid = _.uniqueId()
  console.log newUser.uid + " connected"
  logWaitingRoom()
  unless waitingUsers.length
    waitingUsers.push newUser
    console.log "making " + newUser.uid + " wait"
    logWaitingRoom()
    newUser.set "waiting", true, ->
      newUser.emit "please wait"
    return

  newUser.on 'disconnect', ->
    console.log newUser.uid + " disconnected"
    newUser.get 'waiting', (err, waiting) ->
      if waiting
        console.log "removing " + newUser.uid + " from waiting list"
        removeFromWaitingList newUser.uid


  firstUser = waitingUsers.shift()

  console.log "connecting " + firstUser.uid + " and " + newUser.uid

  broadcastToBoth = (data) ->
    firstUser.emit "message_rec", data
    newUser.emit "message_rec", data

  connectUsers = (first, second) ->
    u.on('message_sent', broadcastToBoth) for u  in [first, second]

    console.log 'making ' + first.uid + ' ready'
    first.set "waiting", false, ->
      first.set "partner_uid", second.uid, ->
        console.log 'telling ' + first.uid + ' to get ready'
        first.emit 'ready for chat'

    console.log 'making ' + second.uid + ' ready'
    second.set "waiting", false, ->
      second.set "partner_uid", first.uid, ->
        console.log 'telling ' + second.uid + ' to get ready'
        second.emit 'ready for chat'

  connectUsers firstUser, newUser