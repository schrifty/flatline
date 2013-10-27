window.Flatline ||= {}

$(document).ready ->

# TODO: Reinstate the socket.io stuff
#  socket = io.connect()
#  $("#sender").bind "click", ->
#    socket.emit "message", "Message Sent on " + new Date()
#
#  socket.on "server_message", (data) ->
#    $("#receiver").append "<li>" + data + "</li>"

  $('#sender').on 'click', (event) ->
    Flatline.start()

  $('#login').on 'click', (event) ->
    Flatline.login()

  $('#createuser').on 'click', (event) ->
    Flatline.createUser()

Flatline.start = () ->
  data = {}
  $.ajax '/run',
    type: 'POST',
    data: data,
    error: (jqXHR, textStatus, errorThrown) ->
      console.log textStatus + " - " + errorThrown + " - " + JSON.stringify(jqXHR)

# TODO: Remove me
Flatline.login = () ->
  data = {
    site: {
      sub_domain : 'xxjess',
      domain : 'moxiedev.com',
      full_url : "https://xxjess.moxiedev.com",
      users: { }
    }
  }
  $.ajax '/login',
    type: 'POST',
    data: data,
    error: (jqXHR, textStatus, errorThrown) ->
      console.log textStatus + " - " + errorThrown + " - " + JSON.stringify(jqXHR)

# TODO: Remove me
Flatline.createUser = () ->
  data = {
    site: {
      sub_domain : 'xxjess',
      domain : 'moxiedev.com',
      full_url : "https://xxjess.moxiedev.com",
      users: { }
    }
  }
  $.ajax '/createuser',
    type: 'POST',
    data: data,
    error: (jqXHR, textStatus, errorThrown) ->
      console.log textStatus + " - " + errorThrown + " - " + JSON.stringify(jqXHR)
