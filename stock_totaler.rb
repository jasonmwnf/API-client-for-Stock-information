require "json"
require "faraday"

class SymbolNotFound < StandardError; end
class RequestFailed < StandardError; end

# StockTotaler calculates the value of stock shares
class StockTotaler
  def initialize(stock_client)
    @stock_client = stock_client
  end

  # Calculate the value of a stock using its symbol and a number of shares
  # Returns the total value as a Float
  def total_value(stock_symbol, quantity)
    price = @stock_client.last_price(stock_symbol)
    price * quantity
  end
end

# MarkitClient provides access to the Markit On Demand API
class MarkitClient
  def initialize(http_client=Faraday.new)
    @http_client = http_client
  end

  # Get the most recent price for a stock symbol
  # Returns the price as a Float.
  # Raises RequestFailed if the request fails.
  # Raises SymbolNotFound if a price cannot be found for the provided symbol.
  def last_price(stock_symbol)
    url = "http://dev.markitondemand.com/Api/v2/Quote/json"
    data = make_request(url, symbol: stock_symbol)
    price = data["LastPrice"]

    raise SymbolNotFound.new(data["Message"]) unless price

    price
  end

  private

  # Make an HTTP GET request using @http_client
  # Returns the parsed response body.
  def make_request(url, params={})
    response = @http_client.get(url, params)
    JSON.load(response.body)
  rescue Faraday::Error => e
    raise RequestFailed, e.message, e.backtrace
  end
end

def calculate_value(stock_symbol, quantity)
  markit_client = MarkitClient.new
  stock_totaler = StockTotaler.new(markit_client)

  stock_totaler.total_value(stock_symbol, quantity.to_i)
end

if $0 == __FILE__
  symbol, quantity = ARGV
  puts calculate_value(symbol, quantity)
end