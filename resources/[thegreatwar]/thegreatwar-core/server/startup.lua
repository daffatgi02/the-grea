-- resources/[thegreatwar]/thegreatwar-core/server/startup.lua
-- Initialize database tables on first start

CreateThread(function()
    -- Wait for database connection
    while not MySQL do
        Wait(100)
    end
    
    print("^2[The Great War] ^7Initializing database...")
    
    -- Create tables if they don't exist
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS `thegreatwar_sessions` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `map_name` VARCHAR(50) NOT NULL,
            `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `ended_at` TIMESTAMP NULL,
            `champion_type` ENUM('solo', 'crew') NOT NULL,
            `champion_name` VARCHAR(100) NOT NULL,
            `champion_kills` INT DEFAULT 0,
            `total_players` INT DEFAULT 0,
            `status` ENUM('lobby', 'active', 'ended') DEFAULT 'lobby'
        )
    ]])
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS `thegreatwar_player_stats` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `session_id` INT NOT NULL,
            `player_id` VARCHAR(50) NOT NULL,
            `nickname` VARCHAR(50) NOT NULL,
            `crew_name` VARCHAR(50) NULL,
            `role` VARCHAR(20) NOT NULL,
            `kills` INT DEFAULT 0,
            `deaths` INT DEFAULT 0,
            `assists` INT DEFAULT 0,
            `survival_time` INT DEFAULT 0,
            `money_earned` INT DEFAULT 0,
            `joined_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`session_id`) REFERENCES `thegreatwar_sessions`(`id`)
        )
    ]])
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS `thegreatwar_crew_stats` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `session_id` INT NOT NULL,
            `crew_name` VARCHAR(50) NOT NULL,
            `total_kills` INT DEFAULT 0,
            `total_members` INT DEFAULT 0,
            `top_player` VARCHAR(50) NOT NULL,
            `top_player_kills` INT DEFAULT 0,
            FOREIGN KEY (`session_id`) REFERENCES `thegreatwar_sessions`(`id`)
        )
    ]])
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS `thegreatwar_leaderboard` (
            `player_id` VARCHAR(50) PRIMARY KEY,
            `nickname` VARCHAR(50) NOT NULL,
            `total_kills` INT DEFAULT 0,
            `total_deaths` INT DEFAULT 0,
            `total_wins_solo` INT DEFAULT 0,
            `total_wins_crew` INT DEFAULT 0,
            `total_sessions` INT DEFAULT 0,
            `total_money_earned` INT DEFAULT 0,
            `last_updated` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])
    
    MySQL.Sync.execute([[
        CREATE TABLE IF NOT EXISTS `thegreatwar_kill_log` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `session_id` INT NOT NULL,
            `killer_id` VARCHAR(50) NOT NULL,
            `victim_id` VARCHAR(50) NOT NULL,
            `weapon` VARCHAR(50) NOT NULL,
            `distance` FLOAT DEFAULT 0,
            `location_x` FLOAT NOT NULL,
            `location_y` FLOAT NOT NULL,
            `location_z` FLOAT NOT NULL,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (`session_id`) REFERENCES `thegreatwar_sessions`(`id`)
        )
    ]])
    
    print("^2[The Great War] ^7Database initialized successfully!")
end)