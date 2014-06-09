#
# The home view appears upon start.
#
module.exports = class HomeView extends Backbone.View
	template: require 'views/templates/home'
	idName: 'home'
	events:
		'click .start': 'start'
		'click #music': 'toggleMusic'

	render: =>
		@$el.attr('id', @idName).html(@template())

		if Modernizr.webgl
			$('#startbutton').prop 'disabled', false
			$(window).bind 'keypress', @start
		else
			alert 'WebGL is not supported.'
			$('#startbutton').prop 'disabled', true

		@bg0 = new Howl
			urls: ['sound/bg0.ogg', 'sound/bg0.mp3']
			autoplay: true
			loop: true
			volume: 0.125
		
	toggleMusic: =>
		if @$('#music').is ':checked'
			@bg0.play()
		else
			@bg0.pause()

	start: =>
		$(window).unbind 'keypress'
		@bg0.unload()
		@trigger 'start'
		