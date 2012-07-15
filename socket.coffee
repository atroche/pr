express = require('express')
app = express()

app.use(express.static(__dirname + '/public'))

# static index page
app.get '/', (req, res) ->
  res.sendfile(__dirname + '/index.html')

server = app.listen 8080

io = require('socket.io').listen(server)

_ = require 'underscore'

waitingUsers = []


removeFromWaitingList = (id) ->
  console.log "removing " + id + " from waiting list: " + waitingUsers
  waitingUsers = (u for u in waitingUsers when u.uid != id)


logWaitingRoom = ->
  console.log "waiting users: " + waitingUsers

io.sockets.on 'connection', (newUser) ->
  newUser.uid = _.uniqueId()
  newUser.set 'connected', true
  console.log newUser.uid + " connected"
  logWaitingRoom()
  newUser.on 'nickname given', (name) ->
    newUser.on 'message_sent', (message) ->
      newUser.emit 'message_rec', message, name

    newUser.set 'name', name, ->

      newUser.emit 'got name', name

      newUser.on 'disconnect', ->
        newUser.set 'connected', false
        console.log newUser.uid + " disconnected"
        newUser.get 'partner', (error, partner) ->
          newUser.get "name", (error, name) ->
            partner.emit "other person disconnected", name
            partner.get 'connected', (e, connected) ->
              if connected
                waitingUsers.push partner
        removeFromWaitingList newUser.uid

      unless waitingUsers.length
        waitingUsers.push newUser
        console.log "making " + newUser.uid + " wait"
        logWaitingRoom()
        return


      firstUser = waitingUsers.shift()

      console.log "connecting " + firstUser.uid + " and " + newUser.uid

      connectUsers = (first, second) ->

        handleMessagesOf = (user) ->
          user.get 'name', (error, name) ->
            user.get 'partner', (error, partner) ->
              user.on 'message_sent', (message) ->
                partner.emit 'message_rec', message, name

        first.set 'partner', second, ->
          second.set 'partner', first, ->
            handleMessagesOf u for u in [first, second]

            first.get 'name', (e, name) ->
              second.emit 'found a partner', name

            second.get 'name', (e, name) ->
              first.emit 'found a partner', name


      connectUsers firstUser, newUser