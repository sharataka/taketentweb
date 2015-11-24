class LocationsController < ApplicationController

	before_action :require_login

	def find_opponent
		@locationId = params[:objectId]
		@current_location = Parse::Query.new("CoorList").eq("objectId", @locationId).get.first
	end

	def standalone
		# Is the user signed in?
		if session[:userObject]
			@signed_in = true
			@current_user = session[:userObject]
			number_of_locations_displayed = 9
		else
			@signed_in = false
			number_of_locations_displayed = 6
		end

		@objectId = params[:objectId]
		current_location = Parse::Query.new("CoorList").eq("objectId", @objectId).get.first
		@imageLink = current_location['imageLink']
		@fact = current_location['Fact']

	end

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
			@locations = @locations.reverse
		else
			redirect_to root_path
			return
		end
		
	end

	def about
		# Is the user signed in?
		if session[:userObject]
			@signed_in = true
			@current_user = session[:userObject]
			number_of_locations_displayed = 9
		else
			@signed_in = false
			number_of_locations_displayed = 6
		end
	end

	def landing
		# Is the user signed in?
		if session[:userObject]
			redirect_to locations_path
			return
		end

		# render "test"

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
		# End of facebok login if user already has FB account


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
			user_profile["Wins"] = 0
			user_profile["Losses"] = 0
			user_profile["email"] = username
			if password == 'facebookuser'
				user_profile["signup_method"] = 'facebook'
			else
				user_profile["signup_method"] = 'email'
			end
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
		@current_picture_level = location_object[0]['Level']
		current_picture_order = location_object[0]['Order']

		# Get next location
		next_location_query = Parse::Query.new("CoorList").tap do |q|
		  	q.eq("Level", @current_picture_level)
		  	q.order_by = "Order"
  			q.order = :ascending
  			q.eq("Status", "live")
		end.get

		#Number of rounds in level
		@number_of_rounds_in_level = next_location_query.count
		
		# Continue getting next location
		i = 0
		next_location_query.each do |find_next_location|
			i = i + 1
			if current_picture_order >= find_next_location['Order']
				@current_round = i
			end
		end

		if @current_round == @number_of_rounds_in_level
			@next_location = "Round is finished"
		else
			@next_location = next_location_query[@current_round]
		end



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

		# Is the user signed in?
		if session[:userObject]
			@signed_in = true
			@current_user = session[:userObject]
		else
			@signed_in = false
			return
		end

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

	def result_level
		# Is the user signed in?
		if session[:userObject]
			@signed_in = true
			@current_user = session[:userObject]
		else
			@signed_in = false
		end

		# 1st answer
		objectId0 = params[:objectId0]
		distance0 = params[:distance0]
		won0 = params[:won0]

		# 2nd answer
		objectId1 = params[:objectId1]
		distance1 = params[:distance1]
		won1 = params[:won1]

		# 3rd answer
		objectId2 = params[:objectId2]
		distance2 = params[:distance2]
		won2 = params[:won2]

		# Insert objectIds into array
		played_location = Array.new
		played_location << objectId0
		played_location << objectId1
		played_location << objectId2

		# Insert who_won into array to figure out who won the level
		who_won = Array.new
		who_won << won0
		who_won << won1
		who_won << won2

		# Get number of wins
		count_of_wins = 0
		who_won.each do |game_result|
			if game_result == 'true'
				count_of_wins = count_of_wins + 1
			end
		end
		
		# Determine who won the level given the number of wins
		if count_of_wins >=2
			@who_won = "You won!"
		else
			@who_won = "You lost"
		end


		# Query to get locations
		locations_query = Parse::Query.new("CoorList").tap do |q|
		  	q.order_by = "Order"
  			q.order = :ascending
  			q.eq("Status", "live")
  			q.value_in('objectId', played_location)
		end.get

		# Put location objects in an array to be called by view
		locations_array = Array.new
		locations_query.each do |location|
			individual_location = Hash.new
			individual_location['Answer'] = location['Answer']
			individual_location['imageLink'] = location['imageLink']
			individual_location['objectId'] = location['objectId']

			locations_array << individual_location
		end

		@locations = locations_array

	end

	private
	def require_login
		require 'parse-ruby-client'
		Parse.init(application_id: 'qLfYVjRm0fmRuwLjx0F0TpzPXlQmCg31ennbB0J4', api_key: 'c3fmbo6lLjiFcujfKEvo4DIk4x9LxwAB9LFeqr3r')

		require "browser"
		if browser.mobile?
			@device = 'mobile'
		elsif browser.tablet?
			@device = 'mobile'
		else
			@device = 'desktop'
		end
	end

end

# http://www.rubydoc.info/github/adelevie/parse-ruby-client/file/README.md
# http://www.color-hex.com/color-palette/5452
# http://getbootstrap.com/css/#forms
# https://github.com/fnando/browser