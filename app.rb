require "sinatra"
require "sinatra/reloader"
require "http"
require "json"
require "sinatra/cookies"

get("/") do
  erb(:homepage)
end

get("/umbrella") do
  erb(:umbrella_form)
end

post("/process_umbrella") do
  @loc = params.fetch("user_loc")
  @loc_url_version = @loc.gsub(" ","+")
  gmaps_key = ENV.fetch("GMAPS_KEY")
  google_url = "https://maps.googleapis.com/maps/api/geocode/json?address=#{@loc_url_version}&key=#{gmaps_key}"
  gmaps_data = HTTP.get(google_url)
  parsed_gmaps_data_hash = JSON.parse(gmaps_data)
  results_array = parsed_gmaps_data_hash.fetch("results")
  results2_hash = results_array.at(0)
  geometry = results2_hash.fetch("geometry")
  location = geometry.fetch("location")
  @lat = location.fetch("lat")
  @lng = location.fetch("lng")

  weather_key = ENV.fetch("PIRATE_WEATHER_KEY")
  weather_url = "https://api.pirateweather.net/forecast/#{weather_key}/#{@lat},#{@lng}"

  weather_data = HTTP.get(weather_url)
  parsed_weather_data = JSON.parse(weather_data)
  @currently = parsed_weather_data.fetch("currently")
  @current_temperature = @currently.fetch("temperature")
  @hourly = parsed_weather_data.fetch("hourly")
  @next_hour_summary = @hourly.fetch("summary")
  hourly_data_array = @hourly.fetch("data")
  @hourly_data_hash = hourly_data_array.at(0)
  @current_summary = @hourly_data_hash.fetch("summary")
  @first_hourly_precip = @hourly_data_hash.fetch("precipProbability")
  twelvehour_data_hash = hourly_data_array[1..12]

  yesrainy = false
  precipprob_array = []  
  preciptime_array = []

    twelvehour_data_hash.each do |hourly|
      precipprob = hourly.fetch("precipProbability")
      precipprob_array << precipprob  

      if precipprob > 0.1
        yesrainy = true
        precip_time = Time.at(hourly.fetch("time"))
        seconds_from_now = precip_time - Time.now
        hours_from_now = seconds_from_now / 60 / 60
    #    pp "In #{hours_from_now.round} hours, there is a #{(precipprob*100).round}% chance of precipitation."
      else
        precip_time = Time.at(hourly.fetch("time"))
        seconds_from_now = precip_time - Time.now
        preciptime_array << hours_from_now = (seconds_from_now / 60 / 60).round
      end
    end

    if yesrainy
      @outcome = "You might want to take an umbrella!"
    else
      @outcome = "You probably won't need an umbrella."
    end

    cookies["last_location"] = @loc
    cookies["last_lat"] = @lat
    cookies["last_lng"] = @lng
  erb(:process_umbrella)
end

get("/message") do
  erb(:message)
end

post("/msg_response") do
  request_headers_hash = {
    "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
    "content-type" => "application/json"
  }
  
  request_body_hash = {
    "model" => "gpt-3.5-turbo",
    "messages" => [
      {
        "role" => "system",
        "content" => "You are a helpful assistant who talks like Shakespeare."
      },
      {
        "role" => "user",
        "content" => "#{params.fetch("user_msg")}"
      }
    ]
  }
  
  request_body_json = JSON.generate(request_body_hash)
  
  raw_response = HTTP.headers(request_headers_hash).post(
    "https://api.openai.com/v1/chat/completions",
    :body => request_body_json
  ).to_s
  
  @parsed_response = JSON.parse(raw_response)
  
  @reply = @parsed_response.dig("choices", 0, "message", "content")
  @formatted_reply = @reply.gsub("\n", "<br>")
  cookies["input"] = params.fetch("user_msg")

  erb(:msg_response)
end

get("/chat") do
  erb(:chat)
end

post("/clear_chat") do
  cookies[:chat_history] = JSON.generate([])
  redirect to("/chat")
end

post("/chat") do
  
    # create a cookie array that includes the entirety of user messages and OpenAI replies
  pp "0000000000000000000000000000000000000"
  pp  @chat_history = JSON.parse(cookies[:chat_history] || "[]")
  pp "1111111111111111111111111111111111111"
    # self-explanatory
  pp  @current_message = params.fetch("user_chat_msg")
  pp "2222222222222222222222222222222222222222222222"
    # add a hash describing the user's most recent input
  pp  @chat_history << { "role" => "user", "content" => @current_message }
  pp "3333333333333333333333333333333333333333333333333"
  # send a hash that includes the API key and specifies that it should be received as a JSON string
  pp  request_headers_hash = {
      "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
      "content-type" => "application/json"
    }

  pp "44444444444444444444444444444444444444444444444444"
  # an array of two hashes. The first "silently" tells ChatGPT what its behavior is without the user having to specify directly. 
  #Unclear if "system" is a required term for ChatGPT to understand or what. The second specifies what the user's most recent input is.
  pp request_messages = [
      {
        "role" => "system",
        "content" => "You can only respond in British English."
      },
      {
        "role" => "user",
        "content" => @current_message
      }
    ]

  @chat_history.each do |message|
      request_messages << {
        "role" => message["role"],
        "content" => message["content"]
      }
    end
  pp "666666666666666666666666666666666666666666666666666"

  pp  request_body_hash = {
      "model" => "gpt-3.5-turbo",
      "messages" => request_messages
    }


    pp request_body_json = JSON.generate(request_body_hash)

    pp raw_response = HTTP.headers(request_headers_hash).post(
      "https://api.openai.com/v1/chat/completions",
      :body => request_body_json
    ).to_s

    @parsed_response = JSON.parse(raw_response)

 
    @reply = @parsed_response.dig("choices", 0, "message", "content")

    @chat_history << { "role" => "assistant", "content" => @reply }

    cookies[:chat_history] = JSON.generate(@chat_history)
    erb(:chat)
end
