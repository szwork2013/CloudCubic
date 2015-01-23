'use strict'

angular.module('budweiserApp').config ($stateProvider) ->

  $stateProvider.state 'teacher.course',
    url: '/courses/:courseId/classeId/:classeId'
    templateUrl: 'app/teacher/teacherCourse/teacherCourse.html'
    controller: 'TeacherCourseCtrl'
    roleRequired: 'teacher'
