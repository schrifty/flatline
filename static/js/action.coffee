logger = require('./logger.js')

SEED_METADATA = [
  ['Category', 'create'],
  ['Category', 'create'],
  ['Category', 'create'],
  ['Category', 'create'],
  ['Category', 'create']
]

ACTION_METADATA = [
  [10, 'Activity', 'create'],
  [ 5, 'Blog', 'create', 'group'],
  [ 1, 'Blog', 'updateBlog'],
  [ 1, 'Blog', 'deleteBlog'],
  [10, 'Blog', 'createPost', 'blog'],
  [ 2, 'Blog', 'updatePost'],
  [ 1, 'Blog', 'deletePost'],
  [ 1, 'Category', 'create'],
  [ 5, 'Folder', 'create', 'folder'],
  [ 1, 'Folder', 'createDocument', 'folder'],
  [ 1, 'Folder', 'deleteDocument']
  [ 5, 'Forum', 'create', 'group'],
  [ 1, 'Forum', 'updateForum'],
  [ 1, 'Forum', 'deleteForum'],
  [10, 'Forum', 'createDiscussion', 'discussion_archive'],
  [ 2, 'Forum', 'updateDiscussion'],
  [ 1, 'Forum', 'deleteDiscussion'],
  [ 5, 'Group', 'create', 'category'],
  [ 5, 'Group', 'create', 'group'],
  [10, 'Ideastorm', 'create', 'group'],
  [ 5, 'Ideastorm', 'updateIdeastorm'],
  [ 1, 'Ideastorm', 'deleteIdeastorm'],
  [10, 'Ideastorm', 'createIdea', 'ideastorm'],
  [ 2, 'Ideastorm', 'updateIdea'],
  [ 1, 'Ideastorm', 'deleteIdea']
#  ['ideastorm', 'show', 100],
#  ['ideastorm', 'show_idea', 200],
#  [10, 'Activity', 'show']
#    ['category', 'delete', 5],
#    ['category', 'update', 5],
#    ['category', 'show', 100],
#    ['group', 'delete', 10],
#    ['group', 'show', 200],
#    ['group', 'update', 10],
#    ['blog', 'delete', 5],
#    ['blog', 'deletePost', 10],
#    ['blog', 'show', 100],
#    ['blog', 'showPost', 200],
#    ['blog', 'showMyPosts', 200],
#    ['blog', 'update', 5],
#    ['blog', 'updatePost', 10],
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
  @seed = (site, userId) ->
    for action in SEED_METADATA
      Action.launch(action, site, userId)

  @doSomething = (sites, host, user) ->
    action = actions[Math.floor(Math.random() * actions.length)]
    site = sites[Math.floor(Math.random() * sites.length)]
    site.users = [] unless site.users
    userId = site.users[Math.floor(Math.random() * site.users.length)]
    Action.launch(action, site, userId)

  @launch = (action, site, userId) ->
    skip = false
    parent = null
    if action[2]
      unless parent = Spaces.Session.getRandomUserItemIdOfType(site, userId, action[2])
#        logger.warn("[%s][%s] WARN: action (%s#%s) not launched because no valid parent %s was found", site.site_id, userId, action[0], action[1], action[2])
        skip = true

    unless skip
      if klass = Spaces[action[0]]
        if f = klass[action[1]]
          f.apply(klass, [site, parent, userId])
        else
          logger.error("[%s][%s] Couldn't find Spaces.%s.%s()", site.site_id, userId, action[0], action[1])
      else
        logger.error("[%s][%s] Couldn't find Spaces.%s", site, userId, action[0])

module.exports = exports = Action