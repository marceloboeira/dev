require 'rubygems'
require 'erb'
require_relative 'lib/github_api_client'

template = File.read 'lib/template.html.erb'
erb = ERB.new template, 0, '<>'

user = load_user 'marceloboeira'

repos = load_sources 'marceloboeira'
is_fork = false
File.open('index.html', 'w') {|f| f.puts erb.result}

repos = load_forks 'marceloboeira'
is_fork = true
File.open('contributions.html', 'w') {|f| f.puts erb.result}