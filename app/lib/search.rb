require 'json'
require 'typhoeus'
require 'pry'
require 'csv'
bearer_token = ENV["BEARER_TOKEN"]

# Endpoint URL for the Recent Search API
search_url = "https://api.twitter.com/2/tweets/search/recent"

# Set the query value here. Value can be up to 512 characters
query = "penny stocks"

query_params = {
  "query": query, # Required
  "max_results": 100,
  "tweet.fields": "created_at",
}

def search_tweets(url, bearer_token, query_params, next_token = nil)
  options = {
    method: 'get',
    headers: {
      "User-Agent": "v2RecentSearchRuby",
      "Authorization": "Bearer #{bearer_token}"
    },
    params: query_params,
    
  }
  if next_token
    options[:headers]["next_token"] = next_token
  end

  request = Typhoeus::Request.new(url, options)
  response = request.run

  return response
end

def parse_response(response)
  json_body = JSON.parse(response.body)
  return {
    next_token: json_body["meta"]["next_token"],
    content: json_body["data"]
  }
end

results = []
next_token = nil

loop do
  response = search_tweets(search_url, bearer_token, query_params, next_token)
  cleaned_result = parse_response(response)
  results.concat cleaned_result[:content]
  puts results.size
  
  if cleaned_result[:next_token].nil? || results.size == 1000 
    break
  else
    next_token = cleaned_result[:next_token]
  end
end

CSV.open("penny_tweets.csv", "wb") do |csv|
  csv << results.first.keys
  results.each do |h|
    csv << h.values
  end
end