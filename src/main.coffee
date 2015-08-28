
app = require 'app'
BrowserWindow = require 'browser-window'
Menu = require 'menu'
shell = require 'shell'

mainWindow = null

app.on 'window-all-closed', ->
    app.quit()

app.on 'ready', ->
    mainWindow = new BrowserWindow
        width: 800
        height: 600
    mainWindow.loadUrl 'file://' + __dirname + '/index.html'

    mainWindow.on 'closed', ->
        mainWindow = null

    if process.platform is 'darwin'
        mainWindow.setMenu Menu.buildFromTemplate [{
            label: 'ファイル'
            submenu: [{
                label: '新しいファイル'
                accelerator: 'Command+N'
                click: -> mainWindow.webContents.send 'c', 'sr.newFile'
            }, {
                label: 'ファイルを開く...'
                accelerator: 'Command+O'
                click: -> mainWindow.webContents.send 'c', 'sr.openFile'
            }, {
                label: 'フォルダーを開く...'
                accelerator: 'Command+Shift+O'
                click: -> mainWindow.webContents.send 'c', 'sr.openFolder'
            }, {
                label: '保存'
                accelerator: 'Command+S'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.save'
            }, {
                label: '名前を付けて保存...'
                accelerator: 'Command+Shift+S'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.saveAs'
            }]
        }, {
            label: '編集'
            submenu: [{
                label: 'すべて折りたたむ'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.foldAll'
            }, {
                label: 'ファイルまですべて展開'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.unfoldToFile'
            }, {
                type: 'separator'
            }, {
                label: 'メモの開閉'
                accelerator: 'F2'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.toggleMemo'
            }]
        }, {
            label: 'ツール'
            submenu: [{
                label: '開発者ツール'
                accelerator: 'F12'
                click: -> mainWindow.toggleDevTools()
            }]
        }, {
            label: 'ヘルプ'
            submenu: [{
                label: 'ウェブページ...'
                click: ->
                    shell.openExternal 'http://hakomo.github.io/sourcer/'
            }, {
                label: 'バグの報告・要望...'
                click: ->
                    shell.openExternal 'https://github.com/hakomo/SourceR/issues'
            }, {
                label: 'v1.0 2015/08/29'
                enabled: false
            }]
        }]

    else
        mainWindow.setMenu Menu.buildFromTemplate [{
            label: 'ファイル(&F)'
            submenu: [{
                label: '新しいファイル(&N)'
                accelerator: 'Ctrl+N'
                click: -> mainWindow.webContents.send 'c', 'sr.newFile'
            }, {
                label: 'ファイルを開く(&O)...'
                accelerator: 'Ctrl+O'
                click: -> mainWindow.webContents.send 'c', 'sr.openFile'
            }, {
                label: 'フォルダーを開く...'
                accelerator: 'Ctrl+Shift+O'
                click: -> mainWindow.webContents.send 'c', 'sr.openFolder'
            }, {
                label: '保存(&S)'
                accelerator: 'Ctrl+S'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.save'
            }, {
                label: '名前を付けて保存(&A)...'
                accelerator: 'Ctrl+Shift+S'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.saveAs'
            }]
        }, {
            label: '編集(&E)'
            submenu: [{
                label: 'すべて折りたたむ'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.foldAll'
            }, {
                label: 'ファイルまですべて展開'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.unfoldToFile'
            }, {
                type: 'separator'
            }, {
                label: 'メモの開閉'
                accelerator: 'F2'
                click: -> mainWindow.webContents.send 'c', 'sr.tree.toggleMemo'
            }]
        }, {
            label: 'ツール(&T)'
            submenu: [{
            #     label: '再読み込み(&R)'
            #     accelerator: 'Ctrl+R'
            #     click: -> mainWindow.reload()
            # }, {
                label: '開発者ツール(&D)'
                accelerator: 'F12'
                click: -> mainWindow.toggleDevTools()
            }]
        }, {
            label: 'ヘルプ(&H)'
            submenu: [{
                label: 'ウェブページ...'
                click: ->
                    shell.openExternal 'http://hakomo.github.io/sourcer/'
            }, {
                label: 'バグの報告・要望...'
                click: ->
                    shell.openExternal 'https://github.com/hakomo/SourceR/issues'
            }, {
                label: 'v1.0 2015/08/29'
                enabled: false
            }]
        }]
