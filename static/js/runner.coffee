# Runner does the following upon start:
# - starts a site creation loop, according to the period and max defined in constants
# - for each site
#   - logs in as tech-support and uses the tech-support account to seed the site with some node hierarchy
#   - starts a user creation loop, according to the period and max defined in constants
#   - for each user
#     - logs in
#     - registers the user's personal doclib for future use
#     - starts an activity loop for the user

# TODO Expose these so the user can set them through the UI
MAX_SITES = 20
MAX_SOCKETS = 500
SITE_INTERVAL_MS = 100000
REST_PERIOD_MS = 10000

class Runner
  Faker = require("Faker")
  Action = require("./action")
  Session = require("./session")
  logger = require("./logger")
  Spaces = require("spaces-client")

  @start: () ->
    require('https').globalAgent.maxSockets = MAX_SOCKETS
    Runner.diagInfo()
    Action.init(() ->
      Runner.createNextSite()
    )

  @diagInfo: () ->
    maxSockets = require('https').globalAgent.maxSockets
    queueDepth = Object.keys(require('https').globalAgent.requests).length
    socketDepth = Object.keys(require('https').globalAgent.sockets).length
    logger.info("********** Max Sockets: [%d]  Queue Depth: [%d]  Socket Depth: [%d]", maxSockets, queueDepth, socketDepth)

    callback = -> Runner.diagInfo()
    setTimeout callback, 60000


  @createNextSite: () ->
    siteId = "xx" + Faker.Internet.domainWord()
    data = {
      site: {
        site_id: siteId,
        customer_name: "Acme",
        site_type_name: "Freemium",
        settings: {
          skip_signup_activation: true
        }
      }
    }

    Spaces.Site.createSite(data, ((site) ->
      site = Session.registerSite(site)
#      Session.addActivity()

      # if we successfully created the site, lets log tech-support in and seed the site with a little structure
      Runner.login(site, 'tech-support@moxiesoft.com', 'k3ithm00n', ((user, cookies) ->
#        Session.addActivity()
#        site = Session.registerUser(site.site_id, user, cookies['_social_navigator_session'])
#        Action.seedSite(site, user.id, (() ->
#          Runner.createUser(site)
#        ))
        Runner.createUser(site)
        if Session.siteCount() < MAX_SITES
          callback = -> Runner.createNextSite()
          setTimeout callback, (SITE_INTERVAL_MS / 2) + Math.floor(Math.random() * SITE_INTERVAL_MS)
      ))
    ), ((message) ->
      logger.error("Unable to create successfully - abandoning site [%s]: %s", siteId, message)
    ))

  @createUser: (site) ->
    password = "P3qu0ts!"
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
#      Session.addActivity()
      logger.debug("[%s][%s] Created User [%s][%s]", site.site_id, user.id, user.id, user.email)
      Runner.login(site, email, password, ((user, cookies) ->
#        Session.addActivity()
        site = Session.registerUser(site.site_id, user, cookies['_social_navigator_session'])
        Action.seedUser(site, user.id, (() ->
          Runner.startActivity(site, user.id)
        ))
      ), ((msg) ->
        logger.error("[%s][%s] Failed to authenticate user: %s", site.site_id, email, msg)
      ))
      if site.currentUsers < site.maxUsers
        callback = () -> Runner.createUser(site)
        setTimeout callback, (site.signupPeriod / 2) + Math.floor(Math.random() * site.signupPeriod)
      else
        logger.info("[%s][%s] usercount: %d, maxusers: %d", site.site_id, 'bleh', Session.userCount(), site.maxUsers)
    ), ((message) ->
      logger.error "[%s][%s] Failed to create user %s", site.site_id, email, message
    ))

  @login: (site, email, password, onsuccess, onfail) ->
    data = {
      user: {
        email: email,
        password: password
      }
    }
    Spaces.Site.login(data, site, ((resp, cookies) ->
      logger.debug("[%s][%s] Authed User [%s][%s][%s]", site.site_id, email, cookies['_social_navigator_session'])
      onsuccess(JSON.parse(resp), cookies)
    ), ((msg) ->
      onfail(msg) if onfail
    ))

  @startActivity: (site, userId) ->
    require("./action").doSomething(site, userId)
    callback = () -> Runner.startActivity(site, userId)
    setTimeout callback, (REST_PERIOD_MS / 2) + Math.floor(Math.random() * REST_PERIOD_MS)

module.exports = Runner