/*jslint node: true */
"use strict";

var users = [ { username : 'tm'   , password : 'tm'   } ,
              { username : 'user' , password : ''     } ,
              { username : 'roman', password : 'longpassword'     }
            ];
            
var loginPage         = '/user/login/returning-user-validation.html';
var mainPage_user     = '/home/main-app-view.html';
var mainPage_no_user  = '/landing-pages/index.html';                

var Login_Controller = function(req, res) 
    {
        //var that  = this;
        
        this.users              = users;
        this.loginPage          = loginPage;
        this.mainPage_user      = mainPage_user;
        this.mainPage_no_user   = mainPage_no_user;
        this.req                = req;
        this.res                = res;          
        
        this.redirectToLoginPage = function()
            {
                this.res.redirect(this.loginPage);
            };
        
        this.loginUser = function()
            {
                var username = req.body.username
                var password = req.body.password
                
                //major hack for demo (this needs to be done by consuming the GraphDB TeamMentor-Service)
                var request = require('request')
                var loginUrl = 'https://tmdev01-sme.teammentor.net/rest/login/' + username + '/' + password;
                console.log(loginUrl)
                request(loginUrl, function(error, response, body)
                    {                         
                        if (body.indexOf('00000000-0000-0000-0000-00000000000') > -1 || body.indexOf('Endpoint not found.')>-1 )
                        {
                            console.log('not logged in')                        
                            req.session.username = undefined;
                            res.redirect(loginPage);                            
                        }
                        else
                        {
                            console.log('logged in as user: ' + username);
                            req.session.username = username;
                            res.redirect(mainPage_user);
                        }
                    });
            };
//           console.log ('logging in with:' + loginUrl)
//           
//           for(var index in users)
//           {
//               var user = users[index];                    
//               if (user.username === req.body.username && user.password === req.body.password)
//               {
//                   req.session.username = user.username;
//                   res.redirect(mainPage_user);
//                   return;
//               }
//           }                
//           req.session.username = undefined;
//           res.redirect(loginPage);
//          };  
        this.logoutUser = function()
            {
                req.session.username = undefined;
                res.redirect(mainPage_no_user);
            };        
    };

module.exports = Login_Controller;