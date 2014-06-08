#
# The stage view appears while playing.
#
module.exports = class StageView extends Backbone.View
	template: require 'views/templates/stage'
	idName: 'stage'

	render: =>
		@$el.attr('id', @idName).html(@template())
		require 'game/game'
		@
