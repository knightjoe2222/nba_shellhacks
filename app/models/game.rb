class Game < ApplicationRecord
  belongs_to :player
  has_many :links
  include HTTParty
  include Nokogiri
  include Byebug
  def self.import_games
    Player.all.each do |p|
      puts "Working on: #{p.name}"

      # Array that will hold top 15 games by game_score
      finalGames = []

      # Populate yearsArr with years the player has played. E.g. ["2018","2017",...]
      yearsArr = []
      numSeasons = p.years
      it = 0
      while numSeasons > 0
        yearsArr.push((Time.now - it*31557600).strftime("%Y"))
        numSeasons -= 1
        it+=1
      end

      #loop through each year
      yearsArr.each do |y|
        # define URL for that year
        url = "https://www.basketball-reference.com/players/#{p.bballRefUrl}/gamelog/#{y}/"
        puts url
        response = HTTParty.get(url, :verify => false)
        parsed = Nokogiri::HTML(response.body)
        byebug

        # array that stores every game in season
        games = []

        # loop over games in regular season
        i = 0
        while i < 86
          row = parsed.css("#pgl_basic tbody tr")[i]
          reason = row.css("td[data-stat='reason']")[0]
          headerRow = row.css("th[aria-label='Rank']")[0]
          if !reason && !headerRow # If the row has stats in it (the player played) and it's not a heading row
            boxScoreUrl = "https://www.basketball-reference.com" + row.css("td[data-stat='date_game']")[0].children[0]['href']
            date = row.css("td[data-stat='date_game']")[0].text
            opponent = row.css("td[data-stat='opp_id']")[0].text
            score = row.css("td[data-stat='game_result']")[0].text
            minutes = row.css("td[data-stat='mp']")[0].text
            fgma = row.css("td[data-stat='fg']")[0].text + "-" + row.css("td[data-stat='fga']")[0].text
            rebounds = row.css("td[data-stat='trb']")[0].text
            assists = row.css("td[data-stat='ast']")[0].text
            steals =  row.css("td[data-stat='stl']")[0].text
            blocks =  row.css("td[data-stat='blk']")[0].text
            turnovers =  row.css("td[data-stat='tov']")[0].text
            points = row.css("td[data-stat='pts']")[0].text
            metric = row.css("td[data-stat='game_score']")[0].text
            game = Game.new(date: date, opponent: opponent, score: score, minutes: minutes, fgma: fgma, rebounds: rebounds, assists: assists, steals: steals, blocks: blocks, turnovers: turnovers, points: points, metric: metric, player_id: p.id)
            games << game
          else
            puts "Did not Play/Header Row"
          end
          i += 1
        end

        # loop through playoff games, append to games

        i = 0
        while i < 16
          i += 1
        end
        # if y == '2018'
          # sort games by game_score
          # cut array at position 15
          # continue loop (i.e. go to year 2017)
        # elsif any other year
          # sort games by game_score
        # end



      end

    end
  end

  def self.import_urls #doesn't catch 29 of 464 players due to nicknames/weird URLs on BR's side. Still works. eg: Adds "a/anderju01" to Justin Anderson

    Player.all.each do |p|
      if p.bballRefUrl
        next
      end
      i = 0
      playerUrl = ""
      puts "Working on: #{p.name}"
      # define it to use as number in URL if name is taken
      it = 1
      # fetch the guess URL from the player's model
      url = p.bballRefURL("2018", it)
      # get the ballref page
      response = HTTParty.get(url, :verify => false)
      # parse the response with Nokogiri
      parsed = Nokogiri::HTML(response.body)
      # define the number of words in player's name
      words_in_name = p.name.gsub(/Jr./, '').gsub(/III/, '').gsub(/II/, '').gsub(/IV/, '').split(" ").length
      # fetch the same number of words from header from bballref
      name_from_response = parsed.css('h1[itemprop=name]').text.split(" ")[0..words_in_name-1].join(" ")
      # while the player's name in our DB != the player's name from BBallRef, increment it and try again.
      if p.name.gsub(/Jr./, '').gsub(/III/, '').gsub(/II/, '').gsub(/IV/, '').strip == name_from_response
        puts "Found #{p.name}'s BBall Ref Page: #{url}"
        playerUrl = url
        puts "Final #{p.name} URL: #{playerUrl.gsub(/https:\/\/www.basketball-reference.com\/players\//,'').gsub(/\/gamelog\/2018\//,'')}"
        p.update_attributes(bballRefUrl: playerUrl.gsub(/https:\/\/www.basketball-reference.com\/players\//,'').gsub(/\/gamelog\/2018\//,''))
        next
      else
        puts "Did not find #{p.name}'s BBall Ref Page. Tried: #{url} | Compared: #{p.name.gsub(/Jr./, '').gsub(/III/, '').gsub(/II/, '').gsub(/IV/, '').strip} to #{name_from_response}"
        while true
          it += 1
          url = p.bballRefURL("2018", it)
          response = HTTParty.get(url, :verify => false)
          parsed = Nokogiri::HTML(response.body)
          words_in_name = p.name.gsub(/Jr./, '').gsub(/III/, '').gsub(/II/, '').gsub(/IV/, '').split(" ").length
          name_from_response = parsed.css('h1[itemprop=name]').text.split(" ")[0..words_in_name-1].join(" ")
          if p.name.gsub(/Jr./, '').gsub(/III/, '').gsub(/II/, '').gsub(/IV/, '').strip == name_from_response
            puts "Found #{p.name}'s BBall Ref Page: #{url}"
            playerUrl = url
            break
          else
            puts "Did not find #{p.name}'s BBall Ref Page. Tried: #{url} | Compared: #{p.name.gsub(/Jr./, '').gsub(/III/, '').gsub(/II/, '').gsub(/IV/, '').strip} to #{name_from_response}"
          end
          i += 1
          if i == 5
            puts "Went thru 5 iterations, did not get a hit."
            break
          end
        end
        # I am sorry for how ugly this code is but it's called a HACKathon for a reason.
        puts "Final #{p.name} URL: #{playerUrl.gsub(/https:\/\/www.basketball-reference.com\/players\//,'').gsub(/\/gamelog\/2018\//,'')}"
        p.update_attributes(bballRefUrl: playerUrl.gsub(/https:\/\/www.basketball-reference.com\/players\//,'').gsub(/\/gamelog\/2018\//,''))
      end
    end
  end

end
