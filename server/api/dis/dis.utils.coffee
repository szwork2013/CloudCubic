BaseUtils = require('../../common/BaseUtils')

SocketUtils = _u.getUtils 'socket'
NoticeUtils = _u.getUtils 'notice'
DeviceUtils = _u.getUtils 'device'

class DisUtils extends BaseUtils
  classname: 'DisUtils'

  vote: (DisModel, disId, userId) ->
    type = DisModel.classname[-5..] #Reply or Topic
    tmpResult = {}
    DisModel.findByIdQ disId
    .then (dis) ->
      tmpResult.dis = dis
      if dis.likeUsers.indexOf(userId) > -1
        dis.likeUsers.pull userId
      else
        dis.likeUsers.addToSet userId
        if dis.postBy.toString() isnt userId.toString()
          NoticeUtils["add#{type}VoteUpNotice"](
            dis.postBy
            userId
            dis._id
          ).then (notice) ->
            SocketUtils.sendNotices notice
            DeviceUtils.pushToUser user._id, notice

      do dis.saveQ
    .then (result) ->
      tmpResult.newDis = result[0]
      return tmpResult.newDis

exports.DisUtils = DisUtils
