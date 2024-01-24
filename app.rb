require "sinatra"
require "sinatra/reloader"

get("/") do
  erb(:homepage)
end

get("/umbrella") do
  erb(:umbrella_form)
end

get("/umbrella_results") do
  erb(:umbrella_results)
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
