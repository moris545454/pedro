Config = {}

Config.DefaultModel = 'a_c_shepherd'

Config.AllowedModels = {
    'a_c_shepherd',
    'a_c_rottweiler',
    'a_c_husky',
    'a_c_retriever',
    'a_c_poodle',
    'a_c_cat_01'
}

Config.FollowDistance = 1.5
Config.FollowSpeed = 2.0
Config.CommandPrefix = 'pet'
Config.StatDecayIntervalMs = 10000
Config.HungerDecay = 2
Config.StaminaDecay = 3
Config.StatRecovery = 5
Config.LowHungerThreshold = 20
Config.LowStaminaThreshold = 15
Config.XPPerAction = 15
Config.LevelThresholds = { 0, 100, 250, 450, 700, 1000 }
Config.MoodThresholds = {
    happy = 75,
    content = 45
}
Config.TrickScenarios = {
    sit = 'WORLD_DOG_SITTING',
    bark = 'WORLD_DOG_BARKING',
    beg = 'WORLD_DOG_BARKING'
}
