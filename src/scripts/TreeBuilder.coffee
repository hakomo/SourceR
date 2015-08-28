
class sr.TreeBuilder

    constructor: (o) ->
        @tree = new sr.Tree o
        @list = []

    @buildFromDirectory: (directory, callback) ->
        builder = new sr.TreeBuilder changedFile: true
        builder.createTag directory, (e, tags) ->
            if e
                callback e

            else
                builder.createSymbolTree tags, ->
                    builder.mergeFileTree directory, callback

    createTag: (directory, callback) ->
        temp.mkdir '', (e, tempDirectory) ->
            if e
                callback e

            else
                execFile = path.join __dirname,
                    'bin', 'ctags-' + process.platform
                tempFile = path.join tempDirectory, 'tags'

                currentDirectory = path.resolve directory, '..'
                targetDirectory = path.relative currentDirectory, directory

                command = "#{execFile} -Ruf #{tempFile} #{targetDirectory}"

                exec command, cwd: currentDirectory, (e) ->
                    if e
                        temp.cleanup()
                        callback e

                    else
                        callback null, tempFile

    createSymbolTree: (tags, callback) ->
        rl = readline.createInterface
            input: fs.createReadStream tags
            output: {}

        rl.on 'line', (line) =>
            unless line[0] is '!'
                [symbol, file, ..., type] = line.split '\t'

                if type is 'f'
                    list = path.normalize(file).split path.sep
                    list.push symbol

                    @pushSymbol list

        rl.on 'close', =>
            temp.cleanup()
            @sort @tree.children
            callback()

    pushSymbol: (list) ->
        parent = @tree
        exists = true

        for name, i in list
            exists and= @exists list, i

            unless exists
                parent.children.push new sr.Node @tree,
                    parent, type: @type(list, i), name: name

            [..., parent] = parent.children

        @list = list

    exists: (list, i) ->
        if i is list.length - 1
            false

        else if i is list.length - 2
            list.length is @list.length and list[i] is @list[i]

        else
            @list.length > i + 2 and list[i] is @list[i]

    type: (list, i) ->
        if i is list.length - 1
            'symbol'
        else if i is list.length - 2
            'file'
        else
            'directory'

    sort: (nodes) ->
        if nodes.length and nodes[0].type isnt 'symbol'
            nodes.sort @compare

            for { children } in nodes
                @sort children

    compare: (a, b) ->
        (a.type > b.type) - (a.type < b.type) or
            do (a = a.name.toLowerCase(), b = b.name.toLowerCase()) ->
                (a > b) - (a < b)

    mergeFileTree: (directory, callback) ->
        readdir.read directory, (e, files) =>
            if e
                callback e

            else
                currentDirectory = path.resolve directory, '..'
                targetDirectory = path.relative currentDirectory, directory

                files = ignore().filter files
                fulls = (path.join directory, file for file in files)

                async.map fulls, fs.stat, (e, stats) =>
                    if e
                        callback e

                    else
                        for { size }, i in stats
                            list = path.normalize(files[i]).split path.sep
                            list.unshift targetDirectory

                            @insertFile list, size

                        @tree.focusFirstNode()
                        callback null, @tree

    insertFile: (list, size) ->
        parent = @tree

        for name, i in list
            type = if i is list.length - 1 then 'file' else 'directory'
            index = @index parent, { type, name }
            child = parent.children[index - 1]

            unless child and type is child.type and name is child.name
                child = new sr.Node @tree, parent, { type, name }
                parent.children.splice index, 0, child

            parent = child

        parent.size = size

    index: ({ children }, o) ->
        l = -1
        r = children.length

        until r - l is 1
            if @compare(o, children[(l + r) // 2]) < 0
                r = (l + r) // 2
            else
                l = (l + r) // 2
        r

    @buildFromSourcer: (file, callback) ->
        builder = new sr.TreeBuilder { file }
        builder.buildFromSourcer file, callback

    buildFromSourcer: (file, callback) ->
        fs.readFile file, encoding: 'utf8', (e, json) =>
            if e
                callback e

            else
                try
                    @tree.children = for o in JSON.parse json
                        @createNode o, @tree
                    @tree.focusFirstNode()
                    callback null, @tree

                catch e
                    callback e

    createNode: (o, parent) ->
        node = new sr.Node @tree, parent, o
        node.children = for child in o.children or []
            @createNode child, node
        node
