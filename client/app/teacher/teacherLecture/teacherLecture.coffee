'use strict'

angular.module('budweiserApp').config ($stateProvider) ->
  $stateProvider.state 'teacher.lecture',
    url: '/courses/:courseId/lectures/:lectureId'
    templateUrl: 'app/teacher/teacherLecture/teacherLecture.html'
    controller: 'TeacherLectureCtrl'
    authenticate: true
