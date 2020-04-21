-- Author : Mridul Singh
-- Paddle Class
-- Represents a paddle that can move up and down. Used in 
-- the main program to deflect the ball back toward the opponent

Paddle = Class{}

-- The init function is called just once, when the object is first created
function Paddle:init(x, y, width, height)
    self.x = x -- x coordinate
    self.y = y -- y coordinate
    self.width = width -- width of the paddle
    self.height = height -- height of the paddle
    self.dy = 0 -- initial velocity
end

function Paddle:update(dt)
    --math.max ensures that we're the greater of 0 or the player's
    --current calculated Y position when pressing up so that we don't 
    --go into the negatives;
    if self.dy < 0 then
        self.y = math.max(0, self.y + self.dy * dt)

    --ensuring the paddle doesn't go below the window
    else
        self.y = math.min(VIRTUAL_HEIGHT - self.height, self.y + self.dy * dt)
    end
end

--It will be called by ourn main function in 'love.draw'
function Paddle:render()
    love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end
