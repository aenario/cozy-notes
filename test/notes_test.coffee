should = require('should')
async = require('async')
Client = require('request-json').JsonClient

request = require('request')
URL = require('url')

app = require('../server')
helpers = require("./helpers")

DataTree = require("../lib/data-tree").DataTree #TODO BJA : vérifier utilité


client = new Client("http://localhost:8888/")


###
# HELPERS 
###

# vars used through the tests :
notesList = rnotes = {}
note1  = note2  = note3  = null # notes with data chosen on client side
id1    = id2    = id3    = null # notes ids
rnote1 = rnote2 = rnote3 = null # retrieved notes from the serveur
updateData = null

retrieveNotes = (notes)->
    rows = notes.rows
    rnotes[rows[0].id] = rows[0]
    rnotes[rows[1].id] = rows[1]
    rnotes[rows[2].id] = rows[2]
    rnote1 = rnotes[id1]
    rnote2 = rnotes[id2]
    rnote3 = rnotes[id3]

createNoteFunction = (title, parentNote_id, content, creationCbk) ->
    (syncCallback) ->
        noteData =
            title     : title
            content   : content
            parent_id : parentNote_id

        client.post "notes/", noteData, (error, response, body) ->
            creationCbk(body)
            syncCallback()

before (done) ->
    app.listen(8888)
    helpers.cleanDb done

after (done) ->
    app.close()
    # helpers.cleanDb done
    done()


###
# TESTS
###

describe "/notes", ->


    describe "- POST - Creation of several notes", ->

        it "should create 3 notes", (done) ->
            async.series [
                createNoteFunction "Note1 title", "all", "\n+ 01\n", (newNote)->
                    note1=newNote
                createNoteFunction "Note2 title", "all", "\n+ 02\n", (newNote)->
                    note2=newNote
            ], ->
                async.series [
                    createNoteFunction "Note3 title", note1.id, "\n+ 03\n", (newNote)->
                        note3=newNote
                ], ->
                    id1 = note1.id
                    id2 = note2.id
                    id3 = note3.id
                    should.exist note1
                    should.exist note2
                    should.exist note3
                    note1.title.should.equal 'Note1 title'
                    note2.title.should.equal 'Note2 title'
                    note3.title.should.equal 'Note3 title'
                    should.exist note3.path.length
                    note3.path.should.be.a('object').and.have.property('length')
                    done()

        it "should create the Tree.tree model and a Tree.dataTree", ->
            should.exist Tree.tree
            should.exist Tree.tree.struct
            should.exist Tree.dataTree
            should.exist Tree.dataTree.root
            should.exist Tree.dataTree.nodes
            
        it "should produce an internal tree with root->node1->node3 & root->node2 ", (done)->
            root  = Tree.dataTree.root 
            node1 = Tree.dataTree.nodes[note1.id]
            node2 = Tree.dataTree.nodes[note2.id]
            node3 = Tree.dataTree.nodes[note3.id]
            node1._parent.should.equal root
            node2._parent.should.equal root
            node3._parent.should.equal node1
            root.children[0].should.equal node1
            root.children[1].should.equal node2
            node1.children[0].should.equal node3
            done()

        it 'should store a correct tree', (done)->
            client.get "tree/", (error, response, tree) ->
                response.statusCode.should.equal 200
                tree.data.should.equal "All"
                tree.children[0].data.should.equal "Note1 title"
                tree.children[1].data.should.equal "Note2 title"
                tree.children[0].children[0].data.should.equal "Note3 title"                    
                tree.children[0].attr.id.should.equal note1.id
                tree.children[1].attr.id.should.equal note2.id
                tree.children[0].children[0].attr.id.should.equal note3.id
                done()

        it 'should affect proper path to Notes', (done)->
            console.log note1
            console.log note2
            console.log note3
            note1.path.should.eql ['Note1 title']
            note2.path.should.eql ['Note2 title']
            note3.path.should.eql ['Note1 title','Note3 title']
            done()


    describe "- GET -", ->
            
        it "should get back all the notes", (done) ->

            client.get "notes/", (error, response, notes) ->
                response.statusCode.should.equal 200
                notes.rows.length.should.equal 3
                n1 = notes.rows[0]
                n2 = notes.rows[1]
                n3 = notes.rows[2]
                originalNotes={}
                originalNotes[note1.id]=note1
                originalNotes[note2.id]=note2
                originalNotes[note3.id]=note3
                n1.title.should.equal originalNotes[n1.id].title
                n2.title.should.equal originalNotes[n2.id].title
                n3.title.should.equal originalNotes[n3.id].title
                n1.path.should.eql note1.path
                n2.path.should.eql note2.path
                n3.path.should.eql note3.path
                n1.content.should.equal originalNotes[n1.id].content
                n2.content.should.equal originalNotes[n2.id].content
                n3.content.should.equal originalNotes[n3.id].content
                done()


describe "/notes/:id", ->

    describe "GET", ->

        it "should success", (done)->

            client.get "notes/#{note3.id}", (err, resp, note) ->
                resp.statusCode.should.equal 200
                should.exist note.path.length
                note.path.length.should.equal 2
                note.path[0].should.equal 'Note1 title'
                note.path[1].should.equal 'Note3 title'
                note.title.should.equal "Note3 title"
                note.content.should.equal '\n+ 03\n'
                done()

        it "should get one note", (done)->

            client.get "notes/#{note3.id}", (err, resp, note) ->
                resp.statusCode.should.equal 200
                should.exist note.path.length
                note.path.length.should.equal 2
                note.path[0].should.equal 'Note1 title'
                note.path[1].should.equal 'Note3 title'
                note.title.should.equal "Note3 title"
                note.content.should.equal '\n+ 03\n'
                done()

    describe "PUT - update the title and content of one note", ->

        it "should success", (done) ->
            updateData = 
                title   : "Note1 title - modified"
                content : "\n+ 01 - modified\n"
            client.put "notes/#{note1.id}", updateData, (err, resp, data) ->
                resp.statusCode.should.equal 200
                console.log "put ok"
                client.get "notes/", (err, resp, notes) ->
                    resp.statusCode.should.equal 200
                    retrieveNotes(notes)
                    done()

        it "should update the note title & content", (done)->
            rnote1.title.should.equal   updateData.title
            rnote1.path[0].should.eql  updateData.title
            rnote1.content.should.equal updateData.content
            done()

        it "should not modify other notes", ->
            rnote2.title.should.eql   note2.title
            rnote2.content.should.eql note2.content
            rnote3.title.should.eql   note3.title
            rnote3.content.should.eql note3.content


        it "should update the title in the tree", (done)->
            client.get "tree/",  (err, resp, tree) ->
                resp.statusCode.should.equal 200
                tree.data.should.equal "All"
                tree.children[0].data.should.equal "Note1 title - modified"
                tree.children[0].attr.id.should.equal note1.id
                tree.children[1].data.should.equal "Note2 title"
                tree.children[1].attr.id.should.equal note2.id
                tree.children[0].children[0].data.should.equal "Note3 title"                    
                tree.children[0].children[0].attr.id.should.equal note3.id
                done()

        it "should update the path of rnote1 and of is son", (done)->
            rnote1.path.should.eql ['Note1 title - modified']
            client.get "notes/#{note3.id}", (err, resp, rnot3) ->
                should.exist rnot3.path
                rnot3.path.should.eql ['Note1 title - modified','Note3 title']
                # now that tests are ok, we update note1 in oder to ease next
                # tests
                note1.title = 'Note1 title - modified'
                note1.path = ['Note1 title - modified']
                note1.content = "\n+ 01 - modified\n"
                done()

    describe "PUT - move the note : from note1->note3 to note1->note3->note2", ->

        it "should success", (done) ->
            updateData =  parent_id : note3.id
            client.put "notes/#{note2.id}", updateData, (err, resp, data) ->
                resp.statusCode.should.equal 200
                done()

        it "should have updated the path stored in each note", (done)->
            client.get "notes/", (err, resp, notes) ->
                retrieveNotes(notes)
                rnote1.path[0].should.equal rnote1.title
                rnote3.path[0].should.equal rnote1.title
                rnote3.path[1].should.equal rnote3.title
                rnote2.path[0].should.equal rnote1.title
                rnote2.path[1].should.equal rnote3.title
                rnote2.path[2].should.equal rnote2.title
                done()

        it 'should update the tree', (done)->
            client.get "tree/", (err, resp, tree) ->
                resp.statusCode.should.equal 200
                tree.data.should.equal "All"
                tree.children[0].data.should.equal note1.title
                tree.children[0].children[0].data.should.equal note3.title
                tree.children[0].children[0].children[0].data.should.equal note2.title
                tree.children[0].attr.id.should.equal note1.id
                tree.children[0].children[0].attr.id.should.equal note3.id
                tree.children[0].children[0].children[0].attr.id.should.equal note2.id
                tree.children.length.should.equal 1
                tree.children[0].children.length.should.equal 1
                tree.children[0].children[0].children.length.should.equal 1
                tree.children[0].children[0].children[0].children.length.should.equal 0
                done()
            