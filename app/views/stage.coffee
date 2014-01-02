#
# The stage view appears while playing.
#
module.exports = class HomeView extends Backbone.View
	template: require 'views/templates/stage'
	idName: 'stage'

	render: =>
		@$el.attr('id', @idName).html(@template())

	initialize: ->
		@game = require 'game/game'