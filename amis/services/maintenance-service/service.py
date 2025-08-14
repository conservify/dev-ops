from flask import Flask
from flask import request
import os
import sys

app = Flask(__name__)

@app.route('/logo_white.png')
def static_logo():
    return app.send_static_file('logo_white.png')

@app.route('/favicon.ico')
def static_favicon():
    return app.send_static_file('favicon.ico')

@app.route('/', defaults={'path': ''})
@app.route('/<path:path>')
def catch_all(path):
    return """<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <link rel="icon" type="image/x-icon" href="favicon.ico">
    <title>Maintenance - FieldKit</title>
    <style>
    body {
      background-color: #1b80c9;
    }

    img {
      margin-top: 2em;
      margin-bottom: 2em;
      width: 250px;
    }

    h1 {
      text-align: center;
      color: #ffffff;
    }

    .message {
      text-align: center;
      color: #ffffff;
    }
    </style>
  </head>
  <body>
    <main>
        <center>
          <img src="/logo_white.png" />
        </center>

        <h1>Down for Maintenance</h1>

        <div class="message">
          <p>Sorry for the inconvenience!</p>
          <p>We are performing some maintenance at the moment.</p>
          <p>Please check back later.</p>
        </div>
    </main>
  </body>
</html>
"""

if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8080, debug=False)
