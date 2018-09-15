class Player < ApplicationRecord
  has_many :games
  include HTTParty

  def self.import_players
    teams = ['hawks','celtics','nets','hornets','bulls','cavaliers','mavericks','nuggets','pistons','warriors','rockets','pacers','clippers','lakers','grizzlies','heat','bucks','timberwolves','pelicans','knicks','thunder','magic','sixers','suns','blazers','kings','spurs','raptors','jazz','wizards']
    teams.each do |t|
      response = HTTParty.get("http://data.nba.net/json/cms/noseason/team/#{t}/roster.json")
      teamName = response['sports_content']['roster']['team']['team_city'] + " " + response['sports_content']['roster']['team']['team_nickname']
      response['sports_content']['roster']['players']['player'].each do |p|
        name = p['first_name'] +" "+ p['last_name']
        name = name.strip.gsub(/'/, '')
        if Player.where(name: name).where(team: teamName).length == 0
          Player.create(name: name, team: teamName, position: p['position_short'], years: p['years_pro'])
        end
      end
    end
  end
  #
  # def self.add_years_to_existing_players
  #   teams = ['hawks','celtics','nets','hornets','bulls','cavaliers','mavericks','nuggets','pistons','warriors','rockets','pacers','clippers','lakers','grizzlies','heat','bucks','timberwolves','pelicans','knicks','thunder','magic','sixers','suns','blazers','kings','spurs','raptors','jazz','wizards']
  #   teams.each do |t|
  #     response = HTTParty.get("http://data.nba.net/json/cms/noseason/team/#{t}/roster.json")
  #     teamName = response['sports_content']['roster']['team']['team_city'] + " " + response['sports_content']['roster']['team']['team_nickname']
  #     response['sports_content']['roster']['players']['player'].each do |p|
  #       name = p['first_name'] +" "+ p['last_name']
  #       name = name.strip
  #       player = Player.where(name: name).where(team: teamName)
  #       if player.length > 0
  #         player.first.update_attributes(years: p['years_pro'])
  #       end
  #     end
  #   end
  # end

  def self.import_headshots
    Player.all.each do |p|
      lastName = p.last_name.split(" ").join("_").downcase
      firstName = p.first_name.downcase
      p lastName + "/" + firstName
      url = "https://nba-players.herokuapp.com/players/#{lastName}/#{firstName}"
      response = HTTParty.get(url, :verify => false)
      p response.body
      if response.body != "Sorry, that player was not found. Please check the spelling."
        p.update_attributes(headshot: url)
      else
        p.update_attributes(headshot: "/avatar.png")
      end
    end
  end

  def first_name
    return self.name.split(" ")[0]
  end

  def last_name
    return self.name.split(" ").drop(1).join(" ")
  end
end
