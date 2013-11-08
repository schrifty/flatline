winston = require("winston")

module.exports = exports = new (winston.Logger)( {
  transports: [
    new winston.transports.Console({ level: 'debug' })
  ]
  exceptionHandlers: [
    new winston.transports.Console()
  ]
})
