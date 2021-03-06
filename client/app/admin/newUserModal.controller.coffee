'use strict'

angular.module('budweiserApp').controller 'NewUserModalCtrl', (
  $log
  $scope
  notify
  configs
  userRole
  existingUsers
  Restangular
  $modalInstance
) ->

  angular.extend $scope,
    imageSizeLimitation: configs.imageSizeLimitation

    user:
      role: userRole
      email: ''

    title:
      switch userRole
        when 'student' then '添加学生'
        when 'teacher' then '添加老师'
        when 'admin'   then '添加管理员'
        else $log.error "unknown user.role #{userRole}"

    searchedUsers: []
    selectedUser: null
    existingUsers : existingUsers

    selectUser: ($item, search, $event)->
      $scope.selectedUser = $item

    searchUsers: ($search)->
      if $search.search
        $scope.searchedUsers.length = 0
        Restangular.all('users/match').getList {keyword: $search.search, role: userRole}
        .then (users)->
          if users.length
            existNames = _.pluck $scope.existingUsers, 'name'
            filteredUsers = _.filter users, (user) ->
              return (_.indexOf existNames, user.name) < 0

            filteredUsers.forEach (user)->
              email = user.email ? ''
              $scope.searchedUsers.push
                text: user.name + ' ' + email
                user: angular.copy(user)
          else if /^[_a-z0-9-\+]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})$/i.test $search.search
            $scope.searchedUsers.push
              text: '发送邀请给' + $search.search
              email: $search.search
            $scope.selectedUser = $scope.searchedUsers[0]
            $scope.targetUser = $scope.selectedUser

    cancel: ->
      $modalInstance.dismiss('cancel')

    confirm: (form) ->
      $scope.submitted = true
      unless $scope.selectedUser? || $scope.user.email?
        form.email.$setValidity 'required', false
      return if !form.$valid

      if $scope.selectedUser?.user
        $modalInstance.close $scope.selectedUser.user
      else
        newUser = angular.copy $scope.user
        if $scope.selectedUser?
          newUser.email = $scope.selectedUser.email
          newUser.name = $scope.selectedUser.email.replace(/@.*/,'')
        else
          newUser.name = newUser.email.replace(/@.*/,'')
        Restangular.all('users').post newUser
        .then $modalInstance.close, (error) ->
          # Update validity of form fields that match the mongoose errors
          angular.forEach error.data.errors, (error, field) ->
            form[field].$setValidity 'mongoose', false
