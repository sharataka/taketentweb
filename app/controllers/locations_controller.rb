class LocationsController < ApplicationController

	before_action :require_login

	def signin
	end

	def signin_action
			username = params[:username]
			password = params[:password]

			begin
				user = Parse::User.authenticate(username, password)
				user.save
				session[:userObject] = user
				redirect_to locations_path
			rescue Parse::ParseProtocolError => e
  				status_code = e.code
  				@error_message = e.error
				redirect_to user_signin_path
			end

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

		# User.save doesn't work if sign up is unsuccessful!!!
		begin
			user.save
			session[:userObject] = user

			user_profile = Parse::Object.new("UserProfile")
			user_profile["userID"] = session[:userObject]['objectId']
			user_profile["GamesPlayed"] = 0
			user_profile["LastPlayed"] = 0
			user_profile["Wins"] = 0
			user_profile["Losses"] = 0
			user_profile.save

			redirect_to locations_path
		rescue Parse::ParseProtocolError => e
			@error_message = e.error
			redirect_to user_signup_path
		end


	end

	def logout_action
		session.delete(:userObject)
		redirect_to user_signin_path
	end

	def index
		# Is the user signed in?
		if session[:userObject]
			@signed_in = true
			@current_user = session[:userObject]
			number_of_locations_displayed = 9
		else
			@signed_in = false
			number_of_locations_displayed = 6
		end
		
		
		# If the user is signed in, get their played locations
		played_locations_array = Array.new
		if session[:userObject]
			played_locations_query = Parse::Query.new("Result").tap do |q|
	  			q.eq("user", session[:userObject]['objectId'])
			end.get

			played_locations_query.each do |played_location|
				played_locations_array << played_location['locationId']
			end			
		end

		# Query to get the next locations
		locations_query = Parse::Query.new("CoorList").tap do |q|
		  	q.limit = number_of_locations_displayed
		  	q.order_by = "Order"
  			q.order = :ascending
  			q.eq("Status", "live")
  			q.value_not_in("objectId", played_locations_array)
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
		# Is the user signed in?
		if session[:userObject]
			@signed_in = true
			@current_user = session[:userObject]
		else
			@signed_in = false
		end

		objectId = params[:objectId]

		location_query = Parse::Query.new("CoorList")
		location_query.eq("objectId", objectId)
		location_object = location_query.get
		
		# Pass data to view in hidden field
		@lat = location_object[0]['Lat']
		@long = location_object[0]['Long']
		@imageLink = location_object[0]['imageLink']
		@objectId = objectId

	end

	def result
		
		# Get parameters
		objectId = params[:objectId]
		distance = params[:distance].to_f

		# Save result
		result = Parse::Object.new("Result")
		result["user"] = session[:userObject]['objectId']
		result["distance"] = distance
		result["locationId"] = objectId
		result.save

		# Get user profile
		game_score = Parse::Query.new("UserProfile").eq("userID", session[:userObject]['objectId']).get.first
		
		# Update games played
		game_score["GamesPlayed"] = Parse::Increment.new(1)
		
		# Update wins/losses
		if distance < 500
			game_score["Wins"] = Parse::Increment.new(1)
		else
			game_score["Losses"] = Parse::Increment.new(1)
		end
		
		# Save update
		game_score.save


	end

	private
	def require_login
		require 'parse-ruby-client'
		Parse.init(application_id: 'qLfYVjRm0fmRuwLjx0F0TpzPXlQmCg31ennbB0J4', api_key: 'c3fmbo6lLjiFcujfKEvo4DIk4x9LxwAB9LFeqr3r')

		require "browser"
		# puts browser.name 
		# puts browser.mobile?
	end

end

# http://www.rubydoc.info/github/adelevie/parse-ruby-client/file/README.md
# http://www.color-hex.com/color-palette/5452
# http://getbootstrap.com/css/#forms
# https://github.com/fnando/browser
