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
CREATE_PERIOD_MS_SITES = 100000
MAX_SITES = 4
REST_PERIOD = 10000

class Runner
  Faker = require("Faker")
  Action = require("./action")
  Session = require("./session")
  logger = require("./logger")
  Spaces = require("spaces-client")

  @start: () ->
    Action.init(() ->
      Runner.createNextSite()
    )

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

      # if we successfully created the site, lets log tech-support in and seed the site with a little structure
      Runner.login(site, 'tech-support@moxiesoft.com', 'k3ithm00n', ((user, cookies) ->
        site = Session.registerUser(site.site_id, user, cookies['_social_navigator_session'])
        Action.seedSite(site, user.id, (() ->
          Runner.createUser(site)
        ))
        if Session.siteCount() < MAX_SITES
          callback = -> Runner.createNextSite()
          setTimeout callback, (CREATE_PERIOD_MS_SITES / 2) + Math.floor(Math.random() * CREATE_PERIOD_MS_SITES)
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
      logger.info("[%s][%s] Added User [%s]", site.site_id, user.id, email)
      Runner.login(site, email, password, ((user, cookies) ->
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
      onsuccess(JSON.parse(resp), cookies)
#      userId = resp.match(/"id":"(.*?)"/)[1]
#      onsuccess(userId, cookies)
    ), ((msg) ->
      onfail(msg) if onfail
    ))

  @startActivity: () ->
    require("./action").doSomething()
    callback = () -> Runner.startActivity()
    setTimeout callback, (REST_PERIOD / 2) + Math.floor(Math.random() * REST_PERIOD)

module.exports = Runner