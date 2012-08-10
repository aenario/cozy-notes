slugify = require("helpers").slugify


# Widget to easily manipulate data tree (navigation for cozy apps)
class exports.Tree

    #array for the autocompletion
    sourceList = []
    
    cozyFilter = (array, searchString) ->
        filteredFirst = []
        filtered = []
        regSentence = ""
        for char in searchString
            regSentence += ".*(#{char})"
        expFirst = new RegExp("^#{searchString}","i")
        expBold = new RegExp("([#{searchString}])","gi")
        exp = new RegExp(regSentence,"i")
        for name in array
            if expFirst.test(name)
                nameBold = name.replace(expBold, (match, p1) ->
                    "<span class='bold-name'>#{p1}</span>"
                )
                filteredFirst.push nameBold
            if exp.test(name)
                nameBold = name.replace(expBold, (match, p1) ->
                    "<span class='bold-name'>#{p1}</span>"
                )
                if !(nameBold in filteredFirst)
                    filtered.push nameBold
        filteredFirst.concat(filtered)

    # Initialize jsTree tree with options : sorting, create/rename/delete,
    # unique children and json data for loading.
    constructor: (navEl, data, callbacks) ->
        @setToolbar navEl


        #Autocomplete
        @searchField = $("#tree-search-field")
        @searchButton = $("#tree-search")
        @noteFull = $("#note-full")

        #attach an icon to a type of the elements in the autocomplete list
        selectIcon = (suggestion, array) ->
            if suggestion is "\"#{$("#tree-search-field").val()}\" à rechercher"
                "<i class='icon-search'></i>"
            else
                i = 0
                suggestion2 = suggestion.replace(/<.*?>/g,"")
                while suggestion2 isnt array[i].name
                    i++
                #when you add a new type, please add the corresponding icon here
                switch array[i].type
                    when "folder" then "<i class='icon-folder-open'></i>"
                    else ""

        $("#tree-search-field")
            .textext(
                    #add ajax for database search
                    plugins : 'tags prompt focus autocomplete'
                    prompt : 'Search...'
                    #ajax :
                    #    url : '/manual/examples/data.json'
                    #    dataType : 'json'
                    #    cacheResults : true
                    autocomplete : 
                        dropdownMaxHeight : '200px',

                        render : (suggestion) ->
                            selectIcon(suggestion, sourceList) + suggestion

                    ext : 
                        itemManager: 
                            nameField: (array) ->
                                retArray = []
                                for i in array
                                    retArray.push i.name
                                retArray
                            itemToString: (item) ->
                                if /".*" à rechercher/.test(item)
                                    item = item.replace(/"(.*)" à rechercher/, (str, p1) -> p1)
                                else
                                    item = item.replace(/<.*?>/g,"")
                )
                
            #every keyup(<=> getSuggestions) in the textext's input show sourceList as a
            #autocomplete list adding a proposition of what the user is typing
            .bind(
                    'getSuggestions', (e, data) ->
                        textext = $(e.target).textext()[0]
                        query = ((if data then data.query else "")) or ""
                        list = textext.itemManager().nameField(sourceList)
                        list = cozyFilter(list, query)
                        #faire en sorte que ca ne devienne pas un tag
                        list = ["\"#{$("#tree-search-field").val()}\" à rechercher"].concat(list) 
                        $(this).trigger "setSuggestions",
                        result: list
                )
        $(".text-selected").click =>
            console.log "tokidoki"
            $("#tree-search-field").textext.addTags(tags)

        # Creation of the tree with jstree
        tree = @_convertData data
        @treeEl = $("#tree")
        @widget = @treeEl.jstree(
            plugins: [
                "themes", "json_data", "ui", "crrm",
                "unique", "sort", "cookies", "types",
                "dnd", "search"
            ]
            json_data: tree
            types:
                "default":
                    valid_children: "default"
                "root":
                    valid_children: null
                    delete_node: false
                    rename_node: false
                    move_node: false
                    start_drag: false
            ui:
                select_limit: 1
                initially_select: [ "tree-node-all" ]
            themes:
                theme: "default"
                dots: false
                icons: false
            core:
                animation: 0
                initially_open: [ "tree-node-all" ]
            unique:
                error_callback: (node, p, func) ->
                    alert "A note has already that name: '#{node}'"
            search:
                show_only_matches: true
        )
    
        @setListeners( callbacks )

    # Create toolbar inside DOM.
    setToolbar: (navEl) ->
        navEl.prepend require('../templates/tree_buttons')
 
    #for .sort() method (array)
    sortFunction = (a, b) ->
        if a.name > b.name
            1
        else if a.name is b.name
            0
        else if a.name < b.name
            -1
 
    currentPath: ""
 
    # Bind listeners given in parameters with comment events (creation,
    # update, deletion, selection).
    setListeners: (callbacks) ->
        
        # Toolbar        
        $("#tree-create").click =>
            @treeEl.jstree("create")
        $("#tree-rename").click =>
            @treeEl.jstree("rename")
        $("#note-full-title").live("keypress", (e) ->
            if e.keyCode is 13
                false
            )
        $("#note-full-title").blur =>
            newName = $("#note-full-title").text()
            oldName = @currentData.inst.get_text @currentData.rslt.obj
            if newName isnt "" and oldName != newName
                @currentData.inst.rename_node(@currentData.rslt.obj, newName)
                #searching the targeted node to change his name
                i = 0
                while sourceList[i].name isnt oldName
                    i++
                sourceList[i].name = newName
                #sorting the array to place the newName
                sourceList.sort(sortFunction)
                #See what it changes to include the code below
                idPath = "tree-node#{@currentPath.split("/").join("-")}"
                @currentData.rslt.obj.attr "id", idPath
                @rebuildIds @currentData, @currentData.rslt.obj, idPath
                callbacks.onRename @currentPath, newName, @currentData
        $("#tree-remove").click =>
            @treeEl.jstree("remove")
        $("#searchInfo").hide()
        $("#search-button").click @_onSearchChanged
        # TODO : this event occures many many times when in the tree : not the best way
        # to add the tree-buttons
        $("#tree").mouseover @_addButton

        # Tree
        @widget.bind "create.jstree", (e, data) =>
            nodeName = data.inst.get_text data.rslt.obj
            #add nodeName to the autocomplete list
            object = {type: "folder", name: nodeName}
            sourceList.push object
            sourceList.sort(sortFunction)
            parent = data.rslt.parent
            path = @_getPath parent, nodeName
            path.pop()
            idPath = "tree-node#{@_getPath(parent, nodeName).join("-")}"
            data.rslt.obj.attr "id", idPath
            callbacks.onCreate path.join("/"), data.rslt.name, data

        @widget.bind "rename.jstree", (e, data) =>
            nodeName = data.inst.get_text data.rslt.obj
            parent = data.inst._get_parent data.rslt.parent
            path = @_getStringPath parent, data.rslt.old_name
            if path == "all"
                $.jstree.rollback data.rlbk
            else if data.rslt.old_name != data.rslt.new_name
                #searching the targeted node to change his name
                i = 0
                while sourceList[i].name isnt data.rslt.old_name
                    i++
                sourceList[i].name = data.rslt.new_name
                sourceList.sort(sortFunction)
                idPath = "tree-node#{@_getPath(parent, nodeName).join("-")}"
                data.rslt.obj.attr "id", idPath
                @rebuildIds data, data.rslt.obj, idPath
                callbacks.onRename path, data.rslt.new_name, data          

        @widget.bind "remove.jstree", (e, data) =>
            nodeName = data.inst.get_text data.rslt.obj
            #searching the element to remove
            i = 0
            while sourceList[i].name isnt nodeName
                i++
            #delete the element of index i in the array of suggestions
            sourceList.splice(i,i)
            parent = data.rslt.parent
            path = @_getStringPath parent, nodeName
            if path == "all"
                $.jstree.rollback data.rlbk
            else
                callbacks.onRemove path

        @widget.bind "select_node.jstree", (e, data) =>
            nodeName = data.inst.get_text data.rslt.obj
            parent = data.inst._get_parent data.rslt.parent
            path = @_getStringPath parent, nodeName
            @currentPath = path
            @currentData = data
            callbacks.onSelect path, data.rslt.obj.data("id")
                    
        @widget.bind "move_node.jstree", (e, data) =>
            nodeName = data.inst.get_text data.rslt.o
            parent = data.inst._get_parent data.rslt.o
            newPath = @_getPath parent, nodeName
            newPath.pop()
            oldParent = data.inst.get_text data.rslt.op
            parent = data.inst._get_parent data.rslt.op
            oldPath = @_getPath parent, oldParent
            oldPath.push(slugify nodeName)
            if newPath.length == 0
                $.jstree.rollback data.rlbk
            else
                callbacks.onDrop newPath.join("/"), oldPath.join("/"), \
                                 nodeName, data

        @widget.bind "loaded.jstree", (e, data) =>
            callbacks.onLoaded()
                

    # Rebuild ids of obj children. 
    # Not sure about the efficiency of this function
    rebuildIds: (data, obj, idPath) ->
        for child in data.inst._get_children obj
            newIdPath = idPath + "-" + slugify($(child).children("a:eq(0)").text())
            $(child).attr "id", newIdPath
            @rebuildIds data, child, newIdPath


    # Select node corresponding to given path
    selectNode: (path) ->
        nodePath = path.replace(/\//g, "-")
        node = $("#tree-node-#{nodePath}")
        
        tree = $("#tree").jstree("deselect_all", null)
        tree = $("#tree").jstree("select_node", node)


    # Returns path to a node for a given node.
    # data.inst is the js tree instance
    _getPath: (parent, nodeName) ->
        nodes = [slugify nodeName] if nodeName?

        name = "all"
        while name and parent != undefined and parent.children != undefined
            name = parent.children("a:eq(0)").text()
            nodes.unshift slugify(name)
            parent = parent.parent().parent()
        nodes

    # Return path for a node at string format.
    _getStringPath: (parent, nodeName) =>
        @_getPath(parent, nodeName).join("/")
       
    # Convert tree coming from server to jstree format.
    # It builds the root of the tree then recursively add node to it.
    _convertData: (data) =>
        # root node
        tree =
            data:
                data: "all"
                attr:
                    id: "tree-node-all"
                    rel: "root"
                children: []

        @_convertNode tree.data, data.all, "-all"
        tree.data = "loading..." if tree.data.length == 0
        tree

    # Convert a node coming from node server to jstree format. Then convertNode
    # is called recursively on node children.
    # * parentNode is the node on which converted node will be set.
    # * noteToConvert is the node that is going to be converted
    # * idpath is the current path used to build the node DOM id. 
    _convertNode: (parentNode, nodeToConvert, idpath) ->
        for property of nodeToConvert when \
                property isnt "name" and property isnt "id"
            nodeIdPath = "#{idpath}-#{property.replace(/_/g, "-")}"
            #updating autocompletion's array
            object = {type: "folder", name: nodeToConvert[property].name}
            sourceList.push object
            sourceList.sort(sortFunction)
            newNode =
                data: nodeToConvert[property].name
                metadata:
                    id: nodeToConvert[property].id
                attr:
                    id: "tree-node#{nodeIdPath}"
                    rel: "default"
                children: []
            if parentNode.children == undefined
                parentNode.data.push newNode
            else
                parentNode.children.push newNode
            @_convertNode newNode, nodeToConvert[property], nodeIdPath


    searchTimer: null

    # When quick search changes, the jstree quick search function is run with
    # input val as argument.
    _onSearchChanged: (event) =>
        searchString = $(".text-tag .text-label")[0].innerHTML
        console.log $(".text-tag .text-label")[0].innerHTML
        clearTimeout @searchTimer
        if searchString is ""
            $("#tree").jstree("search", searchString)
        else
            #@searchTimer = setTimeout(->
            $("#tree").jstree("search", searchString)
            #, 1000) 


    _addButton: (event) ->
        # TODO : these listeners should be set when the node is created in the tree.
        $("#tree a").mouseover (e) ->

            $("#tree-buttons").appendTo( this )
            $("#tree-buttons").show()
        $("#tree").mouseleave ->
            # TODO : this event occurs several times when the mouse
            # leaves the tree (?? shouldn't this hapen only once ??)
            # besides it hapens when the mouse goes over the tree-buttons
            # => not the best way to remove the tree-buttons ...
            $("#tree-buttons").hide()
