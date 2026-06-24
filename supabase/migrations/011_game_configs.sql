-- Create game_configs table in game schema
CREATE TABLE IF NOT EXISTS game.game_configs (
    key text PRIMARY KEY,
    value jsonb NOT NULL,
    description text,
    updated_at timestamp with time zone DEFAULT now()
);

-- Enable RLS
ALTER TABLE game.game_configs ENABLE ROW LEVEL SECURITY;

-- Allow public read and write access for testing/admin purposes
CREATE POLICY "Allow public read access to game_configs" ON game.game_configs
    FOR SELECT USING (true);

CREATE POLICY "Allow public write access to game_configs" ON game.game_configs
    FOR ALL USING (true) WITH CHECK (true);

-- Insert default configurations
INSERT INTO game.game_configs (key, value, description)
VALUES 
(
  'buildings',
  '{
    "sawmill": { "base_seconds": 180, "base_cost": { "wood": 30, "iron": 10 }, "base_prod_tick": { "wood": 6 }, "prod_tick_per_level": { "wood": 3 } },
    "smelter": { "base_seconds": 180, "base_cost": { "wood": 20, "iron": 30 }, "base_prod_tick": { "iron": 2 }, "prod_tick_per_level": { "iron": 1 } },
    "rice_farm": { "base_seconds": 240, "base_cost": { "wood": 40, "iron": 10 }, "base_prod_tick": { "rice": 6 }, "prod_tick_per_level": { "rice": 3 } },
    "distillery": { "base_seconds": 300, "base_cost": { "wood": 30, "iron": 20 }, "base_prod_tick": { "liquor": 1 }, "prod_tick_per_level": { "liquor": 1 } },
    "house": { "base_seconds": 120, "base_cost": { "wood": 50, "iron": 10 }, "base_prod_tick": {}, "prod_tick_per_level": {} },
    "tavern": { "base_seconds": 200, "base_cost": { "wood": 40, "iron": 20 }, "base_prod_tick": {}, "prod_tick_per_level": {} },
    "shrine": { "base_seconds": 360, "base_cost": { "wood": 60, "iron": 30 }, "base_prod_tick": {}, "prod_tick_per_level": {} },
    "barracks": { "base_seconds": 300, "base_cost": { "wood": 50, "iron": 40 }, "base_prod_tick": {}, "prod_tick_per_level": {} },
    "elephant_camp": { "base_seconds": 600, "base_cost": { "wood": 80, "iron": 60 }, "base_prod_tick": {}, "prod_tick_per_level": {} },
    "smithy": { "base_seconds": 400, "base_cost": { "wood": 40, "iron": 50 }, "base_prod_tick": {}, "prod_tick_per_level": {} },
    "wall": { "base_seconds": 500, "base_cost": { "wood": 30, "iron": 60 }, "base_prod_tick": {}, "prod_tick_per_level": {} },
    "watchtower": { "base_seconds": 350, "base_cost": { "wood": 50, "iron": 30 }, "base_prod_tick": {}, "prod_tick_per_level": {} },
    "town_hall": { "base_seconds": 600, "base_cost": { "wood": 80, "iron": 80 }, "base_prod_tick": {}, "prod_tick_per_level": {} }
  }'::jsonb,
  'Configuration for all buildings including upgrade time (base_seconds), upgrade cost (base_cost), and production'
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, description = EXCLUDED.description;

INSERT INTO game.game_configs (key, value, description)
VALUES 
(
  'troops',
  '{
    "swordsman": { "training_seconds": 300, "cost_per_unit": { "wood": 5, "iron": 3 }, "attack": 10, "defense": 10 },
    "archer": { "training_seconds": 300, "cost_per_unit": { "wood": 8, "iron": 2 }, "attack": 12, "defense": 6 },
    "spearman": { "training_seconds": 300, "cost_per_unit": { "wood": 4, "iron": 6 }, "attack": 8, "defense": 15 },
    "cavalry": { "training_seconds": 600, "cost_per_unit": { "wood": 10, "iron": 10 }, "attack": 18, "defense": 14 },
    "elephant": { "training_seconds": 900, "cost_per_unit": { "wood": 20, "iron": 20 }, "attack": 35, "defense": 30 }
  }'::jsonb,
  'Configuration for troop training times, costs, and stats'
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, description = EXCLUDED.description;

INSERT INTO game.game_configs (key, value, description)
VALUES 
(
  'resources',
  '{
    "tick_duration_minutes": 5,
    "offline_cap_minutes": 480
  }'::jsonb,
  'Global resource configurations'
)
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, description = EXCLUDED.description;

-- Disable Row Level Security (RLS) on game tables to allow admin dashboard management
ALTER TABLE game.players DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.settlements DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.buildings DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.troops DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.map_nodes DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.quests DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.season DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.player_quests DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.march_queues DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.enemies DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.events DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.caravans DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.achievements DISABLE ROW LEVEL SECURITY;
ALTER TABLE game.building_positions DISABLE ROW LEVEL SECURITY;

