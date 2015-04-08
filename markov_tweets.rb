#!/usr/bin/env ruby

require 'rubygems'
require 'marky_markov'
require 'buff'
require 'sinatra'

ACCESS_TOKEN = ENV['ACCESS_TOKEN']
PROFILE_ID  = ENV['PROFILE_ID']
PATH_TO_INPUTS = '/inputs/*.txt'
BUFFER_SIZE = 10

class TweetGenerator
	attr_accessor :dictionary
	attr_accessor :inputs

	def initialize(dictionary, inputs)
		@dictionary = dictionary
		@inputs = inputs
	end

	def update_dictionary
		markov = MarkyMarkov::Dictionary.new(@dictionary) # Saves/opens dictionary.mmd

		Dir.glob(PATH_TO_INPUT) do |item|
			markov.parse_file item
		end

		markov.save_dictionary!
	end

	def add_tweets(buffer_size)
		markov = MarkyMarkov::Dictionary.new(@dictionary) # Saves/opens dictionary.mmd

		client = Buff::Client.new(ACCESS_TOKEN)

		num_tweets = buffer_size - client.updates_by_profile_id(PROFILE_ID, status: :pending).total
		output = "Adding #{num_tweets} tweets to the buffer..."

		num_tweets.times do
			tweet_text = markov.generate_n_sentences(2).split(/\#\</).first.chomp.chop
			client.create_update(body: {text: tweet_text, profile_ids: [PROFILE_ID]})
			output << "#{tweet_text}"
		end

		output
	end
end


get '/' do
	twitbot = TweetGenerator.new('dictionary', PATH_TO_INPUTS)
	twitbot.add_tweets(BUFFER_SIZE)
end