class LocationsController < ApplicationController

	before_action :require_login

	def profile
		
		if session[:userObject]
			# Get username
			@username = session[:userObject]['username']

			# Get stats for user
			my_profile = Parse::Query.new("UserProfile").eq("userID", session[:userObject]['objectId']).get.first
			@wins = my_profile['Wins']
			@losses = my_profile['Losses']
			@games_played = my_profile['GamesPlayed']

			# Is the user signed in?
			if session[:userObject]
				@signed_in = true
				@current_user = session[:userObject]
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
			  	q.order_by = "Order"
	  			q.order = :ascending
	  			q.eq("Status", "live")
	  			q.value_in("objectId", played_locations_array)
			end.get

			# Put location objects in an array to be called by view
			locations_array = Array.new
			locations_query.each do |location|
				individual_location = Hash.new
				individual_location['Fact'] = location['Fact']
				individual_location['imageLink'] = location['imageLink']
				individual_location['objectId'] = location['objectId']

				locations_array << individual_location
			end

			@locations = locations_array
		else
			redirect_to root_path
			return
		end
		
	end


	def landing
		# Is the user signed in?
		if session[:userObject]
			redirect_to locations_path
			return
		end

		render "test"

	end

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

		# If signing up/in via facebook
		if password == 'facebook'
			
			# Change password for facebook user
			password = 'facebookuser'

			# If email exists (FB user exists), sign in
			begin
				user = Parse::User.authenticate(username, password)
				user.save
				session[:userObject] = user
				redirect_to locations_path
				return
			rescue
			end
		end
		# End of facebok login


		user = Parse::User.new({
		  :username => username,
		  :password => password
		})

		
		# Sign up the user
		begin
			user.save
			session[:userObject] = user

			user_profile = Parse::Object.new("UserProfile")
			user_profile["userID"] = session[:userObject]['objectId']
			user_profile["GamesPlayed"] = 0
			user_profile["LastPlayed"] = 0
			user_profile["Wins"] = 0
			user_profile["Losses"] = 0
			user_profile["email"] = username
			user_profile.save

			redirect_to locations_path
		rescue Parse::ParseProtocolError => e
			@error_message = e.error
			redirect_to user_signup_path
			return
		end


	end

	def logout_action
		session.delete(:userObject)
		redirect_to user_signup_path
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
		
		if browser.mobile?
			@device = 'mobile'
		else
			@device = 'desktop'
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

		# Put location objects in an array to be called by view
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
		@answer = location_object[0]['Answer']
		@objectId = objectId

		# Did user play this location before?
		if session[:userObject]
			game_score = Parse::Query.new("Result").eq("user", session[:userObject]['objectId']).eq("locationId", objectId).get.first
			if game_score
				@already_played = true
			end
		end

		# Get list of results for people that have played this location
		all_scores = Parse::Query.new("Result").eq("locationId", objectId).get
		@all_scores = ''
		if all_scores.length != 0
			all_scores.each do |score|
				@all_scores = @all_scores + score['distance'].to_s + ','
				
			end
		end

		# Remove the last ','
		@all_scores = @all_scores[0..@all_scores.length-2]
		
		render "locations/browser_guess"


	end

	def result
		# Get parameters
		objectId = params[:objectId]
		distance = params[:distance].to_f

		# Only save result if haven't played before
		game_score = Parse::Query.new("Result").eq("user", session[:userObject]['objectId']).eq("locationId", objectId).get.first
		if game_score
		else
			
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


	end

	private
	def require_login
		require 'parse-ruby-client'
		Parse.init(application_id: 'qLfYVjRm0fmRuwLjx0F0TpzPXlQmCg31ennbB0J4', api_key: 'c3fmbo6lLjiFcujfKEvo4DIk4x9LxwAB9LFeqr3r')

		require "browser"
	end

end

# http://www.rubydoc.info/github/adelevie/parse-ruby-client/file/README.md
# http://www.color-hex.com/color-palette/5452
# http://getbootstrap.com/css/#forms
# https://github.com/fnando/browser