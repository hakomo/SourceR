
class sr.Node

    constructor: (@root, @parent, o) ->
        changedVirtualDom = =>
            @changedVirtualDom true
            @root.changedFile true

        @type = o.type
        @name = o.name
        @size = o.size or 0
        @tag = prop o.tag or '', changedVirtualDom
        @memo = prop (o.memo or '').trim(), changedVirtualDom
        @children = []

        @changedVirtualDom = m.prop true
        @filterClass = prop '', => @changedVirtualDom true
        @foldClass = prop 'fold', => @changedVirtualDom true

        if @type is 'directory'
            @iconClass = 'glyphicon-folder-close'
        else if @type is 'file'
            @iconClass = 'glyphicon-file'
        else if @type is 'symbol'
            @iconClass = 'glyphicon-arrow-right'

    toJSON: ->
        type: @type
        name: @name
        size: @size or undefined
        tag: @tag() or undefined
        memo: @memo().trim() or undefined
        children: if @children.length then @children else undefined

    unfoldToFile: ->
        if @type is 'file'
            @foldClass 'fold'

        else
            @foldClass ''
            for child in @children
                child.unfoldToFile()

    calcProgress: (o) ->
        if @tag()
            size = @sizeAll()
            o['_size'] += size
            o[@tag()] += size

        else if @children.length
            for child in @children
                child.calcProgress o

        else
            o['_size'] += @sizeAll()

    sizeAll: ->
        if @type is 'directory'
            @children.reduce ((size, child) ->
                size + child.sizeAll()), 0

        else if @type is 'file'
            @size

        else
            @parent.size / @parent.children.length

    filterNoTag: ->
        if @tag()
            sum = @children.length * 2 + 1
        else
            sum = @children.reduce ((sum, child) ->
                sum + child.filterNoTag()), 0

        if not sum
            @filterClass ''
            @foldClass 'fold'
            0

        else if sum < @children.length * 2
            @filterClass ''
            @foldClass ''
            1

        else
            @filterClass 'filter'
            2

    filterMemo: ->
        if @children.reduce ((contains, child) ->
                child.filterMemo() or contains), false
            @filterClass ''
            @foldClass ''
            true

        else if @memo().trim()
            @filterClass ''
            @foldClass 'fold'
            true

        else
            @filterClass 'filter'
            false

    filterTag: (tag) ->
        if @tag() is tag
            @setAll filterClass: '', foldClass: 'fold'
            return true

        else if @tag()
        else if @children.reduce ((filters, child) ->
                child.filterTag(tag) or filters), false
            @filterClass ''
            @foldClass ''
            return true

        @filterClass 'filter'
        false

    setAll: (o) ->
        for property, value of o
            @[property] value

        for child in @children
            child.setAll o

    up: (foundOld) ->
        if @filterClass()
            return foundOld

        unless @foldClass()
            for i in [@children.length - 1...-1]
                ret = @children[i].up foundOld

                if typeof ret is 'boolean'
                    foundOld or= ret
                else
                    return ret

        if foundOld
            @
        else
            @ is @root.focusNode()

    down: (foundOld) ->
        if @filterClass()
            return foundOld

        if foundOld
            return @

        foundOld = @ is @root.focusNode()

        unless @foldClass()
            for i in [0...@children.length]
                ret = @children[i].down foundOld

                if typeof ret is 'boolean'
                    foundOld or= ret
                else
                    return ret
        foundOld

    left: ->
        if @children.length and not @foldClass()
            @foldClass 'fold'

        else if @parent isnt @root
            @parent.foldClass 'fold'
            @root.focusNode @parent

    right: ->
        if @foldClass()
            @foldClass ''

        else
            for child in @children when not child.filterClass()
                @root.focusNode child
                return

    scrollNode: (e) =>
        { top, bottom } = e.getBoundingClientRect()

        if top < 0
            window.scrollBy 0, top

        else if bottom > window.innerHeight
            window.scrollBy 0, bottom - window.innerHeight

    toggleFold: (e) =>
        unless e.target.tagName in ['BUTTON', 'INPUT', 'SELECT', 'TEXTAREA']
            @foldClass if @foldClass() then '' else 'fold'
            @root.focusNode @

    contextmenu: (e) =>
        unless e.target.tagName in ['BUTTON', 'INPUT', 'SELECT', 'TEXTAREA']
            if @ is @root.openMemo()
                toggleMemo =
                    label: 'メモを閉じる'
                    accelerator: 'F2'
                    click: @closeMemo

            else
                toggleMemo =
                    label: 'メモを開く'
                    accelerator: 'F2'
                    click: @openMemo

            Menu.buildFromTemplate [toggleMemo]
                .popup remote.getCurrentWindow()

    openMemo: =>
        @root.focusNode @
        @root.openMemo @
        @root.focusMemo @

    focusMemo: (e) ->
        e.focus()

    closeMemo: =>
        @root.focusNode @root.openMemo()
        @root.openMemo null

    view: ->
        changedDescendant = false
        visibleChild = not @filterClass() and
            @children.length and not @foldClass()

        if visibleChild
            views = for child in @children
                view = child.view()
                changedDescendant or= view.subtree isnt 'retain'
                view

        else
            views = (subtree: 'retain' for child in @children)

        if @changedVirtualDom() or changedDescendant
            @changedVirtualDom false

            focusClass = if @ is @root.focusNode() then 'focus' else ''
            openMemoClass = if @ is @root.openMemo() then 'open-memo' else ''

            lineMemo =
                class: focusClass + ' ' + openMemoClass
                onclick: @toggleFold
                oncontextmenu: @contextmenu
                config: if @ is @root.scrollNode() then @scrollNode else null

            textarea =
                onchange: m.withAttr 'value', @memo
                config: if @ is @root.focusMemo() then @focusMemo else null

            tag =
                onchange: m.withAttr 'value', @tag
                value: @tag()

            options = for name in [''].concat ['OK', 'NG', 'Skip']
                m 'option', value: name, name

            m 'li', class: @filterClass(),
                m '.line-memo', lineMemo,
                    m '.line',
                        m 'select.form-control', tag, options
                        m 'span.glyphicon', class: @iconClass
                        @name
                    m '.memo', @memo()
                    m '.memo-form',
                        m 'textarea.form-control', textarea, @memo()
                        m 'button.btn.btn-default',
                            type: 'button', onclick: @closeMemo, 'OK'
                m 'ul', class: @foldClass(), views

        else
            subtree: 'retain'
