coffee = require("coffee-script")
express = require("express")
gzippo = require("gzippo")
assets = require("connect-assets")

app = module.exports = express.createServer()

app.use assets()
app.use gzippo.staticGzip("#{__dirname}/public")
app.use express.static("#{__dirname}/public")
app.use express.logger()

app.use express.vhost "api.plnkr.co", require("./servers/api")
app.use express.vhost "raw.plnkr.co", require("./servers/raw")
app.use express.vhost "edit.plnkr.co", require("./servers/edit")

app.set "views", "#{__dirname}/views"
app.set "view engine", "jade"
app.set "view options", layout: false


app.get "/", (req, res) ->
  res.render("index", page: "/")

app.get "/documentation", (req, res) ->
  res.render("documentation", page: "/documentation")

app.get "/about", (req, res) ->
  res.render("about", page: "/about")



app.get /^\/([a-zA-Z0-9]{6})\/(.*)$/, (req, res) ->
  res.local "raw_url", "http://raw.plnkr.co/" + req.url
  res.local "plunk_id", req.params[0]
  res.render "preview"

app.get /^\/([a-zA-Z0-9]{6})$/, (req, res) -> res.redirect("/#{req.params[0]}/", 301)

if require.main == module
  app.listen process.env.PORT || 8080
  console.log "Listening on port %d", process.env.PORT || 8080