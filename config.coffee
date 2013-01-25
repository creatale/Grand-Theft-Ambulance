#
# Brunch configuration file. For documentation see:
# 	http://brunch.readthedocs.org/en/latest/config.html
#
exports.config =
	paths:
		vendor: 'app/vendor'
		public: 'release/'
	files:
		javascripts:
			joinTo:
				'js/app.js': /^app(\/|\\)(?!vendor)/
				'js/vendor.js': /vendor/
			order:
				before: [
					'app/vendor/js/jquery-1.8.2.js'
					'app/vendor/js/underscore-1.3.3.js'
					'app/vendor/js/backbone-0.9.2.js'
					'app/vendor/js/bootstrap-2.1.1.js'
					'app/vendor/js/three-r55.js'
				]
		stylesheets:
			joinTo: 'css/app.css'
		templates:
			joinTo: 'js/templates.js'
	plugins:
		static_jade:
			extension: ".static.jade"
