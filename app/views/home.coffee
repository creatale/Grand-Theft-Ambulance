#
# The home view appears upon start.
#
module.exports = class HomeView extends Backbone.View
	template: require 'views/templates/home'
	idName: 'home'
	events:
		'click .start': 'start'

	render: =>
		@$el.html @template()

		if Modernizr.webgl
			$('#startbutton').prop 'disabled', false
		else
			alert 'WebGL is not supported.'
			$('#startbutton').prop 'disabled', true
		$(window).bind 'keypress', @start

	start: =>
		$(window).unbind 'keypress'
		@trigger 'start'
		