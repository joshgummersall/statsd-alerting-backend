'use strict';

var coffee = require('gulp-coffee');
var gulp = require('gulp');
var gutil = require('gulp-util');

gulp.task('default', function() {});

gulp.task('compile', function() {
  gulp.src('./src/**/*.coffee')
    .pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(gulp.dest('./lib'));
});

gulp.task('watch', function() {
  gulp.watch('./src/**/*.coffee', ['compile']);
});
