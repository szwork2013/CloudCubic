log4js = require 'log4js'
path = require 'path'
stackTrace = require 'stack-trace'

getCallerFile = ->
  frame = stackTrace.get()[8]
  file  = path.relative process.cwd(), frame.getFileName()
  dir   = path.dirname file
  ext   = path.extname file
  base  = path.basename file, ext
  line  = frame.getLineNumber()
  "#{dir}/#{base}#{ext}##{line}"

logCategory = "[#{config.appName.toUpperCase()}]"
log4js.configure
  appenders: [
    type        : 'console'
    layout      :
      type      : 'pattern'
      pattern   : "%d{ISO8601} %x{filename} %[%-5p%] - %c %m"
      tokens    :
        filename: getCallerFile
  ,
    type        : 'dateFile'
    filename    :  "/data/log/#{config.appName}.log"
    pattern     : "-yyyy-MM"
    alwaysIncludePattern: true
    layout      :
      type      : 'pattern'
      pattern   : "%d{ISO8601} %x{filename} %-5p - %c %m"
      tokens    :
        filename: getCallerFile
    category    : logCategory
  ,
    type        : 'dateFile'
    filename    : "/data/log/#{config.appName}.data.log"
    pattern     : "-yyyy-MM-dd"
    alwaysIncludePattern: true
    layout      :
      type      : 'pattern'
      pattern   : "%m"
    category    : 'DATA'
  ,
    type        : 'dateFile'
    filename    : "/data/log/#{config.appName}.client.log"
    pattern     : "-yyyy-MM-dd"
    alwaysIncludePattern: true
    layout      :
      type      : 'pattern'
      pattern   : "%m"
    category    : 'CLIENT'
  ]

logger = log4js.getLogger logCategory
logger.setLevel config.logger.level

write = () ->
  Array::unshift.call arguments, new Date().toISOString()
  @info Array::join.call arguments, '\t'

loggerD = log4js.getLogger 'DATA'
loggerD.setLevel 'INFO'
loggerD.write = write

loggerC = log4js.getLogger 'CLIENT'
loggerC.setLevel 'INFO'
loggerC.write = write

exports.logger = logger
exports.loggerD = loggerD
exports.loggerC = loggerC
