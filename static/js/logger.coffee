winston = require("winston")

myCustomLevels = {
  levels: {
    debug: 0,
    info: 1,
    warn: 2,
    error: 3
  },
  colors: {
    debug: 'white',
    info: 'green',
    warn: 'orange',
    error: 'red'
  }
}
logger = new (winston.Logger)( {
  transports: [
    new winston.transports.Console({
      level: 'debug',
      colorize: true
    })
  ]
})

logger.setLevels(myCustomLevels.levels)
winston.addColors(myCustomLevels.colors)

module.exports = exports = logger