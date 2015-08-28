
var gulp        = require('gulp'),
    packager    = require('electron-packager'),

    coffee      = require('gulp-coffee'),
    notify      = require('gulp-notify'),
    plumber     = require('gulp-plumber'),
    stylus      = require('gulp-stylus'),
    uglify      = require('gulp-uglify');

gulp.task('stylus', function() {
    gulp.src('src/**/*.stylus')
        .pipe(plumber({
            errorHandler: notify.onError('<%= error.message %>') }))
        .pipe(stylus({ compress: true }))
        .pipe(gulp.dest('src'));
});

gulp.task('coffee', function() {
    gulp.src('src/**/*.coffee')
        .pipe(plumber({
            errorHandler: notify.onError('<%= error.message %>') }))
        .pipe(coffee({ bare: true }))
        .pipe(uglify())
        .pipe(gulp.dest('src'));
});

gulp.task('default', ['stylus', 'coffee'], function() {
    gulp.watch('src/**/*.stylus', ['stylus']);
    gulp.watch('src/**/*.coffee', ['coffee']);
});

gulp.task('build', ['stylus', 'coffee'], function(done) {
    ignore = 'build|resources|\.stylus|\.coffee|\.log|' +
        Object.keys(require('./package.json').devDependencies).join('|');

    packager({
        dir: '',
        name: 'sourcer',
        platform: 'all',
        arch: 'x64',
        version: '0.30.4',
        out: 'build',
        icon: 'resources/sourcer',
        ignore: ignore,
        overwrite: true,
    }, done);
});
