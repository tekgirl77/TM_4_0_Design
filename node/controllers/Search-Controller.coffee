fs                 = null
path               = null
request            = null
Config             = null
Express_Service    = null
Jade_Service       = null
Graph_Service      = null
TeamMentor_Service = null


recentSearches_Cache = ["Logging","Struts","Administrative Controls"]
url_Prefix           = 'show'

class SearchController
    constructor: (req, res, config,express_Service)->

        fs                 = require('fs')
        path               = require('path')
        request            = require('request')
        Config             = require('../misc/Config')
        Express_Service    = require('../services/Express-Service')
        Jade_Service       = require('../services/Jade-Service')
        Graph_Service      = require('../services/Graph-Service')
        TeamMentor_Service = require('../services/TeamMentor-Service')
        @.req                = req
        @.res                = res
        @.config             = config || new Config()
        @.express_Service    = express_Service
        @.jade_Service       = new Jade_Service(@config)
        @.teamMentor_Service = new TeamMentor_Service
        @.graph_Service      = new Graph_Service()
        @.jade_Page          = '/source/jade/user/search.jade'
        @.defaultUser        = 'TMContent'
        @.defaultRepo        = 'TM_Test_GraphData'
        @.defaultFolder      = '/SearchData/'
        @.defaultDataFile    = 'Data_Validation'
        @.urlPrefix          = url_Prefix
        @.searchData         = null


    
    renderPage: ()->
        @jade_Service.renderJadeFile(@jade_Page, @searchData)

    get_Navigation: (queryId, callback)=>

      @.graph_Service.resolve_To_Ids queryId, (data)=>
        navigation = []
        path = null
        for key in data.keys()
          item = data[key]
          path = if path then "#{path},#{key}" else "#{key}"
          if item and path
            navigation.push {href:"/#{@urlPrefix}/#{path}", title: item.title , id: item.id }

        callback navigation

    showSearchFromGraph: ()=>        
        queryId = @req.params.queryId
        filters = @req.params.filters

        @get_Navigation queryId, (navigation)=>
          target = navigation.last() || {}
          @graph_Service.graphDataFromGraphDB target.id, filters,  (searchData)=>
            @searchData = searchData
            if not searchData
              @res.send(@renderPage())
              return
            searchData.filter_container = filters
            @searchData.breadcrumbs = navigation
            @searchData.href = target.href
            if filters
              @graph_Service.resolve_To_Ids filters, (results)=>
                @searchData.activeFilter = results.values()?.first()
                @res.send(@renderPage())
            else
              @res.send(@renderPage())

    search: =>
      target = @.req.query?.text
      filter = @.req.query?.filter?.substring(1)
      jade_Page = '/source/jade/user/search-two-columns.jade'

      @graph_Service.query_From_Text_Search target,  (query_Id)=>
        query_Id = query_Id?.remove '"'
        @graph_Service.graphDataFromGraphDB query_Id, filter,  (searchData)=>
          if not searchData
            @res.send @jade_Service.renderJadeFile(jade_Page, {})
            return

          searchData.text         =  target
          searchData.href         = "/search?text=#{target}&filter="

          if searchData?.id
            recentSearches_Cache.push target
          else
            searchData.no_Results = true
            @res.send @jade_Service.renderJadeFile(jade_Page, searchData)
            return
          if filter
            @graph_Service.resolve_To_Ids filter, (results)=>
              searchData.activeFilter = results.values()?.first()
              #searchData.activeFilter = { id: filter, title: filter }
              @res.send @jade_Service.renderJadeFile(jade_Page, searchData)
          else
            @res.send @jade_Service.renderJadeFile(jade_Page, searchData)

    showRootQueries: ()=>
      @graph_Service.root_Queries (root_Queries)=>
        @searchData = root_Queries
        @searchData.breadcrumbs = [{href:"/#{@urlPrefix}/", title: '/' , id: '/' }]
        @searchData.href = "/#{@urlPrefix}/"
        @res.send(@renderPage())


    showMainAppView: =>

        jadePage  = 'source/jade/user/main.jade'  # relative to the /views folder
        @topArticles (topArticles)=>
            #recentArticles =  @recentArticles()
            viewModel = {  recentArticles: {}, topArticles : topArticles, searchTerms : @topSearches() }
            @res.render(jadePage, viewModel)

    topArticles: (callback)=>
      if not @.express_Service
        callback []
        return
      @.express_Service.viewedArticles (data)->
        if (is_Null(data))
            callback []
            return
        results = {}
        for item in data
            results[item.id] ?= { href: "/article/#{item.id}", title: item.title, weight: 0}
            results[item.id].weight++
        results = (results[key] for key in results.keys())

        results = results.sort (a,b)-> a.weight > b.weight
        topResults = []
        topResults.add(results.pop()).add(results.pop())
                  .add(results.pop()).add(results.pop())
                  .add(results.pop())
        callback topResults

    topSearches: =>
        searchTerms = []
        for search in recentSearches_Cache
            searchTerms.unshift { href: "/search?text=#{search}", title: search}

        return searchTerms.take(3)



SearchController.registerRoutes = (app, expressService) ->

    expressService ?= new Express_Service()
    checkAuth       =  (req,res,next) -> expressService.checkAuth(req, res,next, app.config)
    urlPrefix       = url_Prefix            # urlPrefix should be moved to a global static class

    searchController = (method_Name) ->                                  # pins method_Name value
        return (req, res) ->                                             # returns function for express
            new SearchController(req, res, app.config,expressService)[method_Name]()    # creates SearchController object with live
                                                                         # res,req and invokes method_Name


    app.get "/"                              , checkAuth , searchController('showMainAppView')
    app.get "/#{urlPrefix}"                  , checkAuth , searchController('showRootQueries')
    app.get "/#{urlPrefix}/:queryId"         , checkAuth , searchController('showSearchFromGraph')
    app.get "/#{urlPrefix}/:queryId/:filters", checkAuth , searchController('showSearchFromGraph')
    app.get "/user/main.html"                , checkAuth , searchController('showMainAppView')
    app.get "/search"                        , checkAuth,  searchController('search')

module.exports = SearchController