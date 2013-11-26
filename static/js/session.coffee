# This clas:
## registers sites
# - initializes some values within a new site
# - saves the site in a local array
## registers users
# - stores the session in session
# - registers personal doclibs
# - saves the user in a local array
## registers items

class Session
  Spaces = require('spaces-client')
  logger = require('./logger')

  # Emitter

  @activityCount = 0
  @errorCount = 0

  @startEmitter = () ->
    Session.emit(0, 0)

  @emit = (lastActivityCount, lastErrorCount) ->
    if Spaces.socket
      activityCount = @activityCount
      errorCount = @errorCount
      activityRate = @activityCount - lastActivityCount
      errorRate = @errorCount - lastErrorCount
      Spaces.socket.emit "stats", { ts: new Date().getTime(), stats: {
        siteCount: @totalSites,
        userCount: @totalActiveUsers,
        itemCount: @itemCount,
        activityCount: activityCount,
        activityRate: activityRate,
        errorCount: errorCount,
        errorRate: errorRate,
        appServerCount: @appServerCount,
        jobServerCount: @jobServerCount
      }}

    callback = () -> Session.emit(activityCount, errorCount)
    setTimeout callback, 5000

  Session.startEmitter()

  # SITES

  @totalSites = 0
  @sites = {}
  @siteArray = []

  @registerSite = (site) ->
    site.users = []
    site.signupPeriod = 8000
    site.currentUsers = 0
    site.maxUsers = 50000
    # TODO uncomment the above and randomize these runtime characteristics
    #    site.signupPeriod = 20000 + Math.floor(Math.Random() * 100000) # 20 - 120 seconds
    #    site.maxUsers = 10 + Math.floor(Math.Random() * 49990) # 10-50000 users

    this.items[site.site_id] = {}
    this.siteArray.push site.site_id
    this.sites[site.site_id] = site
    this.totalSites += 1

    return site

  @siteCount = () ->
    return this.totalSites

  @getSite = (siteId) ->
    return this.sites[siteId]

  @getRandomSite = () ->
    return this.sites[this.siteArray[Math.floor(Math.random() * this.siteArray.length)]]

  # SERVERS

  @appServerCount = 0
  @jobServerCount = 0

  @startPoller = () ->
    Session.poll()

  @poll = () ->
    if this.sites[0]
      Spaces.Pod.getPods(@sites[0], ((appServerCount, jobServerCount) ->
        @appServerCount = appServerCount
        @jobServerCount = jobServerCount
      ))

    callback = -> Session.poll()
    setTimeout callback, 10000

  Session.startPoller()

  # USERS

  @totalActiveUsers = 0

  @registerUser = (siteId, user, sessionId) ->
    logger.debug "[%s][%s] Session.registerUser [%s] with session [%s]", siteId, user.id, user.email, sessionId
    this.setUserSessionId(siteId, user.id, sessionId)
    this.totalActiveUsers += 1

    site = this.getSite(siteId)
    site.currentUsers += 1
    site.users.push user.id

    this.items[user.id] = {}
    this.registerPersonalDocLib(site, user.id) unless user.email == 'tech-support@moxiesoft.com'

    return site

  @userCount = () ->
    return this.totalActiveUsers

  # USER SESSIONS

  @userSessions = {}

  @setUserSessionId = (siteId, userId, id) ->
    @userSessions[userId] = {} unless @userSessions[userId]
    @userSessions[userId]["id"] = id

  @getUserSessionId = (site, userId) ->
    if session = @userSessions[userId]
      if sessionId = session["id"]
        return sessionId
      else
        logger.error("[%s][%s] Session.getUserSessionId: Couldn't find session ID", site.site_id, userId)
    else
      logger.error("[%s][%s] Session.getUserSessionId: Couldn't find user session", site.site_id, userId)

  # ITEMS

  @itemCount = 0
  @items = {}

  @addItem = (site, userId, type, item) ->
    logger.debug("[%s][%s] Session.addItem: Added a %s [%s]", site.site_id, userId, type, item)
    @itemCount += 1

    if @items[userId]
      @items[userId][type] = [] unless @items[userId][type]
      @items[userId][type].push item
    else
      logger.error("[%s][%s] Session.addItem: user items not found", site.site_id, userId)

    # store the item for the site as well
    if @items[site.site_id]
      @items[site.site_id][type] = [] unless @items[site.site_id][type]
      @items[site.site_id][type].push item
    else
      logger.error("[%s][%s] Session.addItem: site items not found", site.site_id, userId)

  @getRandomUserItemIdOfType = (site, userId, type) ->
    if @items[userId]
      if list = @items[userId][type]
        return list[Math.floor(Math.random() * list.length)]
      else
        logger.debug("[%s][%s] Session.getRandomUserItemIdOfType: user doesn't have a valid %s", site.site_id, userId, type)
    else
      logger.error("[%s][%s] Session.getRandomUserItemIdOfType: Couldn't find user session", site.site_id, userId)

  @getRandomSiteItemIdOfType = (site, userId, type) ->
    if @items[site.site_id]
      if list = @items[site.site_id][type]
        return list[Math.floor(Math.random() * list.length)]
#      else
#        logger.debug("[%s][%s] Session.getRandomSiteItemIdOfType: site doesn't have a valid %s", site.site_id, userId, type)
    else
      logger.error("[%s][%s] Session.getRandomSiteItemIdOfType: Couldn't find site session", site.site_id, userId)

  @registerPersonalDocLib = (site, userId) ->
    sessionId = this.getUserSessionId(site, userId)
    Spaces.Folder.getPersonalDocLibId(site, userId, sessionId, ((folderId) ->
      Spaces.logger.info("[%s][%s] Registering personal folder", site.site_id, userId)
      Session.addItem(site, userId, 'folder', folderId)
    ))

  # ACTIVITIES

  @addActivity = () ->
    @activityCount += 1

  # ERRORS

  @addError = () ->
    @errorCount += 1

module.exports = exports = Session

