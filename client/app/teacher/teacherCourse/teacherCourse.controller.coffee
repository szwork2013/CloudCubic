'use strict'

angular.module('budweiserApp').controller 'TeacherCourseCtrl', (
  $scope
  $state
  Navbar
  $rootScope
  Category
  Restangular
  notify
  $modal
) ->

  $scope.$on '$destroy', Navbar.resetTitle

  angular.extend $scope,

    deleteCallback: (course) ->
      Courses.splice(Courses.indexOf(course), 1)
      $state.go('main')

    togglePublish: ($event)->
      $event.stopPropagation()
      Restangular.one('courses', $scope.course._id).patch isPublished: !$scope.course.isPublished
      .then ->
        $scope.course.isPublished = !$scope.course.isPublished

    viewState:
      editingInfo: false

    saveCourseDesc: ()->
      Restangular.one('courses', $scope.course._id).patch description: $scope.course.description
      .then ->
        notify
          message:'已保存'
          classes: 'alert-success'

    saveCourseInfo: ()->
      Restangular.one('courses', $scope.course._id).patch
        description: $scope.course.description
        categoryId: $scope.course.$category
        info: $scope.course.info
        name: $scope.course.name
      .then (newCourse)->
        angular.extend $scope.course, newCourse
        $scope.viewState.edtingInfo = false
        $scope.course.$category = _.find $scope.categories, (category)->
          category._id is $scope.course.categoryId._id
        notify
          message:'已保存'
          classes: 'alert-success'

    removeCourse: ()->
      course = $scope.course
      $modal.open
        templateUrl: 'components/modal/messageModal.html'
        controller: 'MessageModalCtrl'
        resolve:
          title: -> '删除课程'
          message: -> "确认要删除《#{course.name}》？"
      .result.then ->
        course.remove().then ->
          $scope.deleteCallback?($course:course)

    addClass: ()->
      $modal.open
        templateUrl: 'app/admin/classeManager/editClasseModal.html'
        controller: 'EditClasseModalCtrl'
        resolve:
          Courses: -> [$scope.course]
          Classe: ->
            name: ''
            price: 0
            enrollment: {}
            duration: {}
      .result.then (newClasse) ->
        $scope.classes.push newClasse

  Restangular.one('courses', $state.params.courseId).get()
  .then (course) ->
    $scope.course = course
    Navbar.setTitle course.name, "teacher.course({courseId:'#{$state.params.courseId}'})"
    Category.find()
  .then (categories) ->
    $scope.categories = categories
    $scope.course.$category = _.find $scope.categories, (category)->
      category._id is $scope.course.categoryId._id

  Restangular.all('classes').getList courseId: $state.params.courseId
  .then (classes) ->
    $scope.classes = classes
    $scope.selectedClasse = classes?[0]


