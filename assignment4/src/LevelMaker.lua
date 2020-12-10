--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND

    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- if key and keyblock have already been spawned
    local keySpawned = false
    local keyblockSpawned = false
    local keyColour = math.random(#KEYS)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        --if x >= math.floor(width/3) and not keySpawned and (math.random(33) == 1 or x == math.floor(2*width/3)) then
        if x == 3 then
            keySpawnCheck = true
        --elseif x >= math.floor(7*width/10) and not keyblockSpawned and (math.random(33) == 1  or x == math.floor(17*width/20)) then
        elseif x == 5 then
            tileSpawnCheck = true
        else
            keySpawnCheck, tileSpawnCheck = false
        end

        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        if math.random(7) == 1 and x ~= 1 and (x < width-3) and not (keySpawnCheck or tileSpawnCheck) then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 and x < width - 3 then
                blockHeight = 2

                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,

                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7
                        }
                    )
                end

                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil

            -- chance to generate bushes
            elseif math.random(8) == 1 and (x < width-3) then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn key if atleast 33% through the level
            
            if keySpawnCheck then
                table.insert(objects,
                    GameObject {
                        texture = 'keys_and_locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = keyColour,
                        collidable = true,
                        solid = false,
                        consumable = true,

                        onConsume = function(player, object)
                            gSounds['pickup']:play()
                            player.keyPickedUp = true
                        end
                    }
                )
                keySpawned = true

            
            elseif tileSpawnCheck then
                table.insert(objects,
                    GameObject {
                        texture = 'keys_and_locks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = keyColour + 4,
                        collidable = true,
                        hit = false,
                        solid = true,
                        consumable = true,
                        removed = false,

                        onCollide = function(player, object)
                            if player.keyPickedUp and not object.hit then
                                player.keyblockHit = true
                                object.removed = true
                                gSounds['powerup-reveal']:play()
                                
                                table.insert(objects,
                                    GameObject{
                                        texture = 'flags',
                                        x = (x - 3) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE,
                                        width = 16,
                                        height = 48,
                                        frame = math.random(#FLAG_POLES),
                                        collidable = true,
                                        solid = true,

                                        onCollide = function(player,object)
                                            
                                        end
                                    }
                                )

                                table.insert(objects,
                                    GameObject{
                                        texture = 'flags',
                                        x = (x - 3) * TILE_SIZE + 8,
                                        y = (blockHeight - 1) * TILE_SIZE + 6,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#FLAGS) * 3 + 4
                                    }
                                )
                            else
                                gSounds['empty-block']:play()
                            end
                        end
                    }
                )
                keyblockSpawned = true

            -- chance to spawn a block
            elseif math.random(10) == 1 and (x < width - 3) and (x > 2)then
                table.insert(objects,
                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(object)

                            -- spawn a gem if we haven't already hit the block
                            if not object.hit then
                                object.hit = true

                                -- chance to spawn gem, not guaranteed
                                if math.random(4) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }

                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles

    return GameLevel(entities, objects, map)
end