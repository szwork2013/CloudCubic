'use strict'

User = _u.getModel "user"
Classe = _u.getModel 'classe'
AssetUtils = _u.getUtils 'asset'
passport = require 'passport'
config = require '../../config/environment'
jwt = require 'jsonwebtoken'
qiniu = require 'qiniu'
path = require 'path'
_ = require 'lodash'
fs = require 'fs'
request = require 'request'
xlsx = require 'node-xlsx'
mongoose = require 'mongoose'
Schema = mongoose.Schema
ObjectId = Schema.ObjectId
Organization = _u.getModel "organization"
UserUtils = _u.getUtils 'user'

qiniu.conf.ACCESS_KEY = config.qiniu.access_key
qiniu.conf.SECRET_KEY = config.qiniu.secret_key
qiniuDomain           = config.assetsConfig[config.assetHost.uploadFileType].domain
uploadImageType       = config.assetHost.uploadImageType
###
  Get list of users
  restriction: 'admin'
###
exports.index = (req, res, next) ->
  condition =
    orgId : req.user.orgId
  condition.role = req.query.role if req.query.role?

  User.findQ condition, '-salt -hashedPassword'
  .then (users) ->
    res.send users
  , next

###
  Creates a new user
###
exports.create = (req, res, next) ->
  body = req.body
  body.provider = 'local'

  delete body._id
  body.orgId = req.user.orgId

  User.createQ body
  .then (user) ->
    token = jwt.sign
      _id: user._id,
      config.secrets.session,
      expiresInMinutes: 60*5
    res.json
      _id: user._id
      token: token
  , next

###
  Get a single user
###
exports.show = (req, res, next) ->

  userId = req.params.id

  User.findByIdQ userId
  .then (user) ->
    res.send user.profile
  , next


exports.check = (req, res, next) ->
  UserUtils.check req.query.username
  .then () ->
    res.send 200
  .catch next
  .done()

###
  Get a single user by email
###
exports.showByEmail = (req, res, next) ->
  User.findOneQ
    email : req.params.email
  .then (user) ->
    return res.send 404 if not user?
    res.send user.profile
  , next

###
  Deletes a user
  restriction: 'admin'
###
exports.destroy = (req, res, next) ->
  userId = req.params.id
  userObj = undefined
  User.removeQ
    orgId: req.user.orgId
    _id: userId
  .then (user) ->
    userObj = user
    Classe.findOneQ
      students : userId
  .then (classe) ->
    if classe?
      classe.updateQ
        $pull :
          students : userId
  .then (classe) ->
    res.send userObj
  , next

exports.multiDelete = (req, res, next) ->
  ids = req.body.ids
  User.removeQ
    orgId: req.user.orgId
    _id: $in: ids
  .then () ->
    res.send 204
  , next

###
  Change a users password
###
exports.changePassword = (req, res, next) ->
  userId = req.user._id
  oldPass = String req.body.oldPassword
  newPass = String req.body.newPassword

  User.findByIdQ userId
  .then (user) ->
    if user.authenticate oldPass
      user.password = newPass
      user.save (err) ->
        return next err if err
        res.send 200
    else
      res.send 403
  , next


###
  Get my info
###
exports.me = (req, res, next) ->
  userId = req.user.id
  User.findOne
    _id: userId
    '-salt -hashedPassword'
  .populate 'orgId'
  .execQ()
  .then (user) -> # donnot ever give out the password or salt
    return res.send 401 if not user?
    res.send user
  , next

###
  Update user
###
exports.update = (req, res, next) ->
  body = req.body
  body = _.omit body, ['_id', 'password', 'orgId', 'username']

  User.findByIdQ req.params.id
  .then (user) ->
    return res.send 404 if not user?

    updated = _.merge user , req.body
    updated.saveQ()
  .then (result) ->
    res.send result[0]
  , next


updateClasseStudents = (classeId, studentList) ->
  Classe.findByIdQ classeId
  .then (classe) ->
    return Q.reject 'No classe found for give ID' if not classe?

    logger.info 'Found classe with id ' + classe.id
    classe.students = _.union classe.students, studentList
    classe.markModified 'students'
    classe.saveQ()

###
  Bulk import users from excel sheet uploaded by client
###
exports.bulkImport = (req, res, next) ->
  orgId = req.user.orgId
  resourceKey = decodeURI(req.body.key.replace(/.*images\/\d+\//, ''))
  type = req.body.type
  classeId = req.body.classeId

  console.log 'start importing...', resourceKey

  # do some sanity check
  if !type? or !orgId? or (type is 'student' and !classeId?)
    return res.send 400, '参数不正确'

  destFile = config.local.tempDir + path.sep + 'user_list.xlsx'
  stream = fs.createWriteStream destFile
  streamOnQ = Q.nbind stream.on, stream
  streamCloseQ = Q.nbind stream.close, stream

  importReport =
    total : 0
    success : []
    failure : []

  importedUsers = []
  
  orgUniqueName = ''
  
  Organization.findByIdQ orgId
  .then (org) ->
    orgUniqueName = org.uniqueName
    AssetUtils.getAssetFromQiniu(resourceKey, uploadImageType)
  .then (downloadUrl) ->
    request.get(downloadUrl).pipe stream
    streamOnQ 'finish'
  .then ->
    streamCloseQ()
  .then ->
    console.log 'Start parsing file to ', destFile
    sheets = xlsx.parse destFile
    userList = sheets[0].data

    if not userList
      logger.error 'Failed to parse user list file or empty file'
      Q.reject '请导入包含用户信息的表格'

    savePromises = _.map userList, (userItem) ->
      name = userItem[0]
      email = userItem[1]
      console.log 'userItem', name, email
      newUser = new User.model
        role   :  type
        name : name
        email : email
        username: email + '_' + orgUniqueName
        password : email #initial password is the same as email
        orgId : orgId
      newUser.saveQ()

    Q.allSettled(savePromises)
  .then (results) ->
    _.forEach results, (result) ->
      if result.state is 'fulfilled'
        user = result.value[0]
        console.log 'Imported user ' + user.name
        importReport.success.push user.name
        importedUsers.push user.id
      else
        console.error 'Failed to import user', result.reason
        importReport.failure.push result.reason

    if type is 'student'
      updateClasseStudents classeId, importedUsers
  .then ->    
    res.send importReport
      
  .catch (err) ->
    logger.error 'import users error: ' + err
    fs.unlink destFile
    next err


exports.forget = (req, res, next) ->
  if not req.body.email? then return res.send 400

  crypto = require 'crypto'
  cryptoQ = Q.nbind(crypto.randomBytes)
  token = null

  cryptoQ(21)
  .then (buf) ->
    token = buf.toString 'hex'
    conditions =
      email: req.body.email.toLowerCase()
    fieldsToSet =
      resetPasswordToken: token,
      resetPasswordExpires: Date.now() + 10000000
    User.findOneAndUpdateQ conditions, fieldsToSet
  .then (user) ->
    sendPwdResetMail = require('../../common/mail').sendPwdResetMail
    resetLink = req.protocol+'://'+req.headers.host+'/accounts/resetpassword?email='+user.email+'&token='+token
    sendPwdResetMail user.name, user.email, resetLink
  .done () ->
    res.send 200
  , next


exports.reset = (req, res, next) ->
  if not req.body.password? then return res.send 400

  User.findOneQ
    email: req.query.email.toLowerCase()
    resetPasswordToken: req.query.token
    resetPasswordExpires:
      $gt: Date.now()
  .then (user) ->
    return res.send 404 if not user?
    user.password = req.body.password
    user.saveQ()
  .then (saved) ->
    res.send 200
  , next

###
 Authentication callback
###
exports.authCallback = (req, res, next) ->
  res.redirect '/'
