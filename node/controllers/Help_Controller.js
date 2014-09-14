/*jslint node: true */
"use strict";

var fs                = require('fs'),        
    marked            = require('marked'),
    request           = require('request'),
    auth              = require('../routes/auth'),    
    preCompiler       = require(process.cwd() + '/node/services/jade-pre-compiler.js'),
    teamMentorContent = require(process.cwd() + '/node/services/teamMentor-content.js');


var Help_Controller = function (req, res) 
    {          
        var that  = this;
        var libraryData      = teamMentorContent.getLibraryData_FromCache();            
        var library          = libraryData[0];       

        this.page  = req.params.page;    
        this.req   = req;
        this.res   = res;



        this.renderPage = function()
            {           
                this.pageParams     = auth.mappedAuth(req);
                this.pageParams.library = library;
                this.getContent(this.page);
            };

        this.getContent = function()
            {                               
                if (this.page === "index.html")  
                {
                    var page_index_File     = './source/content/docs/page-index.md'   ; 
                    var page_index_Markdown = fs.readFileSync(page_index_File, 'utf8'); 
                    var page_index_Html     = marked(page_index_Markdown)             ;                 
                    this.mapContent(null, page_index_Html);
                }
                else
                {   
                    this.article = library.Articles[this.page];                
                    if (this.article)
                    {
                        var docs_Url   = 'https://docs.teammentor.net/content/' + this.page;                    
                        request.get(docs_Url, this.handleFetchedHtml);
                    }
                    else
                    {
                        this.mapContent("No content for the current page");
                        return;
                    }
                }            
            };
        this.handleFetchedHtml = function(error, response, body)  
            {
                if (error && error.code==="ENOTFOUND") 
                { 
                    that.mapContent("Error fetching page from docs site");
                }
                else
                {
                    that.mapContent(that.article.Title, body);
                }
            };
        this.mapContent = function(title, content)
                    {
                        this.pageParams.title   = title;
                        this.pageParams.content = content;
                        this.sendResponse(this.pageParams);
                        //callback(pageParams);
                    };

        this.getRenderedPage = function(params)
            {
                return preCompiler.renderJadeFile('/source/html/help/index.jade', params); 
            };

        this.sendResponse = function(pageParams)
            {
                var html = this.getRenderedPage(pageParams);
                this.res.status(200)
                    .send(html); 
            };            

    };

Help_Controller.redirectImagesToGitHub = function(req,res)
    {
        var gitHubImagePath = 'https://raw.githubusercontent.com/TMContent/Lib_Docs/master/_Images/';
        res.redirect(gitHubImagePath + req.params.name);
    };
                        //app.get('/Image/:name', function (req, res) {  } );

module.exports = Help_Controller;