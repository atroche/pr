addMessage = (message) ->
  $('#messages').append $("<div>" + message + "</div>")

$ ->
  $('#chat-window').hide()

  socket = io.connect('/')
  sendMessage = (event) ->
    messageBox = $('input[name=message]')
    message = messageBox.val()
    if message
      socket.emit("message_sent", messageBox.val())
      messageBox.val('')
      messageBox.focus()
    return false

  disableFields = ->
    $('#message-input').attr('disabled', true)
    $('#send-message').toggleClass 'disabled'

  socket.on 'got name', (name) ->
    $('#chat-window').show()
    addMessage "Welcome, " + name + "! You are based in <b>London</b>."
    addMessage "Searching for someone to talk to..."
    disableFields()

  socket.on 'found a partner', (name) ->
    $('#message-input').attr('disabled', false)
    $('#send-message').toggleClass 'disabled'
    addMessage "You are now chatting to: " + name
    console.log 'ready received'

  socket.on 'message_rec', (message, from) ->
    addMessage from + ": " + message

  socket.on 'other person disconnected', (name) ->
    addMessage name + " disconnected"
    addMessage "Searching for someone to talk to..."
    disableFields()

  socket.on 'connect', ->
    console .log 'connected'
    bootbox.prompt "What's your name?", (name) ->
      socket.emit "nickname given", name

  $('.navbar').click ->
    socket.disconnect()

  $('#send-message').click sendMessage
  $('form[name=messages]').submit sendMessage

