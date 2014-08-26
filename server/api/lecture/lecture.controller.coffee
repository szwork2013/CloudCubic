
#
# * Using Rails-like standard naming convention for endpoints.
# * GET     /lecture              ->  index
# * POST    /lecture              ->  create
# * GET     /lecture/:id          ->  show
# * PUT     /lecture/:id          ->  update
# * DELETE  /lecture/:id          ->  destroy
# 

Lecture = _u.getModel "lecture"
Course = _u.getModel "course"
CourseUtils = _u.getUtils 'course'

exports.index = (req, res, next) ->
  courseId = req.query.courseId
  CourseUtils.getAuthedCourseById req.user, courseId
  .then (course) ->
    Lecture.findQ
      _id :
        $in : course.lectureAssembly
  .then (lectures) ->
    return res.json 200, lectures if lectures?
    return res.send 404
  , (err) ->
    next err

exports.show = (req, res, next) ->
  Lecture.findById req.params.id, (err, lecture) ->
    return handleError(res, err)  if err
    return res.send(404)  unless lecture
    courseId = lecture.courseId
    if req.user.role is "teacher"
      Course.findOne
        _id: courseId
        owners:
          $in: [req.user.id]
      , (err, course) ->
        return handleError(res, err)  if err
        return res.send(404)  unless course
        res.json 200, lecture

    else if req.user.role is "student"
      Course.findById(courseId).populate(
        path: "classes"
        match:
          students:
            $in: [req.user.id]
      ).exec (err, course) ->
        return handleError(res, err)  if err
        return res.send(404)  if not course or 0 is course.classes.length
        res.json 200, lecture

    else if req.user.role is "admin"
      res.json 200, lecture
    else
      res.send 404
    return


# TODO: add lectureID to classProcess's lectures automatically & keep the list order same as Course's lectureAssembly.
exports.create = (req, res) ->
  Course.findOne(
    _id: req.body.courseId
    owners:
      $in: [req.user.id]
  ).exec (err, course) ->
    return handleError(res, err)  if err
    return res.send(404)  unless course
    Lecture.create req.body, (err, lecture) ->
      return handleError(res, err)  if err
      course.lectureAssembly.push lecture._id
      course.save (err) ->
        return handleError(err)  if err # TODO: should use transactions to rollback..
        res.json 201, lecture


exports.update = (req, res) ->
  delete req.body._id  if req.body._id
  Lecture.findById req.params.id, (err, lecture) ->
    return handleError(err)  if err
    return res.send(404)  unless lecture
    Course.findOne(
      _id: lecture.courseId
      owners:
        $in: [req.user.id]
    ).exec (err, course) ->
      return handleError(res, err)  if err
      return res.send(404)  unless course
      updated = _.merge(lecture, req.body)
      updated.save (err) ->
        return handleError(err)  if err
        res.json 200, lecture

# TODO: delete from classe's lectureAssembly & classProgress's lecturesStatus
exports.destroy = (req, res) ->
  Lecture.findById req.params.id, (err, lecture) ->
    return handleError(res, err)  if err
    return res.send(404)  unless lecture
    Course.findOne(
      _id: lecture.courseId
      owners:
        $in: [req.user.id]
    ).exec (err, course) ->
      return handleError(res, err)  if err
      return res.send(404)  unless course
      lecture.remove (err) ->
        return handleError(res, err)  if err
        res.send 204


### copied from course.controller.coffee, need to implement all these logic in above methods

exports.showLectures = (req, res) ->
  Course.findById(req.params.id).populate("lectureAssembly", "_id name").exec (err, course) ->
    return handleError(res, err)  if err
    return res.send(404)  unless course
    res.json course.lectureAssembly


exports.showLecture = (req, res) ->
  Lecture.findById req.params.lectureId, (err, lecture) ->
    return handleError(res, err)  if err
    return res.send(404)  unless lecture
    courseId = lecture.courseId
    if req.user.role is "teacher"
      Course.findOne
        _id: courseId
        owners:
          $in: [req.user.id]
      , (err, course) ->
        return handleError(res, err)  if err
        return res.send(404)  unless course
        res.json 200, lecture

    else if req.user.role is "student"
      Course.findById(courseId).populate(
        path: "classes"
        match:
          students:
            $in: [req.user.id]
      ).exec (err, course) ->
        return handleError(res, err)  if err
        return res.send(404)  if not course or 0 is course.classes.length
        res.json 200, lecture

    else if req.user.role is "admin"
      res.json 200, lecture
    else
      res.send 404

#TODO: sync classProgress's lecturesStatus
exports.createLecture = (req, res) ->
  Course.findOne(
    _id: req.params.id
    owners:
      $in: [req.user.id]
  ).exec (err, course) ->
    return handleError(res, err)  if err
    return res.send(404)  unless course
    req.body.courseId = req.params.id
    Lecture.create req.body, (err, lecture) ->
      return handleError(res, err)  if err
      course.lectureAssembly.push lecture._id
      course.save (err) ->
        return handleError(err)  if err #TODO: should use transactions to rollback..
        res.json 201, lecture


exports.updateLecture = (req, res) ->
  delete req.body._id  if req.body._id
  Lecture.findById req.params.lectureId, (err, lecture) ->
    updated = undefined
    return handleError(err)  if err
    return res.send(404)  unless lecture
    Course.findOne(
      _id: lecture.courseId
      owners:
        $in: [req.user.id]
    ).exec (err, course) ->
      return handleError(res, err)  if err
      return res.send(404)  unless course
      updated = _.extend(lecture, req.body)
      updated.save (err) ->
        return handleError(err)  if err
        res.json 200, lecture


exports.destroyLecture = (req, res) ->
  Lecture.findById req.params.lectureId, (err, lecture) ->
    return handleError(res, err)  if err
    return res.send(404)  unless lecture
    Course.findOne(
      _id: lecture.courseId
      owners:
        $in: [req.user.id]
    ).exec (err, course) ->
      return handleError(res, err)  if err
      return res.send(404)  unless course
      #delete from Course's lectureAssembly list
      lecture.remove (err) ->
        return handleError(res, err)  if err
        _.remove course.lectureAssembly, new ObjectId(req.params.lectureId)
        course.markModified "lectureAssembly"
        course.save (err) ->
          return handleError(res, err)  if err
          res.send 204

###

handleError = (res, err) ->
  res.send 500, err
