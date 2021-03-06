"use strict"

Question = _u.getModel "question"
Classe = _u.getModel 'classe'
QuizAnswer = _u.getModel 'quiz_answer'
SocketUtils = _u.getUtils 'socket'

WrapRequest = new (require '../../utils/WrapRequest')(Question)

################################################################
## 题库检索条件：
## 1. user.orgId && deleteFlag非true
## 2. 类别categoryId
## 3. 知识点列表keyPointIds
## 4. 关键字keyword，题目的标题和描述是否包含相应关键字
################################################################
exports.index = (req, res, next) ->
  user = req.user

  conditions = orgId: user.orgId, deleteFlag: $ne: true
  conditions.categoryId = req.query.categoryId if req.query.categoryId?

  if req.query.keyPointIds?
    try
      keyPointIds = JSON.parse req.query.keyPointIds
      conditions.keyPoints = {$in: keyPointIds} if keyPointIds.length > 0
    catch err
      logger.error err

  if req.query.keyword
    keyword = req.query.keyword
    #对可能出现的正则元字符进行转义
    regex = new RegExp(_u.escapeRegex(keyword), 'i')
    conditions.$or = [
      'body': regex
    ,
      'choices.text': regex
    ]

  options = limit: req.query.limit, from: req.query.from

  WrapRequest.wrapPageIndex req, res, next, conditions, options


exports.show = (req, res, next) ->
  conditions = {_id: req.params.id, orgId: user.orgId}
  WrapRequest.wrapShow req, res, next, conditions

exports.create = (req, res, next) ->
  data = req.body
  data.orgId = req.user.orgId
  delete data._id
  WrapRequest.wrapCreate req, res, next, data

exports.update = (req, res, next) ->
  questionId = req.params.id
  body = req.body
  delete body._id
  delete body.orgId

  Question.findByIdQ questionId
  .then (question) ->
    updated = _.extend question, body
#    updated.markModified 'content'
    do updated.saveQ
  .then (result) ->
    newClasse = result[0]
    res.send newClasse
  , next

exports.destroy = (req, res, next) ->
  questionId = req.params.id
  Question.removeQ
    _id: questionId
  .then () ->
    res.send 204
  , next

#找出指定班级中的所有学生，查看他们的quiz_answer记录，若没有，则新增
#然后将question和answer通过socket发送给每一个学生
#TODO: 这是一个http请求，只要在web端登录，就可以推送问题
#但socket只留给最近登录的那个终端，如果需要抢回socket，刷新当前页面即可
exports.pubQuiz = (req, res, next) ->
  user = req.user
  {questionId, classId, lectureId} = req.body

  tmpResult = {}
  Classe.findByIdQ classId
  .then (classe) ->
    tmpResult.classe = classe
    QuizAnswer.findQ
      lectureId: lectureId
      questionId: questionId
      userId: $in: tmpResult.classe.students
  .then (quizAnswers) ->
    tmpResult.quizAnswers = quizAnswers
    tmpResult.userAnswerMap = _.indexBy quizAnswers, 'userId'

    noAnswerStudentIds = _.filter tmpResult.classe.students, (studentId) ->
      return not tmpResult.userAnswerMap[studentId]?

    QuizAnswer.createNewAnswers noAnswerStudentIds, lectureId, questionId
  .then (newAnswers) ->
    return tmpResult.quizAnswers.concat newAnswers
  .then (allAnswers) ->
    tmpResult.allAnswers = allAnswers
    Question.findById questionId
      .populate 'keyPoints', 'name'
      .execQ()
  .then (question) ->
    tmpResult.question = question
    SocketUtils.sendQuizMsg(
      tmpResult.allAnswers
      tmpResult.question
      user._id
    )
  .then ->
    res.send tmpResult.allAnswers
  , next

exports.multiDelete = (req, res, next) ->
  ids = req.body.ids
  Question.updateQ
    orgId: req.user.orgId
    _id: $in: ids
  ,
    deleteFlag: true
  ,
    multi: true
  .then () ->
    res.send 204
  , next
