{spawn, exec} = require 'child_process'
os = require 'os'

cmd = (name) ->
	if os.platform() is 'win32' then name + '.cmd' else name

npm = cmd 'npm'
coffee = cmd 'coffee'
mocha = cmd 'mocha'
brunch = cmd 'brunch'
nodemon = cmd 'nodemon'

task 'install', 'Install node.js modules', ->
	spawn npm, ['install'], {cwd: '.', stdio: 'inherit'}

task 'test', 'Execute tests', ->
	spawn mocha, [], {cwd: '.', stdio: 'inherit'}
	
task 'run', 'Start the server', ->
	brunch = spawn brunch, ['build'], {cwd: '.', stdio: 'inherit'}

task 'watch', 'Watch for file changes and (re-)start the server', ->
	brunch = spawn brunch, ['w', '-s'], {cwd: '.', stdio: 'inherit'}

