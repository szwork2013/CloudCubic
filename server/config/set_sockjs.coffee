'use strict'

#routes = require('../api/socket/').routes

SocketUtils = _u.getUtils 'socket'

exports.init = (sockjs_server) ->
  sockjs_server.on 'connection', (conn) ->
    conn.on 'data', (data) ->
      msg = JSON.parse data
      SocketUtils.verify msg.token
      .then (user) ->
        if global.socketMap[user._id]?
          global.socketMap[user._id].beatAt = _u.time()
        else
          global.socketMap[user._id] = beatAt: _u.time(), ws: conn

#        routes[msg.type] user, msg.payload #if we need more, uncomment this line
      , (err) ->
        logger.error err
        conn.write SocketUtils.buildErrMsg err
        do conn.close

    conn.on 'close', () ->
      logger.info 'some socket is closed'
      for userId, current of global.socketMap
        if current.ws is conn
          current = null
          delete global.socketMap[userId]
          logger.info "userId: #{userId}, websocket closed"


HeartBeatTime = 10 * 60 #seconds
#HeartBeatTime = 5 #seconds, for test
setInterval () ->
  logger.warn 'check connection: starting'
  now = do _u.time
  for userId, current of global.socketMap
    logger.info "check userId: #{userId}"
    if now - current.beatAt > HeartBeatTime
      logger.info "userId: #{userId}, websocket is not alive"
      do current.ws.close
      current = null
      delete global.socketMap[userId]

  logger.warn 'check connection: finished'
, HeartBeatTime * 1000
