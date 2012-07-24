RouletteApp = ->
  apiKey = 16664242
  mySession = undefined
  partnerSession = undefined
  ele = {}
  TB.setLogLevel TB.DEBUG
  init = (sessionId, token) ->
    sessionConnectedHandler = (event) ->
      console.log "Connected, press allow."
      publisher = mySession.publish("publisher")
    streamCreatedHandler = (event) ->
      stream = event.streams[0]
      SocketProxy.findPartner mySession.sessionId  if mySession.connection.connectionId is stream.connection.connectionId
    ele.nextButton = document.getElementById("nextButton")
    console.log("Connecting...")
    # ele.nextButton.onclick = ->
    #   RouletteApp.next()

    mySession = TB.initSession(sessionId)
    mySession.addEventListener "sessionConnected", sessionConnectedHandler
    mySession.addEventListener "streamCreated", streamCreatedHandler
    mySession.connect apiKey, token

  next = ->
    if partnerSession.connected
      SocketProxy.disconnectPartners()
    else
      SocketProxy.findPartner()

  disconnectPartner = ->
    partnerSession.disconnect()

  subscribe = (sessionId, token) ->
    sessionConnectedHandler = (event) ->
      partnerSession.subscribe event.streams[0], "subscriber"
    sessionDisconnectedHandler = (event) ->
      partnerSession.removeEventListener "sessionConnected", sessionConnectedHandler
      partnerSession.removeEventListener "sessionDisconnected", sessionDisconnectedHandler
      partnerSession.removeEventListener "streamDestroyed", streamDestroyedHandler
      SocketProxy.findPartner mySession.sessionId
      partnerSession = null
    streamDestroyedHandler = (event) ->
      partnerSession.disconnect()
    console.log "Have fun !!!!"
    partnerSession = TB.initSession(sessionId)
    partnerSession.addEventListener "sessionConnected", sessionConnectedHandler
    partnerSession.addEventListener "sessionDisconnected", sessionDisconnectedHandler
    partnerSession.addEventListener "streamDestroyed", streamDestroyedHandler
    partnerSession.connect apiKey, token

  wait = ->
    console.log "Nobody to talk to :(.  When someone comes, you'll be the first to know :)."

  init: init
  next: next
  subscribe: subscribe
  disconnectPartner: disconnectPartner
  wait: wait


RouletteApp = RouletteApp()


socket = io.connect('/')
socket.on "initial", (data) ->
  console.log data
  RouletteApp.init data.sessionId, data.token

socket.on "subscribe", (data) ->
  RouletteApp.subscribe data.sessionId, data.token

socket.on "disconnectPartner", (data) ->
  RouletteApp.disconnectPartner()

socket.on "empty", (data) ->
  RouletteApp.wait()

SocketProxy =
  findPartner: (mySessionId) ->
    socket.emit "next",
      sessionId: mySessionId

  disconnectPartners: ->
    socket.emit "disconnectPartners"