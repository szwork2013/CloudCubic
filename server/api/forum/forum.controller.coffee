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

    WrapRequest.wrapCreate req, res, next, data


pickedUpdatedKeys = ["name", "logo", "info", "categoryId"]
exports.update = (req, res, next) ->
  conditions = {_id : req.params.id, postBy : req.user._id}
  WrapRequest.wrapUpdate req, res, next, conditions, pickedUpdatedKeys


exports.destroy = (req, res, next) ->
  conditions = {_id : req.params.id, postBy : req.user._id}
  WrapRequest.wrapDestroy req, res, next, conditions
