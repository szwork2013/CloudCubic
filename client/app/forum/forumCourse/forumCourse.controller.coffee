'use strict'

angular.module('budweiserApp').controller 'ForumCourseCtrl',
(
  $scope
  Restangular
  notify
  $state
  $q
  $rootScope
  $document
  $window
  $timeout
  CurrentUser
  $modal
  AllKeypoints
) ->
  $rootScope.additionalMenu = [
    {
      title: '主页'
      link: 'student.courseList'
      role: 'student'
    }
    {
      title: '主页'
      link: 'teacher.home'
      role: 'teacher'
    }
    {
      title: '课程主页<i class="fa fa-home"></i>'
      link: "student.courseDetail({courseId:'#{$state.params.courseId}'})"
      role: 'student'
    }
    {
      title: '课程主页<i class="fa fa-home"></i>'
      link: "teacher.courseDetail({courseId:'#{$state.params.courseId}'})"
      role: 'teacher'
    }
    {
      title: '讨论<i class="fa fa-comments-o"></i>'
      link: "forum.course({courseId:'#{$state.params.courseId}'})"
      role: 'student'
    }
    {
      title: '统计<i class="fa fa-bar-chart-o"></i>'
      link: "student.courseStats({courseId:'#{$state.params.courseId}'})"
      role: 'student'
    }
    {
      title: '统计<i class="fa fa-bar-chart-o"></i>'
      link: "teacher.courseStats({courseId:'#{$state.params.courseId}'})"
      role: 'teacher'
    }
  ]

  $scope.$on '$destroy', ()->
    $rootScope.additionalMenu = []

  if not $state.params.courseId
    return
  angular.extend $scope,
    loading: true

    course: null

    topics: null

    myTopic: null

    posting: false

    me: CurrentUser

    selectedTopic: undefined

    imagesToInsert: undefined

    loadCourse: ()->
      Restangular.one('courses',$state.params.courseId).get()
      .then (course)->
        $scope.keypoints = AllKeypoints.filter (x) -> x._id is course.categoryId
        $scope.course = course

    loadLectures: ()->
      Restangular.all('lectures').getList({courseId: $state.params.courseId})
      .then (lectures)->
        $scope.course.$lectures = lectures


    loadTopics: ()->
      Restangular.all('dis_topics').getList({courseId: $state.params.courseId})
      .then (topics)->
        # pull out the tags in content
        topics.forEach (topic)->
          topic.$tags = (topic.content.match /<div\s+class="tag\W.*?<\/div>/)?.join()
          topic.$heat = 1000 / (moment().diff(moment(topic.created),'hours') + 1)+ topic.repliesNum * 10 + topic.voteUpUsers.length * 10
        console.log(_.pluck topics, '$heat')
        $scope.topics = topics
        $scope.viewTopic(topics[0]) if topics[0]

    createTopic: ()->
      # validate
      $modal.open
        templateUrl: 'app/forum/discussionComposerPopup/discussionComposerPopup.html'
        controller: 'DiscussionComposerPopupCtrl'
        resolve:
          keypoints: -> $scope.keypoints
          course: -> $scope.course
          lectures: -> $scope.course.$lectures
          topics: -> $scope.topics
      .result.then (dis_topic)->
        $scope.topics.splice 0, 0, dis_topic

    viewTopic: (topic)->
      $scope.selectedTopic = undefined
      Restangular.one('dis_topics', topic._id).get()
      .then (topic)->
        $scope.selectedTopic = topic
        Restangular.all('dis_replies').getList({disTopicId: topic._id})
      .then (replies)->
        replies.forEach (reply)->
        $scope.selectedTopic.$replies = replies
        $document.scrollToElement(angular.element('.article'), 60, 200);

    clientHeight: undefined

  setclientHeight = ()->
    $scope.clientHeight =
      "min-height": $window.innerHeight

  setclientHeight()

  handle = angular.element($window).bind 'resize', setclientHeight

  $scope.$on '$destroy', ->
    angular.element($window).unbind 'resize', setclientHeight

  $q.all [
    $scope.loadCourse().then $scope.loadLectures
    $scope.loadTopics()
  ]
  .then ()->
    $scope.loading = false


