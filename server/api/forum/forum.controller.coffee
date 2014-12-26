'use strict'

Forum = _u.getModel 'forum'
WrapRequest = new (require '../../utils/WrapRequest')(Forum)

exports.index = (req, res, next) ->
  conditions = orgId: req.org?._id
  WrapRequest.wrapIndex req, res, next, conditions


exports.show = (req, res, next) ->
  conditions = _id: req.params.id, orgId: req.org?._id
  WrapRequest.wrapShow req, res, next, conditions


pickedKeys = ["name", "logo", "info", "categoryId"]
exports.create = (req, res, next) ->
    data = _.pick req.body, pickedKeys
    data.postBy = req.user._id
    data.orgId = req.user.orgId
    logger.info "create data:", data

    Forum.createQ data
    .then (newDoc) ->
      res.send 201, newDoc
    .catch next
    .done()

pickedUpdatedKeys = ["name", "logo", "info", "categoryId"]
exports.update = (req, res, next) ->
  _id  = req.params.id
  user = req.user

  # 拣选出允许更新的字段
  data = _.pick req.body, pickedUpdatedKeys

  Forum.findOneQ {_id : _id, postBy : user._id}
  .then (doc) ->
    updated = _.extend doc, data
    do updated.saveQ
  .then (result) ->
    res.send result[0]
  .catch next
  .done()

exports.destroy = (req, res, next) ->
  _id = req.params.id
  userId = req.user.id
  Forum.updateQ {_id: _id, postBy: userId}, {deleteFlag: true}
  .then () ->
    res.send 204
  .catch next
  .done()
