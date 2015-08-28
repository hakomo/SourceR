
{ exec }        = require 'child_process'
$               = require 'jquery'
async           = require 'async'
fs              = require 'fs'
ignore          = require 'ignore'
m               = require 'mithril'
path            = require 'path'
readdir         = require 'readdir'
readline        = require 'readline'
remote          = require 'remote'
temp            = require('temp').track()

BrowserWindow   = remote.require 'browser-window'
dialog          = remote.require 'dialog'
Menu            = remote.require 'menu'

require 'block-ui'

require('ipc').on 'c', (s) ->
    unless sr.blockedUI()
        [properties..., method] = s.split '.'
        property = properties.reduce ((property, p) -> property[p]), window
        property[method]()

prop = (store, callback) ->
    ->
        if arguments.length and store isnt arguments[0]
            callback store, arguments[0]
            store = arguments[0]
        store

sr = new sr.SourceR

window.addEventListener 'load', ->
    sr.init()
    m.mount document.getElementsByTagName('div')[0], sr

    document.addEventListener 'dragenter', (e) -> e.preventDefault()
    document.addEventListener 'dragover', (e) -> e.preventDefault()
    document.addEventListener 'drop', (e) ->
        return if sr.blockedUI()

        e.preventDefault()
        file = e.dataTransfer.files[0].path

        sr.tree.confirmChange ->
            fs.stat file, (e, stats) ->
                if e
                    console.log e

                else if stats.isDirectory()
                    sr.block '初期化しています...<br>初期化には数分かかることがあります。'
                    sr.TreeBuilder.buildFromDirectory file, sr.createdTree

                else if stats.isFile() and
                        path.extname(file).toLowerCase() is '.sourcer'
                    sr.TreeBuilder.buildFromSourcer file, sr.createdTree

    document.addEventListener 'keydown', (e) ->
        if e.altKey or e.ctrlKey or e.metaKey or e.shiftKey
        else if e.target.tagName in ['BUTTON', 'INPUT', 'SELECT', 'TEXTAREA']
            if e.which is 27
                e.target.blur()

        else if e.which is 37
            e.preventDefault()
            unless sr.blockedUI()
                m.startComputation()
                sr.tree.left()
                sr.tree.scrollNode sr.tree.focusNode()
                m.endComputation()

        else if e.which is 38
            e.preventDefault()
            unless sr.blockedUI()
                m.startComputation()
                sr.tree.up()
                sr.tree.scrollNode sr.tree.focusNode()
                m.endComputation()

        else if e.which is 39
            e.preventDefault()
            unless sr.blockedUI()
                m.startComputation()
                sr.tree.right()
                sr.tree.scrollNode sr.tree.focusNode()
                m.endComputation()

        else if e.which is 40
            e.preventDefault()
            unless sr.blockedUI()
                m.startComputation()
                sr.tree.down()
                sr.tree.scrollNode sr.tree.focusNode()
                m.endComputation()

        else if e.which is 'O'.charCodeAt(0) and not sr.blockedUI() # todo
            sr.tree.toggleTag 'OK'

        else if e.which is 'N'.charCodeAt(0) and not sr.blockedUI()
            sr.tree.toggleTag 'NG'

        else if e.which is 'S'.charCodeAt(0) and not sr.blockedUI()
            sr.tree.toggleTag 'Skip'

window.onbeforeunload = (e) ->
    sr.tree.confirmChange ->
        window.onbeforeunload = null
        setTimeout (-> remote.getCurrentWindow().close()), 0
    false
