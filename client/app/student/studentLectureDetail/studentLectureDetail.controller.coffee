'use strict'

angular.module('budweiserApp').directive 'ngRightClick', ($parse) ->
  link: (scope, element, attrs) ->
    fn = $parse(attrs.ngRightClick)
    element.bind 'contextmenu', (event) ->
      scope.$apply () ->
        event.preventDefault()
        fn scope, {$event:event}

.controller 'StudentLectureDetailCtrl'
, (
  $scope
  $state
  Restangular
  Auth,
  $http
  $upload
  $location
  notify
  fileUtils
  $tools
  $rootScope
  CurrentUser
  $timeout
) ->

  loadLecture = ()->
    if $state.params.lectureId
      Restangular.one('lectures',$state.params.lectureId).get()
      .then (lecture)->
        $scope.lecture = lecture
        $scope.viewState.isVideo = lecture.media or !lecture.slides
        # If student stay over 5 seconds. Send view lecture event.
        handleViewEvent = $timeout ->
          console.log 'view'
          Restangular.all('activities').post
            eventType: Const.Student.ViewLecture
            data:
              lectureId: $scope.lecture._id
              courseId: $scope.course._id
        , 5000
        $scope.$on '$destroy', ()->
          $timeout.cancel handleViewEvent
        $scope.lecture

  loadCourse = ()->
    Restangular.one('courses',$state.params.courseId).get()
      .then (course)->
        $scope.course = course

  angular.extend $scope,
    lecture: null

    course: null

    me: CurrentUser

    viewState:
      isVideo: true
      # Should not set to ```false```, once it is set to ```true```,
      # because ```ng-if="false"``` will destroy the controller and view
      discussPanelnitialized: false

    $stateParams: $state.params

    saveLecture: (lecture,form)->
      if form.$valid
        if not lecture._id
          #post
          $scope.all('lectures').post lecture,
            courseId: $state.params.courseId
          .then (data)->
            notify
              message:'课时已保存'
              template:'components/alert/success.html'
            $state.go 'teacher.lectureDetail',
              courseId: $state.params.courseId
              lectureId: data._id
        else
          #put
          lecture.put()

    seek: (timestamp)->
      $scope.viewState.isVideo = true
      if $scope.mediaPlayerAPI
        $scope.mediaPlayerAPI?.seekTime timestamp if timestamp?

    currentTime: 0

    isKeypointActive: (keypoint)->
      $scope.currentTime >= keypoint.timestamp and ($scope.currentTime < findNextStamp(keypoint)?.timestamp or not findNextStamp(keypoint))

    onUpdateTime: (now,total)->
      $scope.currentTime = now

    patchLecture: ()->
      if not lecture._id
        #post
        Restangular.all('lectures').post(lecture)
        .then (data)->
          notify({message:'课时已保存',template:'components/alert/success.html'})
          $state.go('editLectureDetail',{lectureId:data._id})
      else
        #put
        patch = {}
        patch[field] = lecture[field]
        lecture.patch(patch)
        .then (data)->
          angular.extend $scope.lecture, data
          notify({message:'课时已保存',template:'components/alert/success.html'})

    mediaPlayerAPI: undefined

    onPlayerReady: (playerAPI) ->
      $scope.mediaPlayerAPI = playerAPI
      seekHashTimestamp()

    toggleDiscussionPanel: ()->
      @viewState.discussPanelnitialized = true
      @viewState.showDiscussion = !@viewState.showDiscussion

    disableDownload: ()->
      console.log 'you are not allowed to download this resource'

  seekHashTimestamp = ->
    total = $tools.timeStrings2Seconds $location.hash()
    $scope.mediaPlayerAPI?.seekTime total if total?

  findNextStamp = (keypoint)->
    ($scope.lecture.keyPoints.filter (item)->
      item.timestamp > keypoint.timestamp
    .sort (a,b)->
      a.timestamp >= b.timestamp
    )?[0]

  loadCourse()

  loadLecture()
