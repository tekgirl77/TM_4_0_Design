require('fluentnode')
fs       = require('fs')
#levelup    = require("levelup")
#levelup    = require("level"        )
#levelgraph      = require('levelgraph'   )
GitHub_Service  = require('./GitHub-Service')

class GraphService

  constructor: ->
    @dataFile   = './src/article-data.json'
    @data       = null
    @server     = 'http://localhost:1332'

  dataFromGitHub: (callback)=>
    user   = "TMContent"
    repo   = "TM_Test_GraphData"
    path   = 'GraphData/article_Data.json'
    new GitHub_Service().file user, repo, path, (data)-> callback(JSON.parse(data))

  graphDataFromGraphDB: (dataId, queryId, filters, callback)=>
    dataId = dataId || 'tm-uno'
    #graphDataUrl = "#{@server}/data/#{dataId}/query/filter/tm-search?show=#{queryId}"
    #graphDataUrl = "#{@server}/view/tm-search/#{queryId}"
    #graphDataUrl = "#{@server}/graph-db/filter/#{queryId}"

    if filters
      graphDataUrl = "#{@server}/data/query_tree_filtered/#{queryId}/#{filters}"
    else
      graphDataUrl = "#{@server}/data/query_tree/#{queryId}"

    graphDataUrl.GET_Json (json)->
      callback json || {}

  resolve_To_Ids: (values, callback)=>
    url = "#{@server}/convert/to_ids/#{values}"
    url.GET_Json (json)->
      callback json || {}

  root_Queries: (callback)=>
    url_root_queries = "#{@server}/data/root_queries"              # need to call this first to create the root_query mapping
    url_query_Tree = "#{@server}/data/query_tree/Root-Queries"
    url_root_queries.GET (root_queries)->
      url_query_Tree.GET_Json (json)->
        callback json || {}

module.exports = GraphService