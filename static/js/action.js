// Generated by CoffeeScript 1.6.3
(function() {
  var Action, exports;

  Action = (function() {
    var Session, Spaces, logger;

    function Action() {}

    logger = require('./logger');

    Session = require("./session");

    Spaces = require('spaces-client');

    Action.actions = null;

    Action.siteSeeds = [];

    Action.userSeeds = [];

    Action.init = function(oncomplete) {
      return Action.readActions(function() {
        return oncomplete();
      });
    };

    Action.seedSite = function(site, userId, oncomplete) {
      return Action.launchNextSeed(site, userId, this.siteSeeds, oncomplete);
    };

    Action.seedUser = function(site, userId, oncomplete) {
      return Action.launchNextSeed(site, userId, this.userSeeds, oncomplete);
    };

    Action.launchNextSeed = function(site, userId, seedArray, oncomplete) {
      var action;
      if (seedArray.length > 0) {
        if (action = seedArray[0]) {
          return Action.launch(site, userId, action, (function() {
            return Action.launchNextSeed(site, userId, seedArray.slice(1), oncomplete);
          }));
        }
      } else {
        if (oncomplete) {
          return oncomplete();
        }
      }
    };

    Action.doSomething = function(site, userId) {
      return Action.launch(site, userId, Action.actions[Math.floor(Math.random() * Action.actions.length)], null);
    };

    Action.launch = function(site, userId, action, oncomplete) {
      var eventHandlers, parentId, resource, sessionId;
      resource = null;
      switch (action.method) {
        case 'delete':
        case 'update':
        case 'show':
          if (!(resource = Session.getRandomUserItemIdOfType(site, userId, action.resource))) {
            logger.info("[%s][%s] Resource not found, so aborting, resource[%s] - method[%s]", site.site_id, userId, action.resource, action.method);
            return false;
          }
          break;
        default:
          switch (action.resource) {
            case 'blogpost':
            case 'blog_post':
              action.parent = 'blog';
              break;
            case 'document':
              action.parent = 'folder';
              break;
            case 'discussion':
              action.parent = 'forum';
              break;
            case 'idea':
              action.parent = 'ideastorm';
              break;
            case 'wikipage':
            case 'wiki_page':
              action.parent = 'wiki';
          }
          if (action.parent) {
            parentId = Session.getRandomUserItemIdOfType(site, userId, action.parent);
            if (!parentId) {
              if (action.method === 'create') {
                logger.error("[%s][%s] Resource not found - not launching activity. \"%s %s in %s\"", site.site_id, userId, action.method, action.resource, action.parent);
              } else {
                logger.info("[%s][%s] Resource not found - not launching activity. \"%s %s in %s\"", site.site_id, userId, action.method, action.resource, action.parent);
              }
              return false;
            }
          }
      }
      eventHandlers = {
        oncreate: function(id) {
          return Session.addItem(site, userId, action.resource, id);
        },
        ondelete: function() {
          logger.info("REMINDER: I don't think removeItem works right now!");
          return Session.removeItem(site, userId, action.resource, null);
        },
        onsuccess: function() {
          Session.addActivity();
          if (oncomplete) {
            return oncomplete();
          }
        },
        onfail: function() {
          Session.addError();
          if (oncomplete) {
            return oncomplete();
          }
        }
      };
      sessionId = Session.getUserSessionId(site, userId);
      return Spaces.process(site, userId, action, sessionId, parentId, eventHandlers);
    };

    Action.readActions = function(oncomplete) {
      var fs, readline;
      Spaces.logger.debug("Action.readActions: Loading actions file");
      fs = require('fs');
      readline = require('readline');
      Action.actions = [];
      return readline.createInterface({
        input: fs.createReadStream('./actions'),
        output: process.stdout,
        terminal: false
      }).on('line', (function(line) {
        var action, e, expr, label, method, parent, resource, seedSite, seedUser, weight;
        if (line.match(/^\s*(#|$)/)) {
          return;
        }
        if (expr = line.match(/\[\s*(\w+)\s*\]/)) {
          label = expr[1].toLowerCase();
          seedSite = label.match(/site/i);
          seedUser = label.match(/user/i);
          if (!(seedSite || seedUser)) {
            weight = parseInt(label);
          }
        } else {
          weight = 1;
          seedSite = false;
          seedUser = false;
        }
        try {
          expr = line.match(/(\w+)\s+(a|an)\s+(\w+)\s+(in a)\s+(\w+)/i);
          if (expr) {
            parent = expr[5];
          } else {
            expr = line.match(/(\w+)\s+(a|an)\s+(\w+)\s*/i);
          }
          method = expr[1].toLowerCase();
          resource = expr[3].toLowerCase();
          action = {
            weight: weight,
            method: method,
            resource: resource,
            parent: parent
          };
          if (seedSite) {
            return Action.siteSeeds.push(action);
          } else if (seedUser) {
            return Action.userSeeds.push(action);
          } else {
            return Action.actions.push(action);
          }
        } catch (_error) {
          e = _error;
          logger.error("Syntax Error in actions config: %s", line);
          throw e;
        }
      })).on('close', (function() {
        if (oncomplete) {
          return oncomplete();
        }
      }));
    };

    return Action;

  })();

  module.exports = exports = Action;

}).call(this);
