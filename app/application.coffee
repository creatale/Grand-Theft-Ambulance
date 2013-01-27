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
					@game = require 'game/game'
				$('#startbutton').click =>
					$(window).unbind('keypress')
					$('#loading').remove()
					@game = require 'game/game'

		# Freeze the object
		Object.freeze? Application

$ ->
	Application.initialize()
	Backbone.history.start()#{pushState: true})
