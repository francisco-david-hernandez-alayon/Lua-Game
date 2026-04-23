# LUA GAME IN LOVE FRAMEWORK
*Author: Francisco David Hernández Alayón*


## Gameplay structure
### Create new Game
```
PlayMenu → Game.new({ name, slot, gameState }): Create new Game
         → world_game_data.buildWorldData(): get world data from world_data folder
         → game.worldData = { npcs={...}, objects={...}, doors={...} }
         → GameController.load(game): load current game in GameController
         → sm.switch(game.gameState): switch to Current Game State
```

### Save Game
```
SaveSystem.save(slot, game)
  → game:toTable(): serialize
    ├── basic game data name, slot, created_at...
    ├── playerX, playerY, gameState
    ├── inventory:toTable()
    └── worldData → utils/game_serializer.serializeWorldData(worldData)
                    ├── WorldNpc  → { id, mapState, visible, interactEnabled, optionStates }: data that cannot be changed during the game
                    ├── WorldObject → { id, mapState, visible, picked }: data that cannot be changed during the game
                    └── WorldDoor   → { id, mapState, visible, open }: data that cannot be changed during the game
  → json.encode → save_slot_N.json
```

### Load Game
```
SaveSystem.load(slot)
  → json.decode → decoded table: deserialize
  → Game.new(decoded)
    ├── basic game data name
    ├── inventory = PlayerInventory.fromTable(data.inventory)
    └── worldData = utils/game_serializer.deserializeWorldData(data.worldData)
                    ├── WorldNpc  → world_game_data.getNpcById(id) 
                    ├── WorldObject → world_game_data.getObjectById(id) 
                    └── WorldDoor   → world_game_data.getDoorById(id) 
  → GameController.load(game): load current game in GameController
  → sm.switch(game.gameState): switch to Current Game State
```

### Load state(each game map)
```
MapTest.enter()
  → GameController.getWorldDataForState("map_test"): get all world_data from the state
  → MapLoader.load(mapPath, npcs, objects, doors): load tile map with all this data
    ├── buildWorldTileMap → apply colliders using Box2D
    ├── resolvePositions  → asign x,y from tiled to each element
    └── returns map, world, spawn, worldData
  → GameController.resolveStartPosition → startX, startY: get player spawn in the state
  → PlayerController.new(world, {x=startX, y=startY}): create player controller
  → door:checkSpawnProximity(startX, startY): Check all the doors in the state to prevent the player from re-entering through the door they came in through
```


### _lists folders
Folders ending in '_list' are used to store definitions of the game’s static data, including core content such as missions, NPCs, items, etc. These files act as centralised records that define the basic information and settings for each system, which are subsequently loaded and used throughout the game.


## Execution
### Windows
Run project from the current folder:

```bash
& "C:\Program Files\LOVE\love.exe" .
```

*Debug*
```bash
& "C:\Program Files\LOVE\love.exe" . *>&1 | Tee-Object -FilePath debug_console.txt
```