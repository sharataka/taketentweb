class LocationsController < ApplicationController
	def index

		require 'parse-ruby-client'

		Parse.init(application_id: 'qLfYVjRm0fmRuwLjx0F0TpzPXlQmCg31ennbB0J4', api_key: 'c3fmbo6lLjiFcujfKEvo4DIk4x9LxwAB9LFeqr3r')

		# http://www.rubydoc.info/github/adelevie/parse-ruby-client/file/README.md

		# locations_query = Parse::Query.new("CoorList")
		# locations = locations_query.get

		locations_query = Parse::Query.new("CoorList").tap do |q|
		  q.limit = 6
		end.get

		locations_array = Array.new
		locations_query.each do |location|
			individual_location = Hash.new
			individual_location['Fact'] = location['Fact']
			individual_location['imageLink'] = location['imageLink']
			individual_location['objectId'] = location['objectId']

			locations_array << individual_location
		end

		@locations = locations_array


	end

	def guess
		@objectId = params[:objectId]
		puts @objectId
	end

	def result
		# puts params[:objectId]
	end

end
