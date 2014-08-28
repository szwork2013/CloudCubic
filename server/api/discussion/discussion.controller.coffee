###
 * Using Rails-like standard naming convention for endpoints.
 * GET     /discussions              ->  index
 * POST    /discussions              ->  create
 * GET     /discussions/:id          ->  show
 * PUT     /discussions/:id          ->  update
 * DELETE  /discussions/:id          ->  destroy
 ###

'use strict'

Discussion = _u.getModel 'discussion'
CourseUtils = _u.getUtils 'course'

# Get list of discussions
exports.index = (req, res, next) ->
  courseId = req.query.courseId
  user = req.user
  from = ~~req.query.from #from参数转为整数

  console.log from
  console.log req.query

  CourseUtils.getAuthedCourseById user, courseId
  .then (course) ->
    if not course?
      return res.send 403

    Discussion.find
      courseId: course._id
    .populate 'postBy', '_id name avatar'
    .sort created: -1
    .limit Const.PageSize.Discussion
    .skip from
    .execQ()
  .then (discussions) ->
    res.send discussions
  , (err) ->
    next err

# Get a single discussion
exports.show = (req, res) ->
  getAuthedCourseById req.user.id, req.params.courseId, (err, course) ->
    if err
      return handleError res, err
    if not course?
      return res.send 403

    Discussion.findById req.params.id,  (err, discussion) ->
      return handleError res, err if err
      return res.send 404 if not discussion?
      res.json 200, discussion


# Creates a new discussion in the DB.
exports.create = (req, res) ->
  getAuthedCourseById req.user.id, req.params.courseId, (err, course) ->
    return handleError res, err if err
    return res.send 403 if not course?

    #TODO: why do this?
    # has permission to add a comment
    delete req.body.voteUpUsers if req.body.voteUpUsers

    req.body.userId = req.user.id
    req.body.courseId = req.params.courseId
    Discussion.create req.body, (err, discussion) ->
      return handleError(res, err) if err
      discWithUserInfo = withUserInfo(discussion.toObject(), req.user)
      res.json 201, discWithUserInfo


# Updates an existing discussion in the DB.
exports.update = (req, res) ->
  if req.body._id
    delete req.body._id
  if req.body.responseTo
    delete req.body.responseTo
  if req.body.voteUpUsers
    delete req.body.voteUpUsers

  Discussion.findOne
    _id : req.params.id
    userId : req.user.id
  , (err, discussion) ->
    return handleError err if err
    return res.send 404 if not discussion?

    updated = _.merge discussion, req.body

    updated.save (err) ->
      return handleError(err) if err
      res.json 200, discussion


# Deletes a discussion from the DB.
exports.destroy = (req, res) ->
  Discussion.findOne
    _id : req.params.id
    userId : req.user.id
  , (err, discussion) ->
    return handleError(res, err) if err
    return res.send 404 if not discussion?
    discussion.remove (err) ->
      return handleError res, err if err
      res.send 204


# call twice can cancel out the vote
exports.vote = (req, res) ->
  courseId = req.params.courseId
  userId = req.user.id
  getAuthedCourseById userId, courseId, (err, course) ->
    return handleError res, err if err
    return res.send 403 if not course?

    Discussion.findById req.params.id, (err, disc) ->
      return handleError res, err if err
      return res.send 403 if not disc?

      if req.body.vote is '1'
        # vote
        upIdx = disc.voteUpUsers.indexOf userId
        if upIdx is -1
          disc.voteUpUsers.push userId
          downIdx = disc.voteDownUsers.indexOf userId
          if downIdx isnt -1
            disc.voteDownUsers.splice downIdx,1
            disc.markModified 'voteDownUsers'
          # undo vote
        else
          disc.voteUpUsers.splice upIdx,1
        disc.markModified 'voteUpUsers'
        disc.save()
      else if req.body.vote is '-1'
        downIdx = disc.voteDownUsers.indexOf userId
        if downIdx is -1
          disc.voteDownUsers.push userId
          upIdx = disc.voteUpUsers.indexOf userId
          if upIdx isnt -1
            disc.voteUpUsers.splice upIdx, 1
            disc.markModified 'voteUpUsers'
        else
          disc.voteDownUsers.splice downIdx,1
        disc.markModified 'voteDownUsers'
        disc.save()
      res.json 200, disc

withUserInfo = (disc, user) ->
  delete disc.userId
  disc.user =
    _id: user._id
    avatar: user.avatar
    name: user.name
  disc
