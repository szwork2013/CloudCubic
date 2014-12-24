'use strict'

Comment = _u.getModel 'comment'
AdapterUtils = _u.getUtils 'adapter'
CommentUtils = _u.getUtils 'comment'
WrapRequest = new (require '../../utils/WrapRequest')(Comment)

exports.index = (req, res, next) ->
  conditions = {}
  WrapRequest.wrapIndex req, res, next, conditions

exports.create = (req, res, next) ->
  user = req.user
  body = req.body
  data =
    content : body.content
    postBy  : user._id
    type    : body.type
    belongTo: body.belongTo
    tags    : body.tags

  Model = CommentUtils.getCommentRefByType body.type
  Q.all [
    Comment.createQ data
    Model.updateQ {_id: data.belongTo}, {$inc: {commentsNum: 1}}
  ]
  .then (result) ->
    comment = result[0]
    res.send comment
  .catch next
  .done()

pickedUpdatedKeys = ['content', 'tags']
exports.update = (req, res, next) ->
  conditions = _id: req.params.id, postBy: req.user._id
  WrapRequest.wrapUpdate req, res, next, conditions, pickedUpdatedKeys


exports.destroy = (req, res, next) ->
  conditions = _id: req.params.id, postBy: req.user._id
  WrapRequest.wrapDestroy req, res, next, conditions

exports.like = WrapRequest.wrapLike()
