SITE_CREATE_FREQUENCY_MS = 5000

class Runner
  maxSites = 1
  maxServers = 5
  @sites = []
  Spaces = new require('spaces-client')
  Faker = require('Faker')

  @createSite: () ->
    site_name = "xx" + Faker.Internet.domainWord()
    data = {
      site: {
        site_id: site_name,
        customer_name: "Acme",
        site_type_name: "Freemium",
        settings: {
          skip_signup_activation: true
        }
      }
    }
    Spaces.Site.createSite(data, ((site, cookie) ->
      Runner.sites.push site
      Runner.createUser(site)
      if Runner.sites.length < maxSites
        callback = ->
          Runner.createSite()
        setTimeout callback, (SITE_CREATE_FREQUENCY_MS / 2) + Math.random(SITE_CREATE_FREQUENCY_MS)
    ), ((message) ->
      console.log message
    ))

  @createUser: (site) ->
    Runner.sites.push site unless Runner.sites.length > 0 # TODO remove this

    password = "L1berty*"
    email = Faker.Internet.email()
    data = {
      user: {
        email: email
        display_name: Faker.Name.findName(),
        password: password,
        password_confirmation: password
      }
    }
    Spaces.User.create(data, site.full_url, ((user) ->
      # only kick off the user once they've successfully logged in
      userId = JSON.stringify(user).match(/^.*"id":"(.*?)".*/)[1]
      Runner.login(site, email, password, ((chunk, cookies) ->
        Spaces.Session.setSessionId(userId, cookies['_social_navigator_session'])
        site.users = [] unless site.users
        site.users.push userId
        Runner.startActivity(site, userId)
      ), (() ->
        console.log "User failed to log in [" + email + ":" + password + "]"
      ))
      callback = () ->
        Runner.createUser(site)
      setTimeout callback, 1000
    ), ((message) ->
      console.log (message)
    ))

  @login: (site, email, password, onsuccess, onfail) ->
    Runner.sites.push site unless Runner.sites.length > 0 # TODO remove this

    data = {
      user: {
        email: email,
        password: password
      }
    }
    Spaces.Site.login(data, site, ((chunk, cookies) ->
      onsuccess(chunk, cookies)
    ), ((msg) ->
      onfail(msg)
    ))

  @startActivity: (site, userId) ->
    Action = require("./action.js")
    Action.doSomething(Runner.sites, site.full_url, userId)
    callback = ->
      Runner.startActivity(site, userId)
    setTimeout callback, 10000

module.exports = Runner