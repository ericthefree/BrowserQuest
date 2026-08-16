
define(['jquery', 'area'], function($, Area) {
    
    var Map = Class.extend({
        init: function(loadMultiTilesheets, game) {
            this.game = game;
        	this.data = [];
        	this.isLoaded = false;
        	this.tilesetsLoaded = false;
        	this.mapLoaded = false;
        	this.loadMultiTilesheets = loadMultiTilesheets;
        	
        	var useWorker = !(this.game.renderer.mobile || this.game.renderer.tablet);

        	this._loadMap(useWorker);
        	this._initTilesets();
        },
        
        _checkReady: function() {
            if(this.tilesetsLoaded && this.mapLoaded) {
                this.isLoaded = true;
                if(this.ready_func) {
        	    	this.ready_func();
        	    }
        	}
        },

        _loadMap: function(useWorker) {
        	var self = this,
        	    filepath = "maps/world_client.json";
        	
        	if(useWorker) {
        	    log.info("Loading map with web worker.");
                var worker = new Worker('js/mapworker.js');
                worker.postMessage(1);
            
                worker.onmessage = function(event) {
                    var map = event.data;
                    self._initMap(map);
                    self.grid = map.grid;
                    self.plateauGrid = map.plateauGrid;
                    self.mapLoaded = true;
                    self._checkReady();
                };
            } else {
                log.info("Loading map via Ajax.");
                $.get(filepath, function (data) {
                    self._initMap(data);
                    self._generateCollisionGrid();
                    self._generatePlateauGrid();
                    self.mapLoaded = true;
                    self._checkReady();
                }, 'json');
            }        
        },
        
        _initTilesets: function() {
            var tileset1, tileset2, tileset3;
            
            if(!this.loadMultiTilesheets) {
                this.tilesetCount = 1;
                tileset1 = this._loadTileset('img/1/tilesheet.png');
            } else {
                if(this.game.renderer.mobile || this.game.renderer.tablet) {
                    this.tilesetCount = 1;
                    tileset2 = this._loadTileset('img/2/tilesheet.png');
                } else {
                    this.tilesetCount = 2;
                    tileset2 = this._loadTileset('img/2/tilesheet.png');
                    tileset3 = this._loadTileset('img/3/tilesheet.png');
                }
            }
        
            this.tilesets = [tileset1, tileset2, tileset3];
        },

        _initMap: function(map) {
            this.width = map.width;
            this.height = map.height;
            this.tilesize = map.tilesize;
            this.data = map.data;
            this.blocking = map.blocking || [];
            this.plateau = map.plateau || [];
            this.musicAreas = map.musicAreas || [];
            this.collisions = map.collisions;
            this.high = map.high;
            this.animated = map.animated;
            
            this.doors = this._getDoors(map);
            this.checkpoints = this._getCheckpoints(map);
        },
    
        _getDoors: function(map) {
            var doors = {},
                self = this;

            _.each(map.doors, function(door) {
                var o;
                
                switch(door.to) {
                    case 'u': o = Types.Orientations.UP;
                        break;
                    case 'd': o = Types.Orientations.DOWN;
                        break;
                    case 'l': o = Types.Orientations.LEFT;
                        break;
                    case 'r': o = Types.Orientations.RIGHT;
                        break;
                    default : o = Types.Orientations.DOWN;
                }
                
                doors[self.GridPositionToTileIndex(door.x, door.y)] = {
                    x: door.tx,
                    y: door.ty,
                    orientation: o,
                    cameraX: door.tcx,
                    cameraY: door.tcy,
                    portal: door.p === 1,
                };
            });
        
            return doors;
        },

        _loadTileset: function(filepath) {
        	var self = this;
    	    var tileset = new Image();
    	
        	tileset.src = filepath;
    
            log.info("Loading tileset: "+filepath);
    
        	tileset.onload = function() {
                if(tileset.width % self.tilesize > 0) {
                    throw Error("Tileset size should be a multiple of "+ self.tilesize);
                }
                log.info("Map tileset loaded.");
            
                self.tilesetCount -= 1;
                if(self.tilesetCount === 0) {
                    log.debug("All map tilesets loaded.")
                    
            		self.tilesetsLoaded = true;
            		self._checkReady();
            	}
        	};
    	
        	return tileset;
        },

        ready: function(f) {
        	this.ready_func = f;
        },

        tileIndexToGridPosition: function(tileNum) {
            var x = 0,
                y = 0;
        
            var getX = function(num, w) {
                if(num == 0) {
                    return 0;
                }
                return (num % w == 0) ? w - 1 : (num % w) - 1;
            }
    
            tileNum -= 1;
            x = getX(tileNum + 1, this.width);
            y = Math.floor(tileNum / this.width);
    
            return { x: x, y: y };
        },

        GridPositionToTileIndex: function(x, y) {
            return (y * this.width) + x + 1;
        },

        isColliding: function(x, y) { 
            if(this.isOutOfBounds(x, y) || !this.grid) {
                return false;
            }
            return (this.grid[y][x] === 1);
        },
    
        isPlateau: function(x, y) { 
            if(this.isOutOfBounds(x, y) || !this.plateauGrid) {
                return false;
            }
            return (this.plateauGrid[y][x] === 1);
        },
        
        _generateCollisionGrid: function() {
            var tileIndex = 0,
                self = this;

            this.grid = [];
            for(var	j, i = 0; i < this.height; i++) {
                this.grid[i] = [];
                for(j = 0; j < this.width; j++) {
                    this.grid[i][j] = 0;
                }
            }

            _.each(this.collisions, function(tileIndex) {
                var pos = self.tileIndexToGridPosition(tileIndex+1);
                self.grid[pos.y][pos.x] = 1;
            });

            _.each(this.blocking, function(tileIndex) {
                var pos = self.tileIndexToGridPosition(tileIndex+1);
                if(self.grid[pos.y] !== undefined) {
                    self.grid[pos.y][pos.x] = 1;
                }
            });
            log.info("Collision grid generated.");
        },

        _generatePlateauGrid: function() {
            var tileIndex = 0;

            this.plateauGrid = [];
            for(var	j, i = 0; i < this.height; i++) {
                this.plateauGrid[i] = [];
                for(j = 0; j < this.width; j++) {
                    if(_.include(this.plateau, tileIndex)) {
                        this.plateauGrid[i][j] = 1;
                    } else {
                        this.plateauGrid[i][j] = 0;
                    }
                    tileIndex += 1;
                }
            }
            log.info("Plateau grid generated.");
        },
    
        /**
         * Returns true if the given position is located within the dimensions of the map.
         *
         * @returns {Boolean} Whether the position is out of bounds.
         */
        isOutOfBounds: function(x, y) {
            return isInt(x) && isInt(y) && (x < 0 || x >= this.width || y < 0 || y >= this.height);
        },

        /**
         * Determines which tiles, bounded to [minX,maxX]x[minY,maxY], should
         * be drawn given the player is standing at (startX, startY). Used so
         * a wide camera never draws terrain from a different, disconnected
         * area of the map (e.g. an unrelated building's interior) that
         * happens to fall within the camera's tile range but isn't actually
         * part of the same space the player is in.
         *
         * Flood-fills from the player through orthogonally-adjacent
         * non-empty tiles, treating doors as the only barrier: crossing a
         * door is a teleport, not a continuous walk, so whatever sits
         * beyond one in raw map coordinates is a different, unrelated area,
         * and the door itself is marked reachable (so its archway still
         * draws) without being a tile the fill continues through.
         *
         * Deliberately not collision-based — walkability seems like the
         * obvious way to define a room's boundary, but it isn't: outdoor
         * terrain routinely has walkable ground that's only reachable via a
         * detour (the far bank of a pond, the other side of a bridge), and
         * unwalkable decoration (cliffs, wide obstacles) that's several
         * tiles deep. Both are real, visible, connected scenery that a
         * walkability-only fill would wrongly hide. Raw tile data being
         * non-empty is a much better proxy for "this is part of the same
         * drawn space" — the only thing that actually needs to act as a
         * hard boundary is a door.
         *
         * Returns a map of tile-index -> true for every reachable tile, or
         * null if the starting position is out of bounds (caller should
         * then skip filtering and draw everything in range).
         */
        computeReachableRegion: function(startX, startY, minX, minY, maxX, maxY) {
            var self = this,
                reachable = {},
                seen = {},
                queue = [[startX, startY]],
                deltas = [[1,0],[-1,0],[0,1],[0,-1]];

            function tileIndexAt(x, y) {
                return self.GridPositionToTileIndex(x, y) - 1;
            }

            function isEmptyTile(x, y) {
                if(self.isOutOfBounds(x, y)) {
                    return true;
                }
                return !self.data[tileIndexAt(x, y)];
            }

            if(self.isOutOfBounds(startX, startY)) {
                return null;
            }

            seen[startX+','+startY] = true;
            reachable[tileIndexAt(startX, startY)] = true;

            while(queue.length > 0) {
                var pos = queue.shift(),
                    x = pos[0],
                    y = pos[1];

                for(var i = 0; i < deltas.length; i++) {
                    var nx = x + deltas[i][0],
                        ny = y + deltas[i][1];

                    if(nx < minX || nx > maxX || ny < minY || ny > maxY) {
                        continue;
                    }

                    var key = nx+','+ny;
                    if(seen[key]) {
                        continue;
                    }
                    seen[key] = true;

                    if(isEmptyTile(nx, ny)) {
                        continue;
                    }

                    reachable[tileIndexAt(nx, ny)] = true;

                    if(!self.isDoor(nx, ny)) {
                        queue.push([nx, ny]);
                    }
                }
            }

            return reachable;
        },

        /**
         * Returns true if the given tile id is "high", i.e. above all entities.
         * Used by the renderer to know which tiles to draw after all the entities 
         * have been drawn.
         *
         * @param {Number} id The tile id in the tileset
         * @see Renderer.drawHighTiles
         */
        isHighTile: function(id) {
            return _.indexOf(this.high, id+1) >= 0;
        },
    
        /**
         * Returns true if the tile is animated. Used by the renderer.
         * @param {Number} id The tile id in the tileset
         */
        isAnimatedTile: function(id) {
            return id+1 in this.animated;
        },
    
        /**
         * 
         */
        getTileAnimationLength: function(id) {
            return this.animated[id+1].l;
        },
    
        /**
         * 
         */
        getTileAnimationDelay: function(id) {
            var animProperties = this.animated[id+1];
            if(animProperties.d) {
                return animProperties.d;
            } else {
                return 100;
            }
        },
    
        isDoor: function(x, y) {
            return this.doors[this.GridPositionToTileIndex(x, y)] !== undefined;
        },
    
        getDoorDestination: function(x, y) {
            return this.doors[this.GridPositionToTileIndex(x, y)];
        },

        _getCheckpoints: function(map) {
            var checkpoints = [];
            _.each(map.checkpoints, function(cp) {
                var area = new Area(cp.x, cp.y, cp.w, cp.h);
                area.id = cp.id;
                checkpoints.push(area);
            });
            return checkpoints;
        },
    
        getCurrentCheckpoint: function(entity) {
            return _.detect(this.checkpoints, function(checkpoint) {
                return checkpoint.contains(entity);
            });
        }
    });
    
    return Map;
});
