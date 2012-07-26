template = require('./templates/note')
CNEditor = require('./editor').CNEditor
Note = require('../models/note').Note

# Row displaying application name and attributes
class exports.NoteWidget extends Backbone.View
    className: "note-full"
    tagName: "div"
   
    ### Constructor ####

    constructor: (@model) ->
        super()

        @id = @model.slug
        @model.view = @

    remove: ->
        $(@el).remove()


    ### configuration ###
    

    render: ->
    #breadcrumb will contain the path of the selected note in a link format(<a>)
    # the code below generates the breadcrumb corresponding
    # to the current note path
        i = 0
        breadcrumb = ""
        linkToThePath = []
        while i < @model.humanPath.split(",").length
            linkToThePath[i] = @model.humanPath.split(",")[0..i].join("/")
            path = "/#note/#{linkToThePath[i]}".toLowerCase()
            path = path.replace(/\s+/g, "-")
            linkToThePath[i] = "<a href='#{path}'> #{@model.humanPath.split(",")[i]}</a>"
            if i is 0
                breadcrumb += "#{linkToThePath[i]}"
            else
                breadcrumb += " > #{linkToThePath[i]}"
            i++
            
        $("#note-full-breadcrumb").html breadcrumb
        $("#note-full-title").html @model.title
        console.log @model.title
        # load the base's content into the editor
        $("#note-area").html require('./templates/editor')
        myContent = @model.content
        
        # Callback to execute when the editor is ready
        # this refers to the editor during instanciation
        callBackEditor = () ->
            editorCtrl = this
            # load the base's content into the editor
            if myContent
                editorCtrl.setEditorContent(myContent)
            else
                editorCtrl.deleteContent()
            # buttons for the editor
            $("#indentBtn").on "click", () ->
                editorCtrl._addHistory()
                editorCtrl.tab()
            $("#unIndentBtn").on "click", () ->
                editorCtrl._addHistory()
                editorCtrl.shiftTab()
            $("#markerListBtn").on "click", () ->
                editorCtrl._addHistory()
                editorCtrl.markerList()
            $("#titleBtn").on "click", () ->
                editorCtrl._addHistory()
                editorCtrl.titleList()
            $("#saveBtn").on "click", () ->
                editorCtrl._addHistory()
            $("#clearBtn").on "click", () ->
                editorCtrl._addHistory()
                editorCtrl.deleteContent()
    
                
        # creation of the editor itself
        instEditor = new CNEditor($('#editorIframe')[0], callBackEditor)
        note = @model
        
        $("iframe").on "onHistoryChanged", () ->
            console.log "call onNoteChanged"
            console.log instEditor.getEditorContent()
            content = instEditor.getEditorContent()
            note.saveContent content

        #params = { allowScriptAccess: "always" }
        #atts = { id: "myytplayer" }
        #swfobject.embedSWF("http://www.youtube.com/v/YAOv-KGh1qw?enablejsapi=1&playerapiid=ytplayer&version=3",
        #               "ytapiplayer", "425", "356", "8", null, null, params, atts)
        #ytplayer = document.getElementById("myytplayer")
        #
        #$("#video").click =>
        #    videoUrl = $("#video-url").val()
        #    ytplayer.cueVideoById(videoUrl, 0, "default")
        #$("a.video-timer").click (event) ->
        #    videoTimer = event.target.text.split(":")
        #    lastElem = videoTimer.length - 1
        #    minute = videoTimer[lastElem - 1]
        #    seconde = videoTimer[lastElem]
        #    if lastElem is 2
        #        hour = videoTimer[0]
        #    else
        #        hour = 0
        #    totalSeconds = parseInt(seconde) + parseInt((60*minute)) + parseInt((3600*hour))
        #    ytplayer.seekTo(totalSeconds)
        #$("#note-full-content-with-video").dblclick =>
        #    content = $("#note-full-content-with-video").html()
        #    $("#note-area").append("<textarea id='note-full-content-with-video'>#{content}</textarea>")
        
        return @el
        

    # TO WIPE OUT
    @setEditor: (changeCallback) ->
        #$("#note-area").html require('./templates/editor')
        # the save button cannot work because it does not exist at the moment
        # we try to bind the "save" event to it (since the editor isnt ready
        # yet)
        saveBtn = $ document.createElement("button")
        $("#note-area").before saveBtn
        saveBtn.text "Save"
        saveBtn.on "click", () =>
            console.log "kikoo"
        
        #console.log $ "iframe"
        #$("iframe").on "onHistoryChanged", () ->
        #    console.log "kikoo"
        #    changeCallback()   
            
        #editor.on "click", () =>
            #changeCallback()
        #editor = $("#editor-content")
        #editor.keyup (event) =>
            #changeCallback()
