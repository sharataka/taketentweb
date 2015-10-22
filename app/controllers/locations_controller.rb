class LocationsController < ApplicationController
	def index

		require 'parse-ruby-client'

		Parse.init(application_id: 'qLfYVjRm0fmRuwLjx0F0TpzPXlQmCg31ennbB0J4', api_key: 'c3fmbo6lLjiFcujfKEvo4DIk4x9LxwAB9LFeqr3r')

		# http://www.rubydoc.info/github/adelevie/parse-ruby-client/file/README.md

		locations_query = Parse::Query.new("CoorList")
		locations = locations_query.get

		locations_array = Array.new
		locations.each do |location|
			individual_location = Hash.new
			individual_location['Fact'] = location['Fact']
			individual_location['imageLink'] = location['imageLink']
			individual_location['objectId'] = location['objectId']


			locations_array << individual_location
		end

		puts locations_array

		@locations = locations_array


	end

	def guess
	end

end
