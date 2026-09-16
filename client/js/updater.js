
define(['character', 'timer'], function(Character, Timer) {

    var Updater = Class.extend({
        init: function(game) {
            this.game = game;
            this.playerAggroTimer = new Timer(1000);
        },

        update: function() {
            this.updateZoning();
            this.updateCharacters();
            this.updatePlayerAggro();
            this.updateTransitions();
            this.updateAnimations();
            this.updateAnimatedTiles();
            this.updateChatBubbles();
            this.updateInfos();
        },

        updateCharacters: function() {
            var self = this;
        
            this.game.forEachEntity(function(entity) {
                var isCharacter = entity instanceof Character;
            
                if(entity.isLoaded) {
                    if(isCharacter) {
                        self.updateCharacter(entity);
                        self.game.onCharacterUpdate(entity);
                    }
                    self.updateEntityFading(entity);
                }
            });
        },
        
        updatePlayerAggro: function() {
            var t = this.game.currentTime,
                player = this.game.player;
            
            // Check player aggro every 1s when not moving nor attacking
            if(player && !player.isMoving() && !player.isAttacking()  && this.playerAggroTimer.isOver(t)) {
                player.checkAggro();
            }
        },
    
        updateEntityFading: function(entity) {
            if(entity && entity.isFading) {
                var duration = 1000,
                    t = this.game.currentTime,
                    dt = t - entity.startFadingTime;
            
                if(dt > duration) {
                    this.isFading = false;
                    entity.fadingAlpha = 1;
                } else {
                    entity.fadingAlpha = dt / duration;
                }
            }
        },

        updateTransitions: function() {
            var self = this,
                m = null,
                z = this.game.currentZoning;
    
            this.game.forEachEntity(function(entity) {
                m = entity.movement;
                if(m) {
                    if(m.inProgress) {
                        m.step(self.game.currentTime);
                    }
                }
            });
        
            if(z) {
                if(z.inProgress) {
                    z.step(this.game.currentTime);
                }
            }
        },
    
        updateZoning: function() {
            var g = this.game,
                c = g.camera,
                z = g.currentZoning,
                s = 3,
                ts = 16,
                speed = 500;
        
            if(z && z.inProgress === false) {
                var orientation = this.game.zoningOrientation,
                    startValue = endValue = offset = 0,
                    updateFunc = null,
                    endFunc = null;
            
                if(orientation === Types.Orientations.LEFT || orientation === Types.Orientations.RIGHT) {
                    offset = (c.gridW - 2) * ts;
                    startValue = (orientation === Types.Orientations.LEFT) ? c.x - ts : c.x + ts;
                    endValue = (orientation === Types.Orientations.LEFT) ? c.x - offset : c.x + offset;
                    updateFunc = function(x) {
                        c.setPosition(x, c.y);
                        g.initAnimatedTiles();
                        g.renderer.renderStaticCanvases();
                    }
                    endFunc = function() {
                        c.setPosition(z.endValue, c.y);
                        g.endZoning();
                    }
                } else if(orientation === Types.Orientations.UP || orientation === Types.Orientations.DOWN) {
                    offset = (c.gridH - 2) * ts;
                    startValue = (orientation === Types.Orientations.UP) ? c.y - ts : c.y + ts;
                    endValue = (orientation === Types.Orientations.UP) ? c.y - offset : c.y + offset;
                    updateFunc = function(y) { 
                        c.setPosition(c.x, y);
                        g.initAnimatedTiles();
                        g.renderer.renderStaticCanvases();
                    }
                    endFunc = function() {
                        c.setPosition(c.x, z.endValue);
                        g.endZoning();
                    }
                }
            
                z.start(this.game.currentTime, updateFunc, endFunc, startValue, endValue, speed);
            }
        },

        updateCharacter: function(c) {
            var tick = Math.round(16 / Math.round((c.moveSpeed / (1000 / this.game.renderer.FPS)))),
                startX,
                startY,
                deltaX,
                deltaY,
                distance,
                duration;

            if(c.isMoving() && c.movement.inProgress === false) {
                startX = c.x;
                startY = c.y;
                deltaX = (c.nextGridX - c.gridX) * 16;
                deltaY = (c.nextGridY - c.gridY) * 16;
                distance = Math.sqrt((deltaX * deltaX) + (deltaY * deltaY));
                duration = c.moveSpeed * (distance / 16);

                c.movement.start(this.game.currentTime,
                                 function(progress) {
                                    c.x = Math.round(startX + (deltaX * progress / 1000));
                                    c.y = Math.round(startY + (deltaY * progress / 1000));
                                    c.hasMoved();
                                 },
                                 function() {
                                    c.x = startX + deltaX;
                                    c.y = startY + deltaY;
                                    c.hasMoved();
                                    c.nextStep();
                                 },
                                 Math.round((tick / 16) * 1000),
                                 1000,
                                 duration);
            }
        },

        updateAnimations: function() {
            var t = this.game.currentTime;
    
            this.game.forEachEntity(function(entity) {
                var anim = entity.currentAnimation;
                
                if(anim) {
                    if(anim.update(t)) {
                        entity.setDirty();
                    }
                }
            });
        
            var sparks = this.game.sparksAnimation;
            if(sparks) {
                sparks.update(t);
            }
    
            var target = this.game.targetAnimation;
            if(target) {
                target.update(t);
            }
        },
    
        updateAnimatedTiles: function() {
            var self = this,
                t = this.game.currentTime;
        
            this.game.forEachAnimatedTile(function (tile) {
                if(tile.animate(t)) {
                    tile.isDirty = true;
                    tile.dirtyRect = self.game.renderer.getTileBoundingRect(tile);

                    if(self.game.renderer.mobile || self.game.renderer.tablet) {
                        self.game.checkOtherDirtyRects(tile.dirtyRect, tile, tile.x, tile.y);
                    }
                }
            });
        },
    
        updateChatBubbles: function() {
            var t = this.game.currentTime;
        
            this.game.bubbleManager.update(t);
        },
    
        updateInfos: function() {
            var t = this.game.currentTime;
        
            this.game.infoManager.update(t);
        }
    });
    
    return Updater;
});
