require_relative './provider_strategies/facebook'

class Provider
  attr_reader :name

  def self.<<(provider)
    all << provider
  end

  def self.all
    @providers ||= []
  end

  def self.[](name)
    @providers.select {|provider| provider.name == name}.first
  end

  def initialize(name)
    @name = name
  end

  def endpoint_url
    "/#{@name}"
  end

  def best_strategy(env)
    strategies.map {|strategy| strategy.new(env)}.select(&:valid?).first
  end

  def strategy(env)
    best_strategy(env) || raise("No strategy".inspect)
  end

  def authentication_url(env)
    strategy(env).authentication_url
  end

  def uid(env)
    strategy(env).uid
  end

  def strategies
    [ProviderStrategies::Facebook]
  end

  if ENV['AUTH_PROVIDERS']
    ENV['AUTH_PROVIDERS'].split(/[\s,]+/).each do |name|
      provider = self.new name
      self << provider
    end
  end
end
