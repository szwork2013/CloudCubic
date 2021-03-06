'use strict'

angular.module('budweiserApp').directive 'teacherCourseForm', ->
  restrict: 'EA'
  replace: true
  controller: 'TeacherCourseFormCtrl'
  templateUrl: 'app/teacher/teacherCourse/teacherCourseForm.html'
  scope:
    course: '='
    categories: '='
    deleteCallback: '&'

angular.module('budweiserApp').controller 'TeacherCourseFormCtrl', (
  $http
  $scope
  notify
  configs
  messageModal
) ->

  angular.extend $scope,
    imageSizeLimitation: configs.imageSizeLimitation
    saving: false
    editingInfo: null

    switchEdit: ->
      $scope.editingInfo =
        if !$scope.editingInfo?
          _.pick $scope.course, [
            'name'
            'info'
            'categoryId'
            'thumbnail'
          ]
        else
          null

    deleteCourse: ->
      course = $scope.course
      messageModal.open
        title: -> '删除课程'
        message: -> "确认要删除《#{course.name}》？"
      .result.then ->
        course.remove().then ->
          $scope.deleteCallback?($course:course)

    saveCourse: (form)->
      unless form.$valid then return
      $scope.saving = true
      course = $scope.course
      editingInfo = $scope.editingInfo
      editingInfo.categoryId = editingInfo.categoryId._id
      course.patch(editingInfo)
      .then (newCourse) ->
        course.__v = newCourse.__v
        $scope.editingInfo = null
        $scope.saving = false
        angular.extend course, newCourse
        notify
          message:'课程信息已保存'
          classes:'alert-success'

    onThumbUploaded: (key) ->
      $scope.editingInfo.thumbnail = key
