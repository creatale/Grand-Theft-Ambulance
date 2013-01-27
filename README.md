# Grand Theft Ambulance

This is a game where you have to steal organs and sell them (take it with a grain of salt). It was made in 48 hours for Global Game Jam 2013 ;-)

# Install for Firefox 18+

1. Unpack the ZIP
1. Open up `release/index.html`
1. Play!

# Install for Chrome 24+

This is harder because Chrome suppresses local XHR requests (thefuq?). You have several options:
  1. copy all `release/` to a web server and navigate there
  1. start Chrome with arguments (`chrome --allow-file-access-from-files`) and open up `release/index.html`

# Setup a development environment:

1. Install [Node.js](http://nodejs.org/)
1. Unpack the ZIP
1. Open up a command line in the ZIPs directory (where package.json is located) and run:
  1. `npm -g install coffee brunch`
  1. `cake install`
  1. `brunch watch --server`
1. Open [localhost:3333](http://localhost:3333) in Chrome
1. Check out some very mad hacks in `app/`

# Licsense

This game is Creative Commons BY-NC-SA licsensed (see licsense.txt).
