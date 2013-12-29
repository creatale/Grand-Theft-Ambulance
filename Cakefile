{spawn} = require 'child_process'
os = require 'os'

cmd = (name) ->
	if os.platform() is 'win32' then name + '.cmd' else name

npm = cmd 'npm'
brunch = cmd 'brunch'

task 'install', 'Install node.js packages', ->
	spawn npm, ['install'], {cwd: '.', stdio: 'inherit'}

task 'update', 'Update node.js packages', ->
	spawn npm, ['update'], {cwd: '.', stdio: 'inherit'}
	
task 'build', 'Build brunch project', ->
	brunch = spawn brunch, ['build'], {cwd: '.', stdio: 'inherit'}

task 'watch', 'Watch brunch project and rebuild if something changed', ->
	brunch = spawn brunch, ['watch', '--server'], {cwd: '.', stdio: 'inherit'}
