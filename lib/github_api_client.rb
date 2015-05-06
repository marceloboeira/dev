require 'faraday'
require 'json'
require 'date'
require 'ostruct'

module DateTimeAgo
  def ago
    days_ago = (DateTime.now - self).to_i
    week = 7
    month = week*52/12
    year = month*12
    case days_ago
      when 0..1 then 'today'
      when 1..2 then 'yesterday'
      when 2..week then "#{days_ago} days ago"
      when week..2*week then 'last week'
      when 2*week..month then "#{(days_ago/week).to_i} weeks ago"
      when month..2*month then 'last month'
      when 2*month..year then "#{(days_ago/month).to_i} months ago"
      when year..2*year then 'last year'
      else "#{(days_ago/year).to_i} years ago"
    end
  end
end
DateTime.send :include, DateTimeAgo

def connection
  @connection ||= new_connection
end

def new_connection
  connection = Faraday.new 'https://api.github.com/' do |c|
    c.use Faraday::Adapter::NetHttp
  end.tap do |c|
    c.headers[:user_agent] = "GitHub API client"
    c.authorization :token, File.read('.github')
  end
end

def get(route)
  connection.get route
end

def load_user(login)
  response = get "/users/#{login}"

  OpenStruct.new(JSON response.body).tap do |user|
    user.joined_on = DateTime.parse(user.created_at).strftime('%b %d, %Y')
  end
end

def load_sources(login)
  sources.map{|source| load_repo source, login}
end

def load_forks(login)
  forks.map{|source| load_repo source, login, true}
end

def sources
  [
    { name: 'core', owner: 'freaktags' },
    { name: 'blew', owner: 'marceloboeira' },
    { name: 'blew-cli', owner: 'marceloboeira' },
    { name: 'alpha-id', owner: 'marceloboeira' }, 
    { name: 'fish', owner: 'marceloboeira' },
    { name: 'core', owner: 'spreadblood' },
    { name: 'jquery-number-suffix', owner: 'marceloboeira' },
    { name: 'awesome-macosx-dev-tools', owner: 'marceloboeira' },
    { name: 'marceloboeira.github.io', owner: 'marceloboeira' },
    { name: 'blog', owner: 'marceloboeira' },
    { name: 'logisim-7-segment-display-driver', owner: 'marceloboeira' },
    { name: 'project-euller', owner: 'marceloboeira' },
    { name: 'awesome-git-disciples', owner: 'marceloboeira' },
    { name: 'arnode', owner: 'marceloboeira' }
  ]
end

def forks
  [
    { name: 'catarse_pagarme', owner: 'catarse'},
    { name: 'catarse', owner: 'catarse'},
    { name: 'ruler', owner: 'pagarme'},
    { name: 'training-kit', owner: 'github'},
    { name: 'errbit', owner:'errbit' },  
    { name: 'loomio', owner:'loomio' },
    { name: 'codetriage', owner:'codetriage' },
    { name: 'recaptcha', owner:'ambethia' },
    { name: 'hackety-hack.com', owner: 'hacketyhack'},
    { name: 'free-for-dev', owner: 'ripienaar'},
    { name: 'newww', owner: 'npm'},
    { name: 'robomongo', owner: 'VBelozyorov'},
    { name: 'MEANS', owner:'SharePointOscar' },
    { name: 'node-gravatar', owner: 'arnabc'},
    { name: 'sails-docs', owner: 'balderdashy'},
    { name: 'sails-docs', owner: 'SailsBR'},
    { name: 'we', owner: 'wejs'}
  ]
end

def load_repo(repo, login, is_fork=false)
  response = get "/repos/#{repo.fetch(:owner, login)}/#{repo[:name]}"
  OpenStruct.new(JSON response.body).tap do |r|
    r.title = is_fork ? "#{repo[:owner]}/#{repo[:name]}" : repo[:name]
    r.description = repo.fetch(:description, r.description)[0..99]
    unless r.homepage.nil? || r.homepage.empty?
      r.description.gsub! /^(.*?)(\S*?\s*?\S*?\s*?\S*?)$/, %Q(\\1<a href="#{r.homepage}">\\2</a>)
    end
    r.description = "&nbsp;" if r.description.empty?
    r.committer = repo.fetch :committer, login
    r.new_commits, r.commits_count, r.old_commits_count = load_commits repo, login
  end
end

def load_commits(repo, login)
  response = get "/repos/#{repo.fetch(:owner, login)}/#{repo[:name]}/commits?author=#{repo.fetch(:committer, login)}&per_page=100"
  all_commits = JSON response.body
  three_commits = all_commits.take(3).map{|commit| load_commit commit}
  [three_commits, all_commits.size, [all_commits.size - 3, 0].max]
end

def load_commit(commit)
  OpenStruct.new(commit).tap do |c|
    c.short_sha = c.sha[0..6]
    c.timestamp = c.commit['author']['date']
    c.timestamp_ago = DateTime.parse(c.timestamp).ago
    c.message = c.commit['message'].split("\n").first[0..71]
  end
end
