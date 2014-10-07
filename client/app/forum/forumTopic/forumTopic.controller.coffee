'use strict'

angular.module('budweiserApp').controller 'ForumTopicCtrl',
(
  $q
  $scope
  $state
  Navbar
  Courses
  CurrentUser
  Restangular
) ->

  if not $state.params.courseId or not $state.params.topicId
    return

  course = _.find Courses, _id:$state.params.courseId
  $scope.$on '$destroy', Navbar.resetTitle
  Navbar.setTitle course.name,
    if CurrentUser?.role == 'teacher'
      "teacher.course({courseId:'#{$state.params.courseId}'})"
    else
      "student.courseDetail({courseId:'#{$state.params.courseId}'})"

  angular.extend $scope,
    loading: true
    topic: null
    me: CurrentUser
    stateParams: $state.params

    loadTopic: ()->
      Restangular.one('dis_topics', $state.params.topicId).get()
      .then (topic)->
        $scope.topic = topic
        Restangular.all('dis_replies').getList({disTopicId: $state.params.topicId})
      .then (replies)->
        replies.forEach (reply)->
        $scope.topic.$replies = replies

    recommendedTopics: undefined

    loadRecommendedTopics: ()->
      Restangular.all('dis_topics').getList(courseId: $state.params.courseId)
      .then (dis_topics)->
        $scope.recommendedTopics = dis_topics.slice 0,3

  $q.all [
    $scope.loadTopic()
    $scope.loadRecommendedTopics()
  ]
  .then ()->
    $scope.loading = false
