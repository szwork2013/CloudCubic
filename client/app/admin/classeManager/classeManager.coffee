'use strict'

angular.module('budweiserApp').config ($stateProvider) ->
  $stateProvider.state 'admin.classeManager',
    url: '/classeManager'
    templateUrl: 'app/admin/classeManager/classeManager.html'
    controller: 'ClassemanagerCtrl'