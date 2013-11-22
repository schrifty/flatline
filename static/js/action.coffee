class Action
  logger = require('./logger')
  Session = require("./session")
  Spaces = require('spaces-client')

  @actions = null
  @siteSeeds = []
  @userSeeds = []

  @init = (oncomplete) ->
    Action.readActions(() ->
      oncomplete()
    )

  @seedSite = (site, userId, oncomplete) ->
    Action.launchNextSeed(site, userId, @siteSeeds, oncomplete)

  @seedUser = (site, userId, oncomplete) ->
    Action.launchNextSeed(site, userId, @userSeeds, oncomplete)

  @launchNextSeed = (site, userId, seedArray, oncomplete) ->
    if seedArray.length > 0
      if action = seedArray[0]
        Action.launch(site, userId, action, (() ->
          Action.launchNextSeed(site, userId, seedArray.slice(1), oncomplete)
        ))
    else
      oncomplete() if oncomplete

  @doSomething = () ->
    action = Action.actions[Math.floor(Math.random() * Action.actions.length)]
    site = Session.getRandomSite()
    userId = site.users[Math.floor(Math.random() * site.users.length)]
    Action.launch(site, userId, action, null)

  @launch = (site, userId, action, oncomplete) ->
    resource = null

    switch action.method
      when 'delete', 'update', 'show'
        unless resource = Session.getRandomUserItemIdOfType(site, userId, action.resource)
          logger.info "[%s][%s] Resource not found, so aborting, resource[%s] - method[%s]", site.site_id, userId, action.resource, action.method
          return false
      else
        switch action.resource
          when 'blogpost', 'blog_post'
            action.parent = 'blog'
          when 'document'
            action.parent = 'folder'
          when 'discussion'
            action.parent = 'forum'
          when 'idea'
            action.parent = 'ideastorm'
          when 'wikipage', 'wiki_page'
            action.parent = 'wiki'

        if action.parent
#          if action.parent == 'category'
#            resource = Session.getRandomSiteItemIdOfType(site, userId, action.parent)
#          else
          resource = Session.getRandomUserItemIdOfType(site, userId, action.parent)
          unless resource
            logger.info "[%s][%s] Resource not found - not launching activity. %s - %s in %s", site.site_id, userId, action.method, action.resource, action.parent
            return false

    eventHandlers = {
      oncreate: (klass, id) ->
        Session.addItem(site, userId, klass, id)
      ondelete: (klass, id) ->
        Session.removeItem(site, userId, klass, id)
      onsuccess: () ->
        Session.addActivity()
        oncomplete() if oncomplete
      onfail: () ->
        Session.addError()
        oncomplete() if oncomplete
    }

    sessionId = Session.getUserSessionId(site, userId)
    Spaces.process(site, userId, action, sessionId, resource, eventHandlers)

  @readActions = (oncomplete) ->
    Spaces.logger.debug "Action.readActions: Loading actions file"

    fs = require('fs')
    readline = require('readline')

    Action.actions = []
    readline.createInterface({
      input: fs.createReadStream('./actions'),
      output: process.stdout,
      terminal: false
    }).on('line', ((line) ->
      # skip comments and empty lines
      return if line.match(/^\s*(#|$)/)

      if expr = line.match(/\[\s*(\w+)\s*\]/)
        label = expr[1].toLowerCase()
        seedSite = label.match(/site/i)
        seedUser = label.match(/user/i)
        unless seedSite || seedUser
          weight = parseInt(label)
      else
        weight = 1
        seedSite = false
        seedUser = false

      try
        expr = line.match(/(\w+)\s+(a|an)\s+(\w+)\s+(in a)\s+(\w+)/i)
        if expr
          parent = expr[5]
        else
          expr = line.match(/(\w+)\s+(a|an)\s+(\w+)\s*/i)

        method = expr[1].toLowerCase()
        resource = expr[3].toLowerCase()

        action = {weight: weight, method: method, resource: resource, parent: parent}
        if seedSite
          Action.siteSeeds.push action
        else if seedUser
          Action.userSeeds.push action
        else
          Action.actions.push action
      catch e
        logger.error("Syntax Error in actions config: %s", line)
        throw e
    )).on('close', (() ->
      oncomplete() if oncomplete
    ))

module.exports = exports = Action