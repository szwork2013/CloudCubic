'use strict'

angular.module('budweiserApp').controller 'StudentCourseDetailCtrl', (
  $q
  Auth
  $scope
  $state
  Navbar
  Courses
  Category
  $rootScope
  Restangular
) ->

  course = _.find Courses, _id:$state.params.courseId

  Navbar.setTitle course.name, "student.courseDetail({courseId:'#{$state.params.courseId}'})"
  $scope.$on '$destroy', Navbar.resetTitle

  Category.find course.categoryId
  .then (category) ->
    course.$category = category

  angular.extend $scope,
    itemsPerPage: 10
    currentPage: 1
    course: course

    loadLectures: ->
      if !$state.params.courseId then return
      Restangular.all('lectures').getList({courseId: $state.params.courseId})
      .then (lectures)->
        console.log 'loadLectures', lectures
        $scope.course.$lectures = lectures
        $scope.course.$lectures

    loadProgress: ->
      $scope.viewedLectureIndex = 1
      if !$state.params.courseId or !Auth.isLoggedIn() then return
      Restangular.all('progresses').getList({courseId: $state.params.courseId})
      .then (progress)->
        progress?.forEach (lectureId)->
          viewedLecture = _.find $scope.course.$lectures, _id: lectureId
          viewedLecture?.$viewed = true
          $scope.viewedLectureIndex = $scope.course.$lectures.indexOf(viewedLecture) + 1 if $scope.viewedLectureIndex < $scope.course.$lectures.indexOf(viewedLecture) + 1

    gotoLecture: ()->
      if !$scope.course.$lectures?.length
        return
      viewedLectures = $scope.course.$lectures.filter (x)->
        x.$viewed
      if viewedLectures and viewedLectures.length > 0
        # GOTO that course
        # TODO: last viewed should not be the last viewed item :(
        lastViewed = viewedLectures[viewedLectures.length - 1]
        $state.go 'student.lectureDetail',
          courseId: $state.params.courseId
          lectureId: lastViewed._id

      else
        # Start from first lecture
        $state.go 'student.lectureDetail',
          courseId: $state.params.courseId
          lectureId: $scope.course.$lectures[0]._id

    addToCart: (classe)->
      Restangular.all('carts/add').post classes: [classe._id]
      .then (result)->
        $rootScope.$broadcast 'addedToCart', result

    makeOrder: (classe)->
      Restangular.all('orders').post classes: [classe._id]
      .then (order)->
        $state.go 'order', orderId: order._id

    enrollFreeClass: (classe)->
      Restangular.all('classes').one(classe._id, 'enroll').post()
      .then ->
        console.log 'enrolled!'
        #TODO: redirect to course page

  Restangular.all('classes').getList(courseId: $state.params.courseId)
  .then (classes)->
    $scope.classes = classes

  $scope.loadLectures()
  .then $scope.loadProgress
