
class sr.Tree

    constructor: (o = {}) ->
        changedVirtualDom = (o, n) =>
            o?.changedVirtualDom true
            n?.changedVirtualDom true

        @children = []
        @focusNode = prop null, changedVirtualDom
        @openMemo = prop null, changedVirtualDom
        @file = m.prop o.file or ''
        @changedFile = m.prop o.changedFile or false

        @scrollNode = m.prop null
        @focusMemo = m.prop null

    toJSON: ->
        @children

    save: (callback = null) ->
        callback or= (e) ->
            if e
                console.log e

        if not @file()
            @saveAs callback

        else if @changedFile()
            fs.writeFile @file(), JSON.stringify(@), (e) =>
                unless e
                    @changedFile false
                callback e

        else
            callback()

    saveAs: (callback = null) ->
        callback or= (e) ->
            if e
                console.log e

        dialog.showSaveDialog BrowserWindow.getFocusedWindow(), {
            filters: [name: '', extensions: ['sourcer']]

        }, (file) =>
            if file
                fs.writeFile file, JSON.stringify(@), (e) =>
                    unless e
                        @file file
                        @changedFile false
                    callback e

            else
                callback null, 'canceled'

    confirmChange: (callback) ->
        if @changedFile()
            dialog.showMessageBox BrowserWindow.getFocusedWindow(), {
                message: '変更を保存しますか？'
                buttons: ['保存する', '保存しない', 'キャンセル']
                cancelId: 2

            }, (id) ->
                if id is 0
                    sr.tree.save (e, s) ->
                        if e
                            console.log e

                        else if s is 'canceled'
                        else
                            callback()

                else if id is 1
                    callback()

        else
            callback()

    foldAll: ->
        @callAll 'setAll', foldClass: 'fold'

    unfoldAll: ->
        @callAll 'setAll', foldClass: ''

    unfoldToFile: ->
        @callAll 'unfoldToFile'

    toggleMemo: ->
        if @focusNode()
            m.startComputation()
            if @focusNode() is @openMemo()
                @focusNode().closeMemo()
            else
                @focusNode().openMemo()
            m.endComputation()

    calcProgress: ->
        tags = ['OK', 'NG', 'Skip']

        o = {}
        for tag in tags.concat ['_size']
            o[tag] = 0

        for child in @children
            child.calcProgress o

        if o['_size'] < 0.5
            tag: tag, value: '0%' for tag in tags.concat ['_total']

        else
            o['_total'] = tags.reduce ((sum, tag) -> sum + o[tag]), 0

            for tag in tags.concat ['_total']
                tag: tag, value: Math.round(o[tag] * 100 / o['_size']) + '%'

    filterNone: ->
        @callAll 'setAll', filterClass: ''

    filterNoTag: ->
        @callAll 'filterNoTag'

    filterMemo: ->
        @callAll 'filterMemo'

    filterTag: (tag) ->
        @callAll 'filterTag', tag

    callAll: (method, args...) ->
        m.startComputation()
        for child in @children
            child[method] args...

        @openMemo null

        unless @visibleFocusNode()
            @focusFirstNode()
        m.endComputation()

    visibleFocusNode: ->
        node = @focusNode()

        if not node or node.filterClass()
            return false

        until node.parent is node.root
            node = node.parent

            if node.filterClass() or node.foldClass()
                return false
        true

    focusFirstNode: ->
        for child in @children when not child.filterClass()
            @focusNode child
            return
        @focusNode null

    up: ->
        unless @focusNode()
            @focusFirstNode()
            return

        foundOld = false

        for i in [@children.length - 1...-1]
            ret = @children[i].up foundOld

            if typeof ret is 'boolean'
                foundOld or= ret
            else
                @focusNode ret
                return

    down: ->
        unless @focusNode()
            @focusFirstNode()
            return

        foundOld = false

        for i in [0...@children.length]
            ret = @children[i].down foundOld

            if typeof ret is 'boolean'
                foundOld or= ret

            else
                @focusNode ret
                return

    left: ->
        if @focusNode()
            @focusNode().left()
        else
            @focusFirstNode()

    right: ->
        if @focusNode()
            @focusNode().right()
        else
            @focusFirstNode()

    toggleTag: (tag) ->
        if @focusNode()
            m.startComputation()
            @focusNode().tag if tag is @focusNode().tag() then '' else tag
            @scrollNode @focusNode()
            m.endComputation()

    view: ->
        if not @children.length
            @scrollNode null
            @focusMemo null
            m 'li', 'ソースのルートフォルダーもしくは *.sourcer ファイルをドロップしてください。'

        else if @children.reduce ((count, child) ->
                count + not child.filterClass()), 0
            views = for child in @children
                child.view()
            @scrollNode null
            @focusMemo null
            views

        else
            views = for child in @children
                child.view()
            views.push m 'li', 'フィルターに一致するものはありません。'
            @scrollNode null
            @focusMemo null
            views
