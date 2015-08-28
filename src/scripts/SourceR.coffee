
sr = {}

class sr.SourceR

    init: ->
        @tree = new sr.Tree
        @visibleMemo = m.prop false
        @filter = m.prop ''
        @blockedUI = m.prop false

    newFile: ->
        @tree.confirmChange ->
            m.startComputation()
            sr.tree = new sr.Tree
            m.endComputation()

    openFile: ->
        @tree.confirmChange ->
            dialog.showOpenDialog BrowserWindow.getFocusedWindow(), {
                filters: [name: '', extensions: ['sourcer']]

            }, (files) ->
                if files
                    sr.TreeBuilder.buildFromSourcer files[0], sr.createdTree

    openFolder: ->
        @tree.confirmChange ->
            dialog.showOpenDialog BrowserWindow.getFocusedWindow(), {
                properties: ['openDirectory']

            }, (directories) ->
                if directories
                    sr.TreeBuilder.buildFromDirectory directories[0],
                        sr.createdTree

    createdTree: (e, tree) ->
        unless e
            m.startComputation()
            sr.tree = tree
            sr.applyFilter()
            m.endComputation()
        sr.unblock e

    block: (message) ->
        sr.blockedUI true
        $.blockUI
            message: message
            css:
                padding: 8
                width: '40%'
                left: '30%'
                textAlign: 'left'
                color: ''
            overlayCSS: opacity: 0.1

    unblock: (e) ->
        sr.blockedUI false
        $.unblockUI()
        if e
            console.log e

    changeFilter: (e) =>
        m.startComputation()
        m.withAttr('value', @filter) e
        @applyFilter()
        m.endComputation()

    applyFilter: =>
        m.startComputation()
        if not @filter()
            @tree.filterNone()
        else if @filter() is '_notag'
            @tree.filterNoTag()
        else if @filter() is '_memo'
            @tree.filterMemo()
        else
            @tree.filterTag @filter()
        m.endComputation()

    view: -> # todo
        visibleMemoClass = if @visibleMemo() then 'visible-memo' else ''

        progress = @tree.calcProgress()

        checkbox =
            type: 'checkbox'
            onchange: m.withAttr 'checked', @visibleMemo
            checked: @visibleMemo()

        select =
            onchange: @changeFilter
            value: @filter()

        [
            m '.header',
                m '.score',
                    m 'h1', progress[3].value
                    m '.progress',
                        m '.progress-bar.progress-bar-success',
                            style: width: progress[0].value
                        m '.progress-bar.progress-bar-danger',
                            style: width: progress[1].value
                        m '.progress-bar.progress-bar-warning',
                            style: width: progress[2].value
                    m '.label.label-success', progress[0].tag
                    progress[0].value
                    m '.label.label-danger', progress[1].tag
                    progress[1].value
                    m '.label.label-warning', progress[2].tag
                    progress[2].value
                m '.option',
                    m 'label', for: 'filter', 'フィルター'
                    m 'select#filter.form-control', select,
                        m 'option', value: '', ''
                        m 'option', value: '_notag', 'タグなし'
                        m 'option', value: '_memo', 'メモあり'
                        m 'option', value: 'OK', 'OK'
                        m 'option', value: 'NG', 'NG'
                        m 'option', value: 'Skip', 'Skip'
                    m '.checkbox', m 'label',
                        m 'input', checkbox
                        'メモを常に表示'
            m 'ul.tree-root', class: visibleMemoClass, @tree.view()
        ]
