express    = require('express')
bodyParser = require('body-parser')
app        = express()
session    = require('express-session')
Config     = require('./Config')
Logger     = require('./services/Logger-Service')

global.info = new Logger().setup().log

#console.log = global.info

info('Starting Express server config')

app.config = new Config(null, false);
app.use(bodyParser.json()                        );     # to support JSON-encoded bodies
app.use(bodyParser.urlencoded({ extended: true }));     # to support URL-encoded bodies
app.use(session({secret: '1234567890', saveUninitialized: true , resave: true }));


require('./routes/flare_routes')(app);
require('./routes/routes')(app);
require('./routes/debug')(app);
require('./routes/config')(app);


app.use(express['static'](process.cwd()));

app.port       = process.env.PORT || 1337;

if(process.mainModule.filename.indexOf('node_modules/mocha/bin/_mocha'   ) > 0)
  console.log('[Running under Mocha]');
else
    console.log("[Running locally or in Azure] Starting 'TM Jade' Poc on port " + app.port)
    app.server = app.listen(app.port)

module.exports = app;