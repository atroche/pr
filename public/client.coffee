socket = io.connect('/')

socket.on 'ready for chat', ->
  console.log 'ready received'
  $('#please-wait').hide()
  $('#chat-window').show()

socket.on 'please wait', ->
  console.log 'ready received'
  $('#please-wait').show()
  $('#chat-window').hide()

socket.on 'message_rec', (message) ->
  $('#messages').append $("<div>" + message + "</div>")

$ ->

  sendMessage = (event) ->
    messageBox = $('input[name=message]')
    socket.emit("message_sent", messageBox.val())
    messageBox.val('')
    return false

  $('#send-message').click sendMessage
  $('form[name=messages]').submit sendMessage