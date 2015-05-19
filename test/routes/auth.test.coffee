supertest       = null
Express_Service = null
request         = null
express         = null
bodyParser      = null
path            = null
cookie          = null
jar             = null


describe '| routes | routes.test |', ()->

  @.timeout 4000
  app             = null
  set_LoginStatus  = ->

  #mocked server
  server                   = null
  url_Mocked_Server        = null
  config                   = null
  req                      = null
  res                      = null

  register_Routes = (app)=>
    app.post '/tmWebServices/Login', (req,res)->
      set_LoginStatus(req,res)
    app.get '/foo', (req,res)->
      res.status(404).render 'source/jade/guest/404.jade',{loggedIn:req.session?.username isnt undefined}
    app.get '/bar', (req,res)->
      res.status(500).render 'source/jade/guest/500.jade',{loggedIn:req.session?.username isnt undefined}

  dependencies = ->
    supertest       = require 'supertest'
    Express_Service = require '../../src/services/Express-Service'
    request         = require('request')
    express         = require 'express'
    bodyParser      = require('body-parser')
    path            = require "path"


  before (next)->
    dependencies()
    random_Port           = 10000.random().add(10000)
    url_Mocked_Server     = "http://localhost:#{random_Port}"
    app                   = new express().use(bodyParser.json())
    register_Routes(app)
    # set Views path
    app.set('views', path.join(__dirname,'../../'))
    server                = app.listen(random_Port)

    url_Mocked_Server.GET (html)->
      html.assert_Is 'Cannot GET /\n'
      next()

    after ()->
      server.close()

  it 'Issue 723 - Verify Auth status on 404 error pages', (done)->
    #require('request-debug')(request)

    set_LoginStatus = (ws_req,ws_res)->
      ws_res.render 'source/jade/guest/404.jade', loggedIn:true, (err, html)->
        if (not err)
          html.assert_Contains '<li><a id="nav-user-logout" href="/user/logout"><i class="fi-power"></i><span>Logout</span></a></li>'
          ws_res.status(404).send html
    getOptions = {
      method: 'get',
      url: url_Mocked_Server + '/foo',
    }
    postOptions = {
      method: 'post',
      url: url_Mocked_Server + '/tmWebServices/Login',
      json   : true,
    }
    request postOptions, (err, response, body)=>
      response.statusCode.assert_Is 404
      response.body.assert_Contains '<li><a id="nav-user-logout" href="/user/logout"><i class="fi-power"></i><span>Logout</span></a></li>'
      request getOptions, (err, response, body)=>
        response.statusCode.assert_Is 404
        response.body.assert_Contains '<li><a id="nav-login" href="/guest/login.html">Login</a></li>'
        done()

  it.only 'Issue 723 - Verify Auth status on 500 error page', (done)->
    #require('request-debug')(request)

    set_LoginStatus = (ws_req,ws_res)->
      ws_res.render 'source/jade/guest/500.jade', loggedIn:true, (err, html)->
        if (not err)
          html.assert_Contains '<li><a id="nav-user-logout" href="/user/logout"><i class="fi-power"></i><span>Logout</span></a></li>'
          ws_res.status(500).send html
    getOptions = {
      method: 'get',
      url: url_Mocked_Server + '/bar',
    }
    postOptions = {
      method: 'post',
      url: url_Mocked_Server + '/tmWebServices/Login',
    }
    request postOptions, (err, response, body)=>
      response.statusCode.assert_Is 500
      response.body.assert_Contains '<li><a id="nav-user-logout" href="/user/logout"><i class="fi-power"></i><span>Logout</span></a></li>'
      request getOptions, (err, response, body)=>
        response.statusCode.assert_Is 500
        response.body.assert_Contains '<li><a id="nav-login" href="/guest/login.html">Login</a></li>'
        done()
