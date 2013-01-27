#
# Application object.
#
Application =
	initialize: ->
		
		# Instantiate the router
		@router = new class Router extends Backbone.Router
			routes:
				'': 'index'

			index: =>
				$(window).keypress =>
					$(window).unbind('keypress')
					$('#loading').remove()
					@demo = require 'game/demo'
				$('#startbutton').click =>
					$(window).unbind('keypress')
					$('#loading').remove()
					@demo = require 'game/demo'

		# Freeze the object
		Object.freeze? Application

$ ->
	Application.initialize()
	Backbone.history.start()#{pushState: true})
