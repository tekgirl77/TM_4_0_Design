Config          = require('../misc/Config')
Jade_Service    = require('../services/Jade-Service')
Express_Session = require('../misc/Express-Session')
bodyParser      = require('body-parser')
session         = require('express-session')
path            = require("path")
express         = require('express')
helmet          = require('helmet')
https           = require('https')
fs              = require('fs')
enforce_ssl     = require('express-enforces-ssl')
conf            = require('../../../TM_4_0_GraphDB/.tm-Config.json')


class Express_Service
  constructor: ()->
    @.app         = express()
    @loginEnabled = true;
    @.app.port    = conf.TMListen.Port
    @.app.ip      = conf.TMListen.IP
    @.app.ssl     = conf.SSL.Enable
    @.expressSession = null

  setup: ()=>
    @set_BodyParser()
    @set_Config()
    @set_Static_Route()
    @add_Session()      # for now not using the async version of add_Session
    @set_Views_Path()
    @set_Secure_Headers()
    @

  add_Session: (sessionFile)=>

    @.expressSession = new Express_Session({ filename: sessionFile || './.tmCache/_sessionData' ,session:session})
    @.app.use session({ secret: '1234567890', key: 'tm-session'
                        ,saveUninitialized: true , resave: true
                        , cookie: { path: '/' , httpOnly: true , maxAge: 365 * 24 * 3600 * 1000 }
                        , store: @.expressSession })


  set_BodyParser: ()=>
    @.app.use(bodyParser.json()                        );     # to support JSON-encoded bodies
    @.app.use(bodyParser.urlencoded({ extended: true }));     # to support URL-encoded bodies

  set_Config:()=>
    @.app.config = new Config(null, false);

  set_Static_Route:()=>
    @app.use(express['static'](process.cwd()));

  set_Views_Path :()=>
    @.app.set('views', path.join(__dirname,'../../'))

  set_Secure_Headers: ()=>
    if @app.ssl == 'True'
      @.app.use(enforce_ssl());

  map_Route: (file)=>
    require(file)(@.app,@);
    @

  start:()=>
    if process.mainModule.filename.not_Contains('node_modules/mocha/bin/_mocha')
      console.log("[Running locally or in Azure] Starting 'TM Jade' Poc on port " + @app.port)
    if @app.ssl == 'True'
      httpsOptions =
        key: fs.readFileSync(conf.PrivateKey.Location), # Located at the root of local TM_4_0_Design/ directory.
        cert: fs.readFileSync(conf.Cert.Location) # Located at the root of local TM_4_0_Design/ directory.
      @app.server = https.createServer(httpsOptions, @app).listen(@app.port, @app.ip)
      console.log("Running securely over HTTPS")
    else
      @app.server = @app.listen(@app.port, @app.ip)

  checkAuth: (req, res, next, config)=>
    if (@.loginEnabled and req and req.session and !req.session.username)
      if req.url is '/'
        res.redirect '/index.html'
      else
        res.status(403)
           .send(new Jade_Service(config).renderJadeFile('/source/jade/guest/login-required.jade'))
    else
      next()

  mappedAuth: (req)->
    data = {};
    if(req && req.session)
      data =  {
        username  : req.session.username,
        loggedIn  : (req.session.username != undefined)
      }
    return data

module.exports = Express_Service