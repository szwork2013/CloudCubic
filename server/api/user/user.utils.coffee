User = _u.getModel 'user'

class UserUtils
  check: (userInfo) ->
    User.findBy userInfo
    .then (user) ->
      if user?
        return Q.reject
          status : 400
          errCode : ErrCode.UsernameOrEmailInUsed
          errMsg : 'username或者email已被使用'


exports.UserUtils = UserUtils
