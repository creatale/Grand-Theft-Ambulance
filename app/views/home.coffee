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
		@$('#bg0')[0].volume = 0.5
		
	mute: =>
		bg0 = @$('#bg0')[0]
		button = @$('.mute')
		icon = @$('.mute > span')
		if icon.hasClass 'glyphicon-volume-off'
			bg0.muted = false
			button.removeClass 'active'
			icon.removeClass 'glyphicon-volume-off'
			icon.addClass 'glyphicon-volume-up'
		else
			bg0.muted = true
			icon.removeClass 'glyphicon-volume-up'
			icon.addClass 'glyphicon-volume-off'
			button.addClass 'active'

	start: =>
		$(window).unbind 'keypress'
		@trigger 'start'
		