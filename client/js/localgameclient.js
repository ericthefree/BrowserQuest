define(['gameclient', 'text!../maps/world_server.json'], function(GameClient, mapJson) {
    var mobProperties = {
            rat: { hp: 25, armor: 1, weapon: 1, drops: { flask: 40, burger: 10, firepotion: 5 } },
            skeleton: { hp: 110, armor: 2, weapon: 2, drops: { flask: 40, mailarmor: 10, axe: 20, firepotion: 5 } },
            goblin: { hp: 90, armor: 2, weapon: 1, drops: { flask: 50, leatherarmor: 20, axe: 10, firepotion: 5 } },
            ogre: { hp: 200, armor: 3, weapon: 2, drops: { burger: 10, flask: 50, platearmor: 20, morningstar: 20, firepotion: 5 } },
            spectre: { hp: 250, armor: 2, weapon: 4, drops: { flask: 30, redarmor: 40, redsword: 30, firepotion: 5 } },
            deathknight: { hp: 250, armor: 3, weapon: 3, drops: { burger: 95, firepotion: 5 } },
            crab: { hp: 60, armor: 2, weapon: 1, drops: { flask: 50, axe: 20, leatherarmor: 10, firepotion: 5 } },
            snake: { hp: 150, armor: 3, weapon: 2, drops: { flask: 50, mailarmor: 10, morningstar: 10, firepotion: 5 } },
            skeleton2: { hp: 200, armor: 3, weapon: 3, drops: { flask: 60, platearmor: 15, bluesword: 15, firepotion: 5 } },
            eye: { hp: 200, armor: 3, weapon: 3, drops: { flask: 50, redarmor: 20, redsword: 10, firepotion: 5 } },
            bat: { hp: 80, armor: 2, weapon: 1, drops: { flask: 50, axe: 10, firepotion: 5 } },
            wizard: { hp: 100, armor: 2, weapon: 6, drops: { flask: 50, platearmor: 20, firepotion: 5 } },
            boss: { hp: 700, armor: 6, weapon: 7, drops: { goldensword: 100 } }
        },
        map = JSON.parse(mapJson);

    function randomInt(min, max) {
        return min + Math.floor(Math.random() * (max - min + 1));
    }

    function damage(weaponLevel, armorLevel) {
        return Math.max(randomInt(0, 3), weaponLevel * randomInt(5, 10) - armorLevel * randomInt(1, 3));
    }

    function playerArmorLevel(kind) {
        return Math.max(1, Types.getArmorRank(kind) + 1);
    }

    function playerWeaponLevel(kind) {
        return Math.max(1, Types.getWeaponRank(kind) + 1);
    }

    var LocalGameClient = GameClient.extend({
        init: function() {
            this._super("offline", null, false);
            this.entities = {};
            this.nextEntityId = 100000;
            this.playerId = 99999;
            this.playerHealth = 80;
            this.playerArmor = Types.Entities.CLOTHARMOR;
            this.playerWeapon = Types.Entities.SWORD1;
            this.checkpoint = window.BROWSERQUEST_OFFLINE_WORLD || null;
        },

        connect: function() {
            var self = this;
            setTimeout(function() {
                if(self.connected_callback) {
                    self.connected_callback();
                }
            }, 0);
        },

        sendHello: function(player) {
            var start = this.getStartingPosition(),
                name = (player.name || "adventurer").substring(0, 15);

            this.playerArmor = Types.getKindFromString(player.getSpriteName()) || Types.Entities.CLOTHARMOR;
            this.playerWeapon = Types.getKindFromString(player.getWeaponName()) || Types.Entities.SWORD1;
            this.playerHealth = 80 + ((playerArmorLevel(this.playerArmor) - 1) * 30);

            this.receiveWelcome([
                Types.Messages.WELCOME,
                this.playerId,
                name,
                start.x,
                start.y,
                this.playerHealth
            ]);
            this.entities = {};
            this.nextEntityId = 100000;
            this.populateWorld();
            this.receivePopulation([Types.Messages.POPULATION, 1, 1]);
        },

        getStartingPosition: function() {
            var checkpoint, starting;
            if(this.checkpoint && this.checkpoint.id) {
                checkpoint = _.find(map.checkpoints, function(item) {
                    return item.id === this.checkpoint.id;
                }, this);
            }
            starting = checkpoint || _.find(map.checkpoints, function(item) { return item.s === 1; });
            return {
                x: starting.x + Math.floor(starting.w / 2),
                y: starting.y + Math.floor(starting.h / 2)
            };
        },

        populateWorld: function() {
            var self = this;

            _.each(map.staticEntities, function(kindName, tileId) {
                var tile = parseInt(tileId, 10),
                    x = ((tile - 1) % map.width) + 1,
                    y = Math.floor((tile - 1) / map.width);
                self.addEntity(Types.getKindFromString(kindName), x, y);
            });

            _.each(map.roamingAreas, function(area) {
                for(var index = 0; index < area.nb; index += 1) {
                    self.addEntity(
                        Types.getKindFromString(area.type),
                        area.x + randomInt(0, area.width),
                        area.y + randomInt(0, area.height)
                    );
                }
            });

            _.each(map.staticChests, function(chest) {
                self.addEntity(Types.Entities.CHEST, chest.x, chest.y, { items: chest.i });
            });
        },

        addEntity: function(kind, x, y, options) {
            var id = this.nextEntityId++,
                state = _.extend({ id: id, kind: kind, x: x, y: y, active: true }, options || {}),
                kindName = Types.getKindAsString(kind),
                properties = mobProperties[kindName];

            if(properties) {
                state.hp = properties.hp;
                state.maxHp = properties.hp;
            }
            this.entities[id] = state;
            this.spawnEntity(state);
            return state;
        },

        spawnEntity: function(entity) {
            var message = [Types.Messages.SPAWN, entity.id, entity.kind, entity.x, entity.y];
            if(Types.isMob(entity.kind) || Types.isNpc(entity.kind)) {
                message.push(randomInt(1, 4));
            }
            this.receiveSpawn(message);
        },

        sendMove: function(x, y) {
            this.playerX = x;
            this.playerY = y;
        },

        sendLootMove: function() {},

        sendAggro: function(mob) {
            var state = this.entities[mob.id];
            if(state && state.active) {
                state.target = this.playerId;
                this.receiveAttack([Types.Messages.ATTACK, mob.id, this.playerId]);
            }
        },

        sendAttack: function() {},

        sendHit: function(mob) {
            var state = this.entities[mob.id],
                properties,
                points,
                self = this;
            if(!state || !state.active) {
                return;
            }

            properties = mobProperties[Types.getKindAsString(state.kind)];
            points = damage(playerWeaponLevel(this.playerWeapon), properties.armor);
            state.hp -= points;
            this.receiveDamage([Types.Messages.DAMAGE, state.id, points]);

            if(state.hp <= 0) {
                state.active = false;
                this.receiveKill([Types.Messages.KILL, state.kind]);
                this.receiveDespawn([Types.Messages.DESPAWN, state.id]);
                this.dropFrom(state, properties.drops);
                setTimeout(function() {
                    state.hp = state.maxHp;
                    state.active = true;
                    self.spawnEntity(state);
                }, 30000);
            }
        },

        sendHurt: function(mob) {
            var state = this.entities[mob.id],
                properties,
                points;
            if(!state || !state.active || this.playerHealth <= 0) {
                return;
            }
            properties = mobProperties[Types.getKindAsString(state.kind)];
            points = damage(properties.weapon, playerArmorLevel(this.playerArmor));
            this.playerHealth = Math.max(0, this.playerHealth - points);
            this.receiveHealth([Types.Messages.HEALTH, this.playerHealth]);
        },

        sendChat: function(text) {
            this.receiveChat([Types.Messages.CHAT, this.playerId, text.substring(0, 60)]);
        },

        sendLoot: function(item) {
            var state = this.entities[item.id],
                amount;
            if(!state || !state.active) {
                return;
            }
            state.active = false;

            if(Types.isHealingItem(state.kind)) {
                amount = state.kind === Types.Entities.FLASK ? 40 : 100;
                this.playerHealth = Math.min(80 + ((playerArmorLevel(this.playerArmor) - 1) * 30), this.playerHealth + amount);
                this.receiveHealth([Types.Messages.HEALTH, this.playerHealth]);
            } else if(Types.isArmor(state.kind)) {
                this.playerArmor = state.kind;
                this.playerHealth = 80 + ((playerArmorLevel(this.playerArmor) - 1) * 30);
                this.receiveEquipItem([Types.Messages.EQUIP, this.playerId, state.kind]);
                this.receiveHitPoints([Types.Messages.HP, this.playerHealth]);
            } else if(Types.isWeapon(state.kind)) {
                this.playerWeapon = state.kind;
                this.receiveEquipItem([Types.Messages.EQUIP, this.playerId, state.kind]);
            }
        },

        sendTeleport: function(x, y) {
            this.playerX = x;
            this.playerY = y;
        },

        sendWho: function() {},

        sendZone: function() {
            var ids = [Types.Messages.LIST];
            _.each(this.entities, function(entity) {
                if(entity.active) {
                    ids.push(entity.id);
                }
            });
            this.receiveList(ids);
        },

        sendOpen: function(chest) {
            var state = this.entities[chest.id],
                kind;
            if(!state || !state.active) {
                return;
            }
            state.active = false;
            this.receiveDespawn([Types.Messages.DESPAWN, state.id]);
            if(state.items && state.items.length) {
                kind = state.items[randomInt(0, state.items.length - 1)];
                this.addEntity(kind, state.x, state.y);
            }
        },

        sendCheck: function(id) {
            this.checkpoint = { id: id };
            window.BROWSERQUEST_OFFLINE_WORLD = this.checkpoint;
            this.saveToCloud();
        },

        dropFrom: function(mob, drops) {
            var roll,
                selected = null,
                id;
            roll = randomInt(1, 100);
            _.each(drops, function(weight, kindName) {
                if(selected === null && roll <= weight) {
                    selected = Types.getKindFromString(kindName);
                }
                roll -= weight;
            });
            if(selected !== null) {
                id = this.nextEntityId++;
                this.entities[id] = { id: id, kind: selected, x: mob.x, y: mob.y, active: true };
                this.receiveDrop([Types.Messages.DROP, mob.id, id, selected, [this.playerId]]);
            }
        },

        saveToCloud: function() {
            if(window.BrowserQuestCloud) {
                window.BrowserQuestCloud.save(localStorage.data || "", JSON.stringify(this.checkpoint || {}));
            }
        }
    });

    return LocalGameClient;
});
