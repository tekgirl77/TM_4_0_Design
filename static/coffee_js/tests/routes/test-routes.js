/*jslint node: true */
/*global describe, it, before, after */
"use strict";

var assert   = require('chai').assert, 
    expect   = require('chai').expect, 
    Browser  = require('zombie'),    
    app      = require('../../server');    
    
describe('routes | test-routes.js |', function () 
{
    before(function() { app.server = app.listen(app.port); Browser.localhost("localhost", app.port);});
    after (function() { app.server.close();                                                             });
    
    describe('routes step up |', function() 
    {
        it('Check app variable/import', function ()
        {        
            expect(app        ).to.be.a('function');
            expect(app._router).to.be.a('function');
        });
        
        it('Check expected paths',function()
        { 
            var paths = [];
            var routes = app._router.stack;

            routes.forEach(function(item) 
            {
                if (item.route) { paths.push(item.route.path);}
            });

            //console.log(paths);  
            var expectedPaths = [ '/',                                     
                                  '/deploy/html/:area/:page.html',                  // jade page rendering
                                  '/:page.html'                  ,
                                  '/user/login/:page.html'       ,
                                  '/landing-pages/:page.html'    ,
                                  '/help/:page*'                 ,
                                  '/Image/:name'                 , 
                                  '/:area/:page.html'            ,

                                  '/getting-started/index.html'  ,                  // static redirects

                                  '/user/login'                  ,                  // Authentication
                                  '/user/login'                  ,
                                  '/user/logout'                 ,
                                  
                                  '/libraries'                   ,
                                  '/library/:name'               , 
                                  '/library/:library/folder/:folder',
                                  
                                  '/search'                      ,                  // search
                                  '/search.json'                 ,
                                  '/search/:file'                ,
                                  '/graph'                       , 
                                  
                                  '/dirName'                     ,                  // debug ones 
                                  '/pwd'                         ,
                                  '/test'                        ,
                                  '/ping'                        ,
                                  '/module'                      ,
                                  '/mainModule'                  ,
                                  
                                  '/version'                     ,                  // config ones
                                  '/config'                      , 
                                  
                                  '/session'                                                                                       ,
                                 ];

            expect(paths.length).to.be.equal(expectedPaths.length);
            paths.forEach(function(path)
            {
                expect(expectedPaths).to.contain(path);
            });        
        });  
    });    
});