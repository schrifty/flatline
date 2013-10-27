ACTION_METADATA = [
#    ['activity', 'show', 20],
#    ['activity', 'create', 10],
  [1, 'Blog', 'create']
  [3, 'Blog', 'createPost', 'blog'],
#    ['blog', 'delete', 5],
#    ['blog', 'deletePost', 10],
#    ['blog', 'show', 100],
#    ['blog', 'showPost', 200],
#    ['blog', 'showMyPosts', 200],
#    ['blog', 'update', 5],
#    ['blog', 'updatePost', 10],
#    ['category', 'create', 10],
#    ['category', 'delete', 5],
#    ['category', 'update', 5],
#    ['category', 'show', 100],
#    ['folder', 'create', 10],
#    ['folder', 'create_document', 10],
#    ['folder', 'delete', 5]
#    ['folder', 'delete_document', 10],
#    ['folder', 'lock_document', 5],
#    ['folder', 'show', 100],
#    ['folder', 'show_document', 200],
#    ['folder', 'unlock_document', 5],
#    ['folder', 'update', 5],
#    ['folder', 'update_document', 10],
#    ['forum', 'create', 10],
#    ['forum', 'create_discussion', 10],
#    ['forum', 'delete', 5],
#    ['forum', 'delete_discussion', 10],
#    ['forum', 'show', 100],
#    ['forum', 'show_discussion', 200],
#    ['forum', 'update', 5],
#    ['forum', 'update_discussion', 10],
#    ['group', 'create', 20],
#    ['group', 'delete', 10],
#    ['group', 'show', 200],
#    ['group', 'update', 10],
#    ['ideastorm', 'create', 10],
#    ['ideastorm', 'create_idea', 10],
#    ['ideastorm', 'delete', 5],
#    ['ideastorm', 'delete_idea', 10],
#    ['ideastorm', 'show', 100],
#    ['ideastorm', 'show_idea', 200],
#    ['ideastorm', 'update', 5],
#    ['ideastorm', 'update_idea', 10],
#    ['user', 'delete', 30],
#    ['user', 'show', 300],
#    ['user', 'update', 30],
#    ['wiki', 'create', 10],
#    ['wiki', 'create_wikipage', 10],
#    ['wiki', 'delete', 5],
#    ['wiki', 'delete_wikipage', 10],
#    ['wiki', 'show', 100],
#    ['wiki', 'show_wikipage', 200],
#    ['wiki', 'update', 5],
#    ['wiki', 'update_wikipage', 10]
  ]

actions = []
for action in ACTION_METADATA
  for i in [0..action[0]-1] by 1
    if action.length < 4
      action[3] = null
    actions.push [action[1], action[2], action[3]]

class Action
  Spaces = require('spaces-client')
  @doSomething = (sites, host, user) ->
    action = actions[Math.floor(Math.random() * actions.length)]
    site = sites[Math.floor(Math.random() * sites.length)]
    site.users = [] unless site.users
    userId = site.users[Math.floor(Math.random() * site.users.length)]

    skip = false
    parent = null
    if action[2]
      unless parent = Spaces.Session.getRandomItemIdOfType(userId, action[2])
        skip = true

    unless skip
      if klass = Spaces[action[0]]
        if f = klass[action[1]]
          f.apply(klass, [site.full_url, parent, userId])
        else
          console.log "ERROR: Couldn't find Spaces." + action[0] + "." + action[1] + "()"
      else
        console.log "ERROR: Couldn't find Spaces." + action[0]

module.exports = exports = Action