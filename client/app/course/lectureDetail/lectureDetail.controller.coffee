'use strict'

angular.module('budweiserApp').directive 'ngRightClick', ($parse) ->
  link: (scope, element, attrs) ->
    fn = $parse(attrs.ngRightClick)
    element.bind 'contextmenu', (event) ->
      scope.$apply () ->
        event.preventDefault()
        fn scope, {$event:event}

.controller 'LectureDetailCtrl' , (
  $sce
  Auth
  $scope
  $state
  notify
  $timeout
  $document
  Restangular
  $localStorage
  $rootScope
  $q
  $http
) ->

  # track the usages of lecture
  console.remote 'views', 'lectures', {courseId:$state.params.courseId,lectureId:$state.params.lectureId}

  angular.extend $scope,
    getCurrentUser: Auth.getCurrentUser
    lecture: null
    selectedFile: null

    viewState:
      isVideo: true
      videos: null
      
      # Should not set to ```false```, once it is set to ```true```,
      # because ```ng-if="false"``` will destroy the controller and view
      discussPanelnitialized: false
      notesPanelnitialized: false

    $stateParams: $state.params

    switchFile: (file) ->
      $scope.selectedFile = file

    getViewerHeight: ->
      if $scope.selectedFile
        $('#lecture-file-content').width() * $scope.selectedFile.fileHeight / $scope.selectedFile.fileWidth
      else
        return 300

    seek: (timestamp)->
      $scope.viewState.isVideo = true
      if $scope.mediaPlayerAPI
        $scope.mediaPlayerAPI?.seekTime timestamp if timestamp?

    currentTime: 0

    isKeypointActive: (keypoint)->
      $scope.currentTime >= keypoint.timestamp and ($scope.currentTime < findNextStamp(keypoint)?.timestamp or not findNextStamp(keypoint))

    onUpdateTime: (now,total)->
      $scope.currentTime = now
      # store current time in local storage
      # localStorage.:userId.lectures.:lectureId.videoPlayTime
      $localStorage[$scope.getCurrentUser()._id] ?= {}
      $localStorage[$scope.getCurrentUser()._id]['lectures'] ?= {}
      lectureState = $localStorage[$scope.getCurrentUser()._id]['lectures'][$state.params.lectureId] ?= {}
      lectureState.videoPlayTime = $scope.currentTime

    mediaPlayerAPI: undefined

    onVideoError: undefined

    onPlayerReady: (playerAPI) ->
      if playerAPI.isReady
        $scope.mediaPlayerAPI = playerAPI
        timestamp = $localStorage[$scope.getCurrentUser()._id]?['lectures']?[$state.params.lectureId]?.videoPlayTime
        if timestamp
          playerAPI.seekTime timestamp
        $scope.onVideoError = (err)->
          console.remote? 'error', 'onVideoError', err

    toggleDiscussionPanel: ()->
      if !@viewState.discussPanelnitialized
        @viewState.discussPanelnitialized = true
        console.remote 'views', 'lectures-comments', {courseId:$state.params.courseId,lectureId:$state.params.lectureId}
        $scope.commentsLoading = true
        $timeout ->
          $scope.commentsLoading = false
          $scope.viewState.showDiscussion = true
        , 1000
      else
        @viewState.showDiscussion = !@viewState.showDiscussion

    toggleNotesPanel: ()->
      if !@viewState.notesPanelnitialized
        @viewState.notesPanelnitialized = true
        console.remote 'views', 'lectures-notes', {courseId:$state.params.courseId,lectureId:$state.params.lectureId}
        $scope.noteLoading = true
        $timeout ->
          $scope.noteLoading = false
          $scope.viewState.showNotes = true
        , 1000
      else
        @viewState.showNotes = !@viewState.showNotes

    startLiveStream: () ->
      lssHandle.startPlay()
      
    stopLiveStream: () ->
      lssHandle.stopPlayer()
      lssHandle.closeConnect()
      
  $scope.$watch 'viewState', (value)->
    if $scope.viewState.showDiscussion or $scope.viewState.showNotes
      angular.element('body').addClass 'sider-open'
    else
      angular.element('body').removeClass 'sider-open'
      
    if !value.isVideo
      user = Auth.getCurrentUser()
      console.log 'user', user
      console.log 'viewState', $scope.viewState.isVideo
      if user.role is 'student'
        console.log 'open live stream window...'
        aodianPlayer(
          container: 'live-stream-window'
          rtmpUrl:'rtmp://1093.lssplay.aodianyun.com/cloud3edu/stream'
          player:
            name:'lssplayer'
            width: '360'
            height: '240'
            autostart: false
            bufferlength: '3'
            stretching: '1'
            controlbardisplay: 'enable'
        )
  , true

  findNextStamp = (keypoint)->
    ($scope.lecture.keyPoints.filter (item)->
      item.timestamp > keypoint.timestamp
    .sort (a,b)->
      a.timestamp >= b.timestamp
    )?[0]

  # TODO: remove this line. Fix in videogular
  $scope.$on '$destroy', ()->

    $scope.onVideoError = undefined
    # clear video
    angular.element('video').attr 'src', ''

    #clear silder
    angular.element('body').removeClass 'sider-open'

  loadLecture = ()->
    lectureQ = Restangular
    .one('lectures', $state.params.lectureId)
    .get(classeId: $state.params.classeId)
    .then (lecture)->
      $scope.lecture = lecture
      $scope.viewState.isVideo = lecture.media or lecture.externalMedia or !lecture.files
      if lecture.media
        $scope.viewState.videos = [
          src: $sce.trustAsResourceUrl(lecture.media)
          type: 'video/mp4'
        ]
      if lecture.externalMedia
        lecture.$externalMedia = $sce.trustAsHtml lecture.externalMedia
      lecture
    $q.all [
      lectureQ
      $scope.classeQ
    ]
    .then (result)->
      enrolled = $scope.classe.students.indexOf($scope.getCurrentUser()?._id)
      if (enrolled == -1) && (($scope.classe.price == 0) || ($scope.lecture.isFreeTry == true))
        $scope.lecture.$isFreeTryOnly = true

  postActivity = (user)->
    # If student stay over 5 seconds. Send view lecture event.
    handleViewEvent = $timeout ->
      if user.role == 'student'
        Restangular.all('activities').post
          eventType: Const.Student.ViewLecture
          data:
            lectureId : $scope.lecture._id
            courseId  : $scope.course._id
            classeId  : $scope.classe._id
    , 5000
    $scope.$on '$destroy', ()->
      $timeout.cancel handleViewEvent

  # scroll to content-view after document ready
  $document.ready ->
    #$document.scrollToElement(ele, 60, 2000)
    $document.scrollTo(0, 80, 2000)

  $scope.$watch Auth.getCurrentUser, (user)->
    loadLecture()
    postActivity(user)

  if $state.current.name is 'course.lecture.comments'
    $scope.toggleDiscussionPanel()
    
