#require 'game/stage.jquery'

#
# Application object.
#
Application =
	initialize: ->

#		@accountView = new (require 'views/account_view')()
#		@stageView = new (require 'views/stage_view')()
		
		# Instantiate the router
		@router = new class Router extends Backbone.Router
			routes:
				'': 'index'
				'about': 'about'
				'support': 'support'
				'media': 'media'
				'guide': 'guide'
			

			index: ->
				require 'game/demo'
				#Application.accountView.render()
				#Application.stageView.render()
				

		# Freeze the object
		Object.freeze? Application

$ ->
	Application.initialize()
	Backbone.history.start()#{pushState: true})
