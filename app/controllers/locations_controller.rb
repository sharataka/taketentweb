class LocationsController < ApplicationController

	before_action :require_login

	def signin
	end

	def signup
	end

	def signup_action
		username = params[:username]
		password = params[:password]


		user = Parse::User.new({
		  :username => username,
		  :password => password
		})

		# User.save doesn't work!!!
		if user.save
			session[:userObject] = user


			user_profile = Parse::Object.new("UserProfile")
			user_profile["userID"] = session[:userObject]['objectId']
			user_profile["GamesPlayed"] = 0
			user_profile["LastPlayed"] = 0
			user_profile["Wins"] = 0
			user_profile["Losses"] = 0
			user_profile.save

			redirect_to locations_path
		else
			puts 'didnt work'
		end

	end

	def logout_action
		session.delete(:userObject)
		redirect_to user_signup_path
	end

	def index
		# http://www.rubydoc.info/github/adelevie/parse-ruby-client/file/README.md
		
		# Is the user signed in?
		if session[:userObject]
			@signed_in = true
		else
			@signed_in = false
		end

		# Query to get the next 
		locations_query = Parse::Query.new("CoorList").tap do |q|
		  	q.limit = 6
		  	q.order_by = "Order"
  			q.order = :ascending
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
		objectId = params[:objectId]
		location_query = Parse::Query.new("CoorList")
		location_query.eq("objectId", objectId)
		location_object = location_query.get
		@lat = location_object[0]['Lat']
		@long = location_object[0]['Long']
		@imageLink = location_object[0]['imageLink']
	end

	def result
		# puts params[:objectId]
	end

	private
	def require_login
		require 'parse-ruby-client'
		Parse.init(application_id: 'qLfYVjRm0fmRuwLjx0F0TpzPXlQmCg31ennbB0J4', api_key: 'c3fmbo6lLjiFcujfKEvo4DIk4x9LxwAB9LFeqr3r')
	end

end
