// Generated by CoffeeScript 1.6.3
(function() {
  var CALLBACK_SECS, Session, exports;

  CALLBACK_SECS = 8;

  Session = (function() {
    var Runner, Spaces, logger,
      _this = this;

    function Session() {}

    Spaces = require('spaces-client');

    Runner = require('./runner');

    logger = require('./logger');

    Session.activityCount = 0;

    Session.errorCount = 0;

    Session.appServerCount = 0;

    Session.jobServerCount = 0;

    Session.runningAvg = 0;

    Session.runningAvgByType = {};

    Session.startEmitter = function() {
      return Session.emit(0, 0);
    };

    Session.emit = function(lastActivityCount, lastErrorCount) {
      var activityCount, activityRate, callback, errorCount, errorRate;
      if (Spaces.socket) {
        activityCount = this.activityCount;
        errorCount = this.errorCount;
        activityRate = (this.activityCount - lastActivityCount) / CALLBACK_SECS;
        errorRate = (this.errorCount - lastErrorCount) / CALLBACK_SECS;
        Spaces.socket.emit("stats", {
          ts: new Date().getTime(),
          stats: {
            siteCount: this.totalSites,
            userCount: this.totalActiveUsers,
            itemCount: this.itemCount,
            activityCount: activityCount,
            activityRate: activityRate,
            errorCount: errorCount,
            errorRate: errorRate,
            appServerCount: this.appServerCount,
            jobServerCount: this.jobServerCount,
            runningAvg: this.runningAvg,
            runningAvgByType: this.runningAvgByType
          }
        });
      }
      callback = function() {
        return Session.emit(activityCount, errorCount);
      };
      return setTimeout(callback, CALLBACK_SECS * 1000);
    };

    Session.startEmitter();

    Session.totalSites = 0;

    Session.sites = {};

    Session.siteArray = [];

    Session.registerSite = function(site) {
      site.users = [];
      site.signupPeriod = 20000;
      site.currentUsers = 0;
      site.maxUsers = 50000;
      this.items[site.site_id] = {};
      this.siteArray.push(site.site_id);
      this.sites[site.site_id] = site;
      this.totalSites += 1;
      return site;
    };

    Session.siteCount = function() {
      return this.totalSites;
    };

    Session.getSite = function(siteId) {
      return this.sites[siteId];
    };

    Session.getRandomSite = function() {
      return this.sites[this.siteArray[Math.floor(Math.random() * this.siteArray.length)]];
    };

    Session.startPoller = function() {
      return Session.poll();
    };

    Session.poll = function() {
      var callback, site;
      if (site = Session.getRandomSite()) {
        Spaces.Pod.getServers(site, (function(appServerCount, jobServerCount) {
          Session.appServerCount = appServerCount;
          return Session.jobServerCount = jobServerCount;
        }));
      }
      callback = function() {
        return Session.poll();
      };
      return setTimeout(callback, 10000);
    };

    Session.startPoller();

    Session.totalActiveUsers = 0;

    Session.registerUser = function(siteId, user, sessionId) {
      var site;
      logger.debug("[%s][%s] Session.registerUser [%s] with session [%s]", siteId, user.id, user.email, sessionId);
      this.setUserSessionId(siteId, user.id, sessionId);
      this.totalActiveUsers += 1;
      site = this.getSite(siteId);
      site.currentUsers += 1;
      site.users.push(user.id);
      this.items[user.id] = {};
      if (user.email !== 'tech-support@moxiesoft.com') {
        this.registerPersonalDocLib(site, user.id);
      }
      return site;
    };

    Session.userCount = function() {
      return this.totalActiveUsers;
    };

    Session.userSessions = {};

    Session.setUserSessionId = function(siteId, userId, id) {
      if (!this.userSessions[userId]) {
        this.userSessions[userId] = {};
      }
      return this.userSessions[userId]["id"] = id;
    };

    Session.getUserSessionId = function(site, userId) {
      var session, sessionId;
      if (session = this.userSessions[userId]) {
        if (sessionId = session["id"]) {
          return sessionId;
        } else {
          return logger.error("[%s][%s] Session.getUserSessionId: Couldn't find session ID", site.site_id, userId);
        }
      } else {
        return logger.error("[%s][%s] Session.getUserSessionId: Couldn't find user session", site.site_id, userId);
      }
    };

    Session.itemCount = 0;

    Session.items = {};

    Session.addItem = function(site, userId, type, item) {
      logger.debug("[%s][%s] Session.addItem: Added a %s [%s]", site.site_id, userId, type, item);
      this.itemCount += 1;
      if (this.items[userId]) {
        if (!this.items[userId][type]) {
          this.items[userId][type] = [];
        }
        this.items[userId][type].push(item);
      } else {
        logger.error("[%s][%s] Session.addItem: user items not found", site.site_id, userId);
      }
      if (this.items[site.site_id]) {
        if (!this.items[site.site_id][type]) {
          this.items[site.site_id][type] = [];
        }
        return this.items[site.site_id][type].push(item);
      } else {
        return logger.error("[%s][%s] Session.addItem: site items not found", site.site_id, userId);
      }
    };

    Session.removeItem = function(site, userId, type, item) {
      logger.info("[%s][%s] Session.removeItem: Removed a %s [%s]", site.site_id, userId, type, item);
      return logger.warn("REMINDER: removeItem isn't implemented yet");
    };

    Session.getRandomUserItemIdOfType = function(site, userId, type) {
      var list;
      if (this.items[userId]) {
        if (list = this.items[userId][type]) {
          return list[Math.floor(Math.random() * list.length)];
        } else {
          return logger.error("[%s][%s] Session.getRandomUserItemIdOfType: user doesn't have a valid %s", site.site_id, userId, type);
        }
      } else {
        return logger.error("[%s][%s] Session.getRandomUserItemIdOfType: Couldn't find user session", site.site_id, userId);
      }
    };

    Session.getRandomSiteItemIdOfType = function(site, userId, type) {
      var list;
      if (this.items[site.site_id]) {
        if (list = this.items[site.site_id][type]) {
          return list[Math.floor(Math.random() * list.length)];
        } else {
          return logger.error("[%s][%s] Session.getRandomSiteItemIdOfType: site doesn't have a valid %s", site.site_id, userId, type);
        }
      } else {
        return logger.error("[%s][%s] Session.getRandomSiteItemIdOfType: Couldn't find site session", site.site_id, userId);
      }
    };

    Session.registerPersonalDocLib = function(site, userId) {
      var sessionId;
      sessionId = this.getUserSessionId(site, userId);
      return Spaces.Folder.getPersonalDocLibId(site, userId, sessionId, (function(folderId) {
        return Session.addItem(site, userId, 'folder', folderId);
      }));
    };

    Session.times = [];

    Session.runningAvgTotal = 0;

    Session.timesByType = [];

    Session.timesByTypeTotal = [];

    Session.profile = function(action, msecs) {
      var n;
      this.times.push(msecs);
      this.runningAvgTotal += msecs;
      if (this.times.length > 100) {
        n = this.times[0];
        this.times = this.times.slice(1);
        this.runningAvgTotal -= n;
      }
      this.runningAvg = this.runningAvgTotal / (1000 * this.times.length);
      if (action.method === 'show') {
        if (!this.timesByType[action.resource]) {
          this.timesByType[action.resource] = [];
          this.timesByTypeTotal[action.resource] = 0;
        }
        this.timesByType[action.resource].push(msecs);
        this.timesByTypeTotal[action.resource] += msecs;
        if (this.timesByType[action.resource].length > 10) {
          n = this.timesByType[action.resource][0];
          this.timesByType[action.resource] = this.timesByType[action.resource].slice(1);
          this.timesByTypeTotal[action.resource] -= n;
        }
        return this.runningAvgByType[action.resource] = this.timesByTypeTotal[action.resource] / (1000 * this.timesByType[action.resource].length);
      }
    };

    Session.addActivity = function(action, msecs) {
      this.activityCount += 1;
      if (msecs) {
        return this.profile(action, msecs);
      }
    };

    Session.addError = function(action, msecs) {
      this.errorCount += 1;
      if (msecs) {
        return this.profile(action, msecs);
      }
    };

    return Session;

  }).call(this);

  module.exports = exports = Session;

}).call(this);
