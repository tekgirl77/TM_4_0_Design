/*jslint node: true */
"use strict";

var auth             = require('../middleware/auth'),    
    preCompiler      = require(process.cwd() + '/node/services/jade-pre-compiler.js'),
    Help_Controller  = require('../controllers/Help-Controller'),
    Login_Controller = require('../controllers/Login-Controller');
//console.log(jade);


module.exports = function (app) 
{
    preCompiler.cleanCacheFolder();
    
    //app.get('/getting-started/index.html'  , function (req, res)  { res.redirect('/user/login/returning-user-login.html');});
    
    
    
    //login routes
    
    app.get ('/user/login' , function (req, res) { new Login_Controller(res, req).redirectToLoginPage(); }); 
    app.post('/user/login' , function (req, res) { new Login_Controller(req, res).loginUser          (); });
    app.get ('/user/logout', function (req, res) { new Login_Controller(req, res).logoutUser         (); });
    
    //help routes
    
    app.get('/help/:page*' , function (req, res) { new Help_Controller(req, res).renderPage(); });
    app.get('/Image/:name' , Help_Controller.redirectImagesToGitHub);                            
    
    // jade (pre-compiled) pages (these have to be the last set of routes)
    
    app.get('/:page.html'                                   , function (req, res)  { res.send(preCompiler.renderJadeFile('/source/html/'                         + req.params.page + '.jade'                       ));});     
    app.get('/landing-pages/:page.html'                     , function (req, res)  { res.send(preCompiler.renderJadeFile('/source/html/landing-pages/'           + req.params.page + '.jade'                       ));});         
    app.get('/user/login/:page.html'                        , function (req, res)  { res.send(preCompiler.renderJadeFile('/source/html/user/login/'              + req.params.page + '.jade'                       ));}); 
    app.get('/:area/:page.html'            , auth.checkAuth , function (req, res)  { res.send(preCompiler.renderJadeFile('/source/html/' + req.params.area + '/' + req.params.page + '.jade'                       ));});     
    
    //Redirect to Jade pages
    app.get('/'                                             , function (req, res)  { res.redirect('/default.html'                                                     );});
    app.get('/deploy/html/:area/:page.html'                 , function (req, res)  { res.redirect('/'                 + req.params.area +'/'+req.params.page + '.html');});     
    
};