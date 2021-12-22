Team = require "Team"
Player = require "Player"

team1 = Team:new("Hornets")
team1:scored(10)
team1:scored(3)

playerJohn = Player:new("John")
team1:addPlayer(playerJohn)

team1:tostring()

print(math.rad(180) - math.rad(181))
