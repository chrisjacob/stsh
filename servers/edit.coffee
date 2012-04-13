coffee = require("coffee-script")
express = require("express")
gzippo = require("gzippo")
sharejs = require("share")

app = module.exports = express.createServer()

app.use gzippo.staticGzip("#{__dirname}/../public")
app.use express.static("#{__dirname}/../public")

app.set "views", "#{__dirname}/../views"
app.set "view engine", "jade"
app.set "view options", layout: false


# Start the sharejs server before variable routes
sharejs.server.attach app,
  db:
    type: "none"


app.get /^(?:\/([a-zA-Z0-9]{6})\/?)?/, (req, res) ->
  res.render "editor", page: "/edit"