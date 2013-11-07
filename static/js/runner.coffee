SITE_CREATE_FREQUENCY_MS = 5000

class Runner
  maxSites = 1
  maxServers = 5
  newUserPeriod = 10000

  @sites = []
  Action = require("./action")
  logger = require("./logger")
  Config = require("./config")
  Faker = require("Faker")
  Spaces = require("spaces-client")
  Spaces.setLogger(logger)
  Spaces.setMothershipURL(Config.mothershipUrl)
  Spaces.setApiKey(Config.apiKey)

  @start: () ->
    Runner.createSites()

  @createSites: () ->
    site_name = "xx" + Faker.Internet.domainWord()
    data = {
      site: {
        site_id: site_name,
        customer_name: "Acme",
        site_type_name: "Freemium",
#        pod_id: 7614,
        settings: {
          skip_signup_activation: true
        }
      }
    }
    Spaces.Site.createSite(data, ((site) ->
#      console.log "BEFORE: " + site.full_url
#      site.full_url = site.full_url.replace(/https/, "http")
#      site.full_url = site.full_url + ":8888"
#      console.log "AFTER: " + site.full_url
      Runner.sites.push site

      # if we successfully created the site, lets log tech-support in and seed the site with a little structure
      Runner.login(site, 'tech-support@moxiesoft.com', 'k3ithm00n', ((userId) ->
        Spaces.Session.setAdminId(userId)
        Action.seed(site, userId)
        Runner.createUser(site)
        if Runner.sites.length < maxSites
          callback = ->
            Runner.createSite()
          setTimeout callback, (SITE_CREATE_FREQUENCY_MS / 2) + Math.random(SITE_CREATE_FREQUENCY_MS)
      ))
    ), ((message) ->
      logger.debug("Unable to create successfully - abandoning site [%s]", site.site_id)
    ))

  @createUser: (site) ->
    Runner.sites.push site unless Runner.sites.length > 0 # TODO remove this

    password = "L1berty*"
    email = Faker.Internet.email()
    data = {
      user: {
        email: email,
        display_name: Faker.Name.findName(),
        password: password,
        password_confirmation: password
      }
    }
    Spaces.User.create(data, site.full_url, ((user) ->
      logger.debug("[%s][%s] Added User", site.site_id, user.id)
      # only kick off the user once they've successfully logged in
      Runner.login(site, email, password, ((userId) ->
        Runner.registerPersonalDocLib(site, userId)
        site.users = [] unless site.users
        site.users.push userId
        Runner.startActivity(site, userId)
      ))
      callback = () ->
        Runner.createUser(site)
      setTimeout callback, 1000
    ), ((message) ->
      logger.debug message
    ))

  @registerPersonalDocLib = (site, userId) ->
    XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest
    xhr = new XMLHttpRequest()
    xhr.setDisableHeaderCheck(true)
    xhr.open('GET', site.full_url + "/current_user/document_library", true)
    xhr.setRequestHeader("Accept", "application/vnd.moxiesoft.spaces-v1+json")
    xhr.setRequestHeader("Cookie", ["_social_navigator_session=" + Spaces.Session.getSessionId(site, userId), "path=/"])
    xhr.onload = () ->
      if this.status == 200 || this.status == 201
        folderId = this.responseText.match(/"id":"(.*?)"/)[1]
        Spaces.Session.addItem(site, userId, 'folder', folderId)
      else
        Spaces.logger.error("[%s][%s] DocLib recovery failed: %s - %s", site.site_id, userId, this.status, this.responseText)
    xhr.send()

  @login: (site, email, password, onsuccess) ->
    Runner.sites.push site unless Runner.sites.length > 0 # TODO remove this

    data = {
      user: {
        email: email,
        password: password
      }
    }
    Spaces.Site.login(data, site, ((resp, cookies) ->
      userId = resp.match(/"id":"(.*?)"/)[1]
      Spaces.Session.setSessionId(userId, cookies['_social_navigator_session'])
      onsuccess(userId)
    ), ((msg) ->
      logger.debug("User failed to log in [%s:%s]: %s", email, password, msg)
    ))

  @startActivity: (site, userId) ->
    Action = require("./action.js")
    Action.doSomething(Runner.sites, site.full_url, userId)
    callback = ->
      Runner.startActivity(site, userId)
    setTimeout callback, 10000

module.exports = Runner