-- Pong in Lua
-- Author: Mridul Singh 

-- push is a library that will allow us to draw our game at a virtual 
-- resolution, instead of however large our window is; used to provide a more
-- retro aesthetic

push = require 'push'

--class is a library that helps us to use classes in our game
Class = require 'class'

-- our paddle class 
require 'Paddle'

-- our ball class
require 'Ball'

WINDOW_WIDTH = 1280 --width of game window
WINDOW_HEIGHT = 720 --height of game window

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- speed at which we will move our paddle; multiplied by dt in update
PADDLE_SPEED = 200

--[[Runs when the game first starts up, only once; used to initialise the game]]
--
function love.load()
    --use nearest-neighbour filtering on upscaling and downscaling to prevent blurring of text
    --and graphics ;
    love.graphics.setDefaultFilter('nearest', 'nearest')

    -- set the title of our application window
    love.window.setTitle('Pong')


    --"seed" the RNG so that calls to random are always random
    --use the current time, since that will vary on startup everytime
    math.randomseed(os.time())

    -- more "retro-looking " font object we can use for any  text
    smallFont = love.graphics.newFont('font.ttf', 8)

    -- another font for printing the winner
    largeFont = love.graphics.newFont('font.ttf', 16)

    -- larger font for drawing the score on the screen
    scoreFont = love.graphics.newFont('font.ttf', 32)

    --set Love2Ds active font to the smallfont object
    love.graphics.setFont(smallFont)

    --set up our sound effects; later, we can just index this table and
    --call each entry's 'play' method
    sounds = {
        ['paddle_hit'] = love.audio.newSource('sounds/paddle_hit.wav', 'static'),
        ['score'] = love.audio.newSource('sounds/score.wav', 'static'),
        ['wall_hit'] = love.audio.newSource('sounds/wall_hit.wav', 'static')
    }

    --initialize our virtual resolution, which will be rendered within our
    --actual window no matter its dimensions; replaces our love.window.setMode call
    --from the last example
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false, -- game window not fullscreen
        resizable = true, -- game window not resizable
        vsync = true -- sync of game with monitor is on
    })

    -- initialize the score variables, used for rendering on the screen and keeping
    -- track of the winner
    player1Score = 0
    player2Score = 0

    -- set whose turn is it to serve
    servingPlayer = 1

    --initialize our player paddles; make them global so they can be
    --detected by other functions and modules
    player1 = Paddle(10, 30, 5, 20)
    player2 = Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    --place a ball in the middle of the screen
    ball = Ball(VIRTUAL_WIDTH/2 - 2, VIRTUAL_HEIGHT/2 - 2, 4, 4)


    --game state variable used to transition between different parts of the game
    --(used for beginning, menus, main game, high score, list, etc.)
    --we will use this to determine behaviour during render and update
    gameState = 'start'
end

-- Called by LOVE whenever we resize the screen; here, we just want to pass in the
-- width and the height to push so our virtual resoulution can be resized as needed
function love.resize(w, h)
    push:resize(w, h)
end


--[[
--Runs every frame, with "dt" passed in, our delta in seconds
--since the last frame, which LOVE2D supplies us
--]]
--
--
function love.update(dt)

    if gameState == 'serve' then
        -- before switching to play, inititalize ball's velocity based
        -- on player who last scored
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then
            ball.dx = math.random(140, 200)
        else 
            ball.dx = -math.random(140, 200)
        end

    elseif gameState == 'play' then
        --detect ball collision with paddles, reversing dx if true
        --slightly increasing it, then altering the dy based on the position of collision
        if ball:collides(player1) then
            ball.dx = -ball.dx * 1.03
            ball.x = player1.x + 5

            --keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else 
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()

        end

        if ball:collides(player2) then
            ball.dx = -ball.dx * 1.03
            ball.x = player2.x - 5

            --keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then
                ball.dy = -math.random(10, 150)
            else 
                ball.dy = math.random(10, 150)
            end

            sounds['paddle_hit']:play()
        end

        --detect upper and lower screen boundary collision and reverse if collided
        if ball.y <= 0 then
            ball.y = 0
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end

        --- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = -ball.dy
            sounds['wall_hit']:play()
        end


        -- if we reach the left or right edge of the screen
        -- go back to start and update the score
        if ball.x < 0 then
            servingPlayer = 1
            player2Score = player2Score + 1
            sounds['score']:play()

            --checking if we have got a winner
            if player2Score == 10 then
                winningPlayer = 2
                gameState = 'done'
            else 
                gameState = 'serve'
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1
            sounds['score']:play()

            --checking if player1 won
            if player1Score == 10 then
                winningPlayer = 1
                gameState = 'done'
            else
                ball:reset()
                gameState = 'serve'
            end
        end
end   

    --player1 movement
    if love.keyboard.isDown('w') then
        --add negative paddle speed to current Y scaled by deltTime
        --ensuring that we don't go above the window
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
        --add positive paddle speed to current Y scaled by deltaTime
        --ensuring we don't go below the window
        player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    --player2 movement
    if love.keyboard.isDown('up') then
        --add negative paddle speed to current Y scaled by deltTime
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then
        --add positive paddle speed to current Y scaled by deltaTime
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    --update our based on its DX and DY only if we are in play state
    --scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then
        ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end



--[[Keyboard Handling, called by Love2D each frame;
--passes in the key we pressed, so we can access]]
--
function love.keypressed(key)
    --keys can be accessed by string name
    if key == 'escape' then
        -- function LOVE gives us to terminate application
        love.event.quit()

    --if we press enter during the start state of the game, we'll go into play mode
    --during play mode, the ball will move in a random direction
    elseif key == 'enter' or key == 'return' then
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then
            -- game is play in a restart phase here, but will set the serving
            -- player to the opponent of whomever won for fairness!
            gameState = 'serve'
            ball:reset()

            --reset scores to 0
            player1Score = 0
            player2Score = 0

            --decide serving player as the opposite of who won
            if winningPlayer == 1 then
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end

--[[Called after update by LOVE2D, used to draw anything to screen,
updated or otherwise]]

function love.draw()
    --begin rendering at virtual resolution
    push:apply('start')

    --clear the screen with a specific color; in this case a color similar 
    --to some versions of the orignial Pong
    love.graphics.clear(40/255,45/255,52/255, 255/255)

    --draw welcome text toward the top of the screen
    love.graphics.setFont(smallFont)

    displayScore()
    
    if gameState == 'start' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        --no UI messages to display in play
    elseif gameState == 'done' then
        -- UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. 'wins', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end

   --render paddles
    player1:render()
    player2:render()

    --render ball
    ball:render()

    -- display the FPS value
    displayFPS()

    --end rendering at virtual resolution
    push:apply('end')
end

-- Renders the current FPS
function displayFPS()
    --simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0,255,0,255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

-- Simply draws the score to the screen
function displayScore()
    -- draw score on the left and right center of the screen
    -- need to switch font to draw before actually printing
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH/2 - 50, VIRTUAL_HEIGHT/3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH/2 + 30, VIRTUAL_HEIGHT/3)
end
