
define(['jquery', 'app'], function($, App) {
    var app, game;

    var initApp = function() {
        $(document).ready(function() {
        	app = new App();
            app.center();
        
            if(Detect.isWindows()) {
                // Workaround for graphical glitches on text
                $('body').addClass('windows');
            }
            
            if(Detect.isOpera()) {
                // Fix for no pointer events
                $('body').addClass('opera');
            }
        
            $('body').click(function(event) {
                if($('#parchment').hasClass('credits')) {
                    app.toggleCredits();
                }
                
                if($('#parchment').hasClass('about')) {
                    app.toggleAbout();
                }
            });
	
        	$('.barbutton').click(function() {
        	    $(this).toggleClass('active');
        	});
	
        	$('#chatbutton').click(function() {
        	    if($('#chatbutton').hasClass('active')) {
        	        app.showChat();
        	    } else {
                    app.hideChat();
        	    }
        	});
	
        	$('#helpbutton').click(function() {
                app.toggleAbout();
        	});
	
        	$('#achievementsbutton').click(function() {
                app.toggleAchievements();
                if(app.blinkInterval) {
                    clearInterval(app.blinkInterval);
                }
                $(this).removeClass('blink');
        	});
	
        	$('#instructions').click(function() {
                app.hideWindows();
        	});
        	
        	$('#playercount').click(function() {
        	    app.togglePopulationInfo();
        	});
        	
        	$('#population').click(function() {
        	    app.togglePopulationInfo();
        	});
	
        	$('.clickable').click(function(event) {
                event.stopPropagation();
        	});
	
        	$('#toggle-credits').click(function() {
        	    app.toggleCredits();
        	});
	
        	$('#create-new span').click(function() {
        	    app.animateParchment('loadcharacter', 'confirmation');
        	});
	
        	$('.delete').click(function() {
                app.storage.clear();
        	    app.animateParchment('confirmation', 'createcharacter');
        	});
	
        	$('#cancel span').click(function() {
        	    app.animateParchment('confirmation', 'loadcharacter');
        	});
        	
        	$('.ribbon').click(function() {
        	    app.toggleAbout();
        	});

            $('#nameinput').on("keyup", function() {
                app.toggleButton();
            });
    
            $('#previous').click(function() {
                var $achievements = $('#achievements');
        
                if(app.currentPage === 1) {
                    return false;
                } else {
                    app.currentPage -= 1;
                    $achievements.removeClass().addClass('active page' + app.currentPage);
                }
            });
    
            $('#next').click(function() {
                var $achievements = $('#achievements'),
                    $lists = $('#lists'),
                    nbPages = $lists.children('ul').length;
        
                if(app.currentPage === nbPages) {
                    return false;
                } else {
                    app.currentPage += 1;
                    $achievements.removeClass().addClass('active page' + app.currentPage);
                }
            });

            $('#notifications div').on(TRANSITIONEND, app.resetMessagesPosition.bind(app));
    
            $('.close').click(function() {
                app.hideWindows();
            });
        
            $('.twitter').click(function() {
                var url = $(this).attr('href');

               app.openPopup('twitter', url);
               return false;
            });

            $('.facebook').click(function() {
                var url = $(this).attr('href');

               app.openPopup('facebook', url);
               return false;
            });
        
            var data = app.storage.data;
    		if(data.hasAlreadyPlayed) {
    		    if(data.player.name && data.player.name !== "") {
		            $('#playername').html(data.player.name);
    		        $('#playerimage').attr('src', data.player.image);
    		    }
    		}
    		
    		$('.play div').click(function(event) {
                var nameFromInput = $('#nameinput').val(),
                    nameFromStorage = $('#playername').html(),
                    name = nameFromInput || nameFromStorage;
                
                app.tryStartingGame(name);
            });
        
            document.addEventListener("touchstart", function() {},false);
            
            $('#resize-check').on("transitionend", app.resizeUi.bind(app));
            $('#resize-check').on("webkitTransitionEnd", app.resizeUi.bind(app));
            $('#resize-check').on("oTransitionEnd", app.resizeUi.bind(app));

            var resizeTimer;
            $(window).on('resize', function() {
                clearTimeout(resizeTimer);
                resizeTimer = setTimeout(app.resizeUi.bind(app), 150);
            });
        
            log.info("App initialized.");
        
            initGame();
        });
    };
    
    var initGame = function() {
        require(['game'], function(Game) {
            
            var canvas = document.getElementById("entities"),
        	    background = document.getElementById("background"),
        	    foreground = document.getElementById("foreground"),
        	    input = document.getElementById("chatinput");

    		game = new Game(app);
    		game.setup('#bubbles', canvas, background, foreground, input);
    		game.setStorage(app.storage);
    		app.setGame(game);
    		
    		if(app.isDesktop && app.supportsWorkers) {
    		    game.loadMap();
    		}
	
    		game.onGameStart(function() {
                app.initEquipmentIcons();
    		});
    		
    		game.onDisconnect(function(message) {
    		    $('#death').find('p').html(message+"<em>Please reload the page.</em>");
    		    $('#respawn').hide();
    		});
	
    		game.onPlayerDeath(function() {
    		    if($('body').hasClass('credits')) {
    		        $('body').removeClass('credits');
    		    }
                $('body').addClass('death');
    		});
	
    		game.onPlayerEquipmentChange(function() {
    		    app.initEquipmentIcons();
    		});
	
    		game.onPlayerInvincible(function() {
    		    $('#hitpoints').toggleClass('invincible');
    		});

    		game.onNbPlayersChange(function(worldPlayers, totalPlayers) {
    		    var setWorldPlayersString = function(string) {
        		        $("#instance-population").find("span:nth-child(2)").text(string);
        		        $("#playercount").find("span:nth-child(2)").text(string);
        		    },
        		    setTotalPlayersString = function(string) {
        		        $("#world-population").find("span:nth-child(2)").text(string);
        		    };
    		    
    		    $("#playercount").find("span.count").text(worldPlayers);
    		    
    		    $("#instance-population").find("span").text(worldPlayers);
    		    if(worldPlayers == 1) {
    		        setWorldPlayersString("player");
    		    } else {
    		        setWorldPlayersString("players");
    		    }
    		    
    		    $("#world-population").find("span").text(totalPlayers);
    		    if(totalPlayers == 1) {
    		        setTotalPlayersString("player");
    		    } else {
    		        setTotalPlayersString("players");
    		    }
    		});
	
    		game.onAchievementUnlock(function(id, name, description) {
    		    app.unlockAchievement(id, name);
    		});
	
    		game.onNotification(function(message) {
    		    app.showMessage(message);
    		});
	
            app.initHealthBar();
	
            $('#nameinput').attr('value', '');
    		$('#chatbox').attr('value', '');
    		
        	if(game.renderer.mobile || game.renderer.tablet) {
                var touchOrigin = null,
                    touchDirection = null,
                    touchAccumulator = { x: 0, y: 0 },
                    touchMoveTimer = null,
                    touchDeadZone = 16;

                function movePlayerInTouchDirection() {
                    var player = game.player,
                        stepX = 0,
                        stepY = 0,
                        x,
                        y;

                    if(!touchDirection || !game.started || !player || player.isDead || game.isZoning()) {
                        return;
                    }

                    touchAccumulator.x += Math.abs(touchDirection.x);
                    touchAccumulator.y += Math.abs(touchDirection.y);
                    if(touchAccumulator.x >= touchAccumulator.y) {
                        stepX = touchDirection.x > 0 ? 1 : -1;
                        touchAccumulator.x -= 1;
                    } else {
                        stepY = touchDirection.y > 0 ? 1 : -1;
                        touchAccumulator.y -= 1;
                    }

                    x = player.isMoving() ? player.nextGridX : player.gridX;
                    y = player.isMoving() ? player.nextGridY : player.gridY;
                    game.makePlayerGoTo(x + stepX, y + stepY);
                }

                $('#foreground').on('touchstart', function(event) {
                    var touch = event.originalEvent.touches[0];

                    app.center();
                    app.setMouseCoordinates(touch);
                	game.click();
                	app.hideWindows();

                    touchOrigin = { x: touch.pageX, y: touch.pageY };
                    touchDirection = null;
                    touchAccumulator = { x: 0, y: 0 };
                    clearInterval(touchMoveTimer);
                    touchMoveTimer = null;
                }).on('touchmove', function(event) {
                    var touch,
                        previousDirection = touchDirection,
                        dx,
                        dy,
                        distance;

                    if(!touchOrigin) {
                        return;
                    }

                    touch = event.originalEvent.touches[0];
                    dx = touch.pageX - touchOrigin.x;
                    dy = touch.pageY - touchOrigin.y;

                    if(Math.abs(dx) < touchDeadZone && Math.abs(dy) < touchDeadZone) {
                        return;
                    }

                    event.preventDefault();
                    distance = Math.abs(dx) + Math.abs(dy);
                    touchDirection = { x: dx / distance, y: dy / distance };

                    if(previousDirection &&
                       ((previousDirection.x < 0) !== (touchDirection.x < 0) ||
                        (previousDirection.y < 0) !== (touchDirection.y < 0))) {
                        touchAccumulator = { x: 0, y: 0 };
                    }

                    if(!touchMoveTimer) {
                        movePlayerInTouchDirection();
                        touchMoveTimer = setInterval(movePlayerInTouchDirection, 120);
                    }
                }).on('touchend touchcancel', function() {
                    var wasDragging = !!touchDirection;

                    touchOrigin = null;
                    touchDirection = null;
                    touchAccumulator = { x: 0, y: 0 };
                    clearInterval(touchMoveTimer);
                    touchMoveTimer = null;

                    if(wasDragging && game.player) {
                        game.player.stop();
                    }
                });
            } else {
                $('#foreground').click(function(event) {
                    app.center();
                    app.setMouseCoordinates(event);
                    if(game) {
                	    game.click();
                	}
                	app.hideWindows();
                    // $('#chatinput').focus();
                });
            }

            $('body').off('click');
            $('body').click(function(event) {
                var hasClosedParchment = false;
                
                if($('#parchment').hasClass('credits')) {
                    if(game.started) {
                        app.closeInGameCredits();
                        hasClosedParchment = true;
                    } else {
                        app.toggleCredits();
                    }
                }
                
                if($('#parchment').hasClass('about')) {
                    if(game.started) {
                        app.closeInGameAbout();
                        hasClosedParchment = true;
                    } else {
                        app.toggleAbout();
                    }
                }
                
                if(game.started && !game.renderer.mobile && game.player && !hasClosedParchment) {
                    game.click();
                }
            });
            
            $('#respawn').click(function(event) {
                game.audioManager.playSound("revive");
                game.restart();
                $('body').removeClass('death');
            });
            
            $(document).mousemove(function(event) {
            	app.setMouseCoordinates(event);
            	if(game.started) {
            	    game.movecursor();
            	}
            });

            $(document).keydown(function(e) {
            	var key = e.which,
                    $chat = $('#chatinput');

                if(key === 13) {
                    if($('#chatbox').hasClass('active')) {
                        app.hideChat();
                    } else {
                        app.showChat();
                    }
                }
            });
            
            $('#chatinput').keydown(function(e) {
                var key = e.which,
                    $chat = $('#chatinput');

                if(key === 13) {
                    if($chat.attr('value') !== '') {
                        if(game.player) {
                            game.say($chat.attr('value'));
                        }
                        $chat.attr('value', '');
                        app.hideChat();
                        $('#foreground').focus();
                        return false;
                    } else {
                        app.hideChat();
                        return false;
                    }
                }
                
                if(key === 27) {
                    app.hideChat();
                    return false;
                }
            });

            $('#nameinput').keypress(function(event) {
                var $name = $('#nameinput'),
                    name = $name.val();

                if(event.keyCode === 13) {
                    if(name !== '') {
                        app.tryStartingGame(name, function() {
                            $name.blur(); // exit keyboard on mobile
                        });
                        return false; // prevent form submit
                    } else {
                        return false; // prevent form submit
                    }
                }
            });
            
            $('#mutebutton').click(function() {
                game.audioManager.toggle();
            });
            
            $(document).on("keydown", function(e) {
            	var key = e.which,
            	    $chat = $('#chatinput');

                if($('#chatinput:focus').length == 0 && $('#nameinput:focus').length == 0) {
                    if(key === 13) { // Enter
                        if(game.ready) {
                            $chat.focus();
                            return false;
                        }
                    }
                    if(key === 32) { // Space
                        // game.togglePathingGrid();
                        return false;
                    }
                    if(key === 70) { // F
                        // game.toggleDebugInfo();
                        return false;
                    }
                    if(key === 27) { // ESC
                        app.hideWindows();
                        _.each(game.player.attackers, function(attacker) {
                            attacker.stop();
                        });
                        return false;
                    }
                    if(key === 65) { // a
                        // game.player.hit();
                        return false;
                    }
                } else {
                    if(key === 13 && game.ready) {
                        $chat.focus();
                        return false;
                    }
                }
            });
            
            if(game.renderer.tablet) {
                $('body').addClass('tablet');
            }
        });
    };
    
    initApp();
});
