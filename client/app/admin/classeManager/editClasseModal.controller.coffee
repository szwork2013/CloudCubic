'use scrict'

angular.module('budweiserApp')

.controller 'EditClasseModalCtrl', (
  $scope
  Courses
  Classe
  notify
  Restangular
  $modalInstance
) ->

  angular.extend $scope,
    errors: null
    classe: Classe
    courses: Courses

    cancel: ->
      $modalInstance.dismiss('cancel')

    confirm: (form) ->
      if !form.$valid then return
      $scope.errors = null
      (
        if $scope.classe._id?
          Restangular.one('classes', $scope.classe._id).patch($scope.classe)
        else
          Restangular.all('classes').post($scope.classe)
      )
      .then $modalInstance.close
      .catch (error) ->
        $scope.errors = error?.data?.errors
        notify
          message: '编辑开课班级信息失败'
          classes: 'alert-danger'

  if $scope.classe.$course
    $scope.classe.courseId = $scope.classe.$course._id
