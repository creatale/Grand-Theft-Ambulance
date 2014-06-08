#
# The home view appears upon start.
#
module.exports = class HomeView extends Backbone.View
	template: require 'views/templates/home'
	idName: 'home'
	events:
		'click .start': 'start'
		'click .mute': 'mute'

	render: =>
		@$el.attr('id', @idName).html(@template())

		if Modernizr.webgl
			$('#startbutton').prop 'disabled', false
		else
			alert 'WebGL is not supported.'
			$('#startbutton').prop 'disabled', true
		$(window).bind 'keypress', @start
		@bg0 = new Howl
			urls: ['sound/bg0.ogg', 'sound/bg0.mp3']
			autoplay: true
			loop: true
			volume: 0.5
		
	mute: =>
		button = @$('.mute')
		icon = @$('.mute > span')
		if icon.hasClass 'glyphicon-volume-off'
			@bg0.play()
			button.removeClass 'active'
			icon.removeClass 'glyphicon-volume-off'
			icon.addClass 'glyphicon-volume-up'
		else
			@bg0.pause()
			icon.removeClass 'glyphicon-volume-up'
			icon.addClass 'glyphicon-volume-off'
			button.addClass 'active'

	start: =>
		$(window).unbind 'keypress'
		@bg0.stop()
		@trigger 'start'
		