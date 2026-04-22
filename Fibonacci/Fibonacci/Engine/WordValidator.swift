// WordValidator.swift
// Curated 4-letter word list and board-scanning logic.
// Words are stored in a Set for O(1) lookup.
// Extend the wordSet to add more words — the rest of the engine adapts automatically.

import Foundation

final class WordValidator {

    // MARK: - Dictionary
    // ~700 common, recognizable 4-letter English words.
    // Organized by category to make expansion easy.
    // No obscure crossword words — every word here a casual player would know.
    // To add more words: append to any category array below.

    static let wordSet: Set<String> = {
        let words: [String] = [

            // ── Body ──────────────────────────────────────────────────────────
            "arms", "back", "bone", "chin", "ears", "eyes", "face",
            "feet", "fist", "foot", "hair", "hand", "head", "heel",
            "hide", "hips", "knee", "legs", "lips", "mind", "nail",
            "neck", "nose", "shin", "skin", "sole", "vein", "waist",

            // ── Animals ───────────────────────────────────────────────────────
            "bear", "bird", "boar", "buck", "bull", "calf", "clam",
            "claw", "colt", "crab", "crow", "deer", "dove", "duck",
            "fawn", "fish", "flea", "frog", "gnat", "goat", "gull",
            "hare", "hawk", "hind", "kite", "lamb", "lark", "lion",
            "lynx", "mole", "moth", "mule", "newt", "pony", "seal",
            "slug", "stag", "swan", "toad", "wasp", "wolf", "worm",
            "wren", "mare", "mink", "pike", "vole", "boar", "ibis",
            "rook", "crane", "finch",

            // ── Nature / landscape ────────────────────────────────────────────
            "bark", "cave", "clay", "coal", "corn", "dale", "dawn",
            "dune", "dusk", "dust", "fern", "fire", "foam", "ford",
            "gale", "gust", "hail", "haze", "hill", "isle", "kelp",
            "lake", "lava", "leaf", "lime", "loam", "mead", "mesa",
            "mist", "moor", "moss", "peat", "pine", "pond", "pool",
            "rain", "reed", "reef", "rift", "rock", "root", "rose",
            "rune", "rust", "sand", "seed", "silt", "snow", "soil",
            "star", "stem", "tide", "tree", "vale", "vine", "wave",
            "weed", "well", "wind", "wood", "glen", "knoll", "crag",
            "cove", "dune", "fell", "holm", "loch", "marsh", "shoal",
            "spit", "tarn", "turf",

            // ── Food & drink ──────────────────────────────────────────────────
            "bake", "bean", "beef", "beer", "beet", "bite", "bran",
            "brew", "bun",  "cake", "chip", "chop", "clam", "cola",
            "cook", "corn", "crab", "curd", "date", "diet", "dish",
            "dram", "duck", "dump", "fare", "farm", "feed", "fish",
            "flan", "food", "fork", "fowl", "fry",  "grain", "grape",
            "herb", "hops", "jell", "juice", "kale", "lamb", "lard",
            "leek", "lime", "loin", "loaf", "malt", "meal", "meat",
            "milk", "mint", "miso", "muck", "oats", "pear", "peel",
            "pie", "plum", "pork", "port", "pulp", "rice", "rind",
            "rump", "rusk", "rye",  "sage", "salt", "seed", "slaw",
            "sloe", "snap", "soup", "spit", "stew", "tart", "tofu",
            "tuna", "veal", "wine", "yolk", "zest",

            // ── House & objects ───────────────────────────────────────────────
            "arch", "axle", "barn", "bath", "beam", "bell", "belt",
            "bolt", "book", "boot", "bowl", "bunk", "cage", "card",
            "cart", "cash", "cell", "cord", "coil", "coin", "comb",
            "cord", "crib", "cup",  "dart", "deck", "desk", "dial",
            "dish", "disk", "dome", "door", "drum", "edge", "file",
            "flag", "font", "fork", "fuse", "gate", "gear", "gown",
            "grid", "grill", "hall", "helm", "hilt", "hive", "hook",
            "hoop", "horn", "hose", "jug",  "kelp", "kiln", "knob",
            "knot", "lace", "lamp", "latch", "lens", "lock", "loft",
            "loom", "mace", "mail", "mast", "mill", "nail", "node",
            "oven", "pack", "page", "pail", "pan",  "pipe", "plan",
            "plug", "pole", "poll", "pump", "rack", "rail", "rake",
            "ramp", "ring", "robe", "rope", "rung", "safe", "sail",
            "sill", "sink", "slab", "slat", "sled", "slot", "sock",
            "sofa", "spool", "spur", "stab", "step", "stir", "sump",
            "tank", "tape", "tent", "tile", "tong", "tool", "trap",
            "tray", "tube", "vent", "vest", "wick", "will", "wire",
            "wrap", "writ", "yard", "yoke",

            // ── Actions / verbs ───────────────────────────────────────────────
            "ache", "adds", "aims", "asks", "band", "bare", "beat",
            "bend", "bind", "bite", "blow", "boil", "bond", "bore",
            "born", "brag", "burn", "call", "care", "cast", "chat",
            "chop", "clap", "clip", "come", "cope", "curb", "dare",
            "dash", "deal", "deem", "dive", "drag", "draw", "drip",
            "drop", "duel", "dump", "earn", "edit", "fade", "fail",
            "fall", "feel", "fill", "find", "flee", "flew", "flip",
            "flow", "fold", "form", "fume", "gain", "gape", "gave",
            "gaze", "glow", "gnaw", "grab", "grin", "grip", "grow",
            "gulp", "halt", "hang", "hate", "haul", "have", "heal",
            "heap", "hear", "help", "hint", "hire", "hold", "hope",
            "howl", "hurl", "hurt", "join", "jump", "keep", "kick",
            "kill", "know", "land", "last", "lead", "lean", "leap",
            "lend", "lift", "like", "link", "list", "live", "load",
            "lock", "loom", "lose", "love", "lurk", "make", "mark",
            "melt", "miss", "move", "muse", "name", "need", "note",
            "open", "pack", "pass", "pave", "pick", "pile", "plan",
            "play", "plot", "plug", "pour", "pull", "push", "rake",
            "read", "rend", "rest", "ride", "ring", "rise", "roam",
            "roar", "roll", "rope", "ruin", "rule", "rush", "sail",
            "save", "scan", "seal", "seek", "seem", "seep", "send",
            "shed", "show", "sing", "sink", "skip", "slam", "slap",
            "slip", "slow", "snap", "soar", "sort", "spin", "spit",
            "spot", "stem", "step", "stop", "swap", "swim", "take",
            "talk", "tame", "tear", "tell", "tend", "test", "tilt",
            "toil", "toss", "trap", "trim", "trip", "trot", "tuck",
            "turn", "type", "veer", "wait", "walk", "wane", "want",
            "warn", "warp", "wash", "wear", "weld", "went", "whip",
            "wink", "wipe", "wish", "work", "wrap", "yell", "zoom",
            "bare", "bled", "bred", "clad", "clod", "fled", "gild",
            "hewn", "knit", "lain", "leapt", "lied", "pent", "plod",
            "pled", "raft", "rang", "reap", "reel", "rein", "rode",
            "rove", "rung", "sang", "sank", "sawn", "sent", "sewn",
            "shed", "shod", "shot", "shun", "shut", "slid", "smote",
            "span", "spun", "stud", "sung", "sunk", "swam", "swum",
            "tore", "torn", "trod", "woke", "wove", "writ",

            // ── Adjectives ────────────────────────────────────────────────────
            "able", "avid", "bald", "bare", "bold", "calm", "cold",
            "cool", "cozy", "dark", "dead", "dear", "deep", "deft",
            "dire", "drab", "dull", "dumb", "each", "easy", "even",
            "fair", "fast", "fine", "firm", "flat", "fond", "foul",
            "free", "full", "good", "gray", "grey", "grim", "hard",
            "hazy", "high", "holy", "huge", "idle", "just", "keen",
            "kind", "last", "late", "lazy", "lean", "limp", "lush",
            "meek", "mild", "near", "neat", "next", "nice", "nude",
            "null", "numb", "pale", "past", "pink", "prim", "pure",
            "rapt", "rare", "rash", "real", "rich", "rife", "ripe",
            "rude", "safe", "same", "sane", "slim", "slow", "smug",
            "snug", "soft", "sore", "sour", "sure", "tall", "tame",
            "taut", "tidy", "tiny", "torn", "true", "vast", "vile",
            "void", "warm", "wary", "weak", "wide", "wild", "wise",
            "worn", "wry",

            // ── Common nouns (misc) ───────────────────────────────────────────
            "aide", "area", "arts", "atom", "aunt", "bail", "bale",
            "band", "bank", "base", "bash", "bias", "blob", "blur",
            "bomb", "bond", "boom", "boon", "boss", "bout", "bulk",
            "byte", "camp", "clan", "clue", "code", "coup", "crew",
            "crop", "cube", "curl", "dame", "data", "debt", "deed",
            "dell", "dime", "dome", "dose", "draw", "dunk", "epic",
            "exam", "fact", "fame", "feat", "film", "flaw", "flea",
            "flex", "flop", "flux", "folk", "fray", "fuel", "fund",
            "game", "gang", "gist", "glue", "gold", "golf", "gore",
            "grit", "gulf", "guru", "gust", "helm", "herd", "hero",
            "hive", "home", "hood", "host", "hump", "hunt", "husk",
            "icon", "idea", "inch", "iron", "item", "jail", "jest",
            "jolt", "junk", "jury", "kern", "king", "lair", "lane",
            "laud", "lawn", "lore", "lure", "mane", "maze", "memo",
            "mile", "mine", "mint", "mode", "molt", "moon", "muck",
            "myth", "news", "nick", "norm", "oath", "odds", "omen",
            "oval", "pace", "pair", "palm", "park", "part", "path",
            "peak", "peel", "peer", "perk", "pest", "pier", "pith",
            "poke", "pore", "port", "post", "prey", "prod", "prop",
            "pulp", "raid", "rank", "rant", "ribs", "rind", "riot",
            "risk", "road", "rout", "sale", "scar", "scum", "seam",
            "sect", "self", "shin", "ship", "shot", "side", "site",
            "size", "smog", "snob", "soot", "soul", "spam", "spar",
            "spun", "star", "stew", "stun", "suit", "sulk", "sync",
            "tale", "task", "team", "tech", "term", "text", "thin",
            "toll", "tome", "town", "trek", "trio", "tuft", "tusk",
            "twig", "twin", "urge", "vane", "view", "volt", "wail",
            "ware", "wart", "whim", "wisp", "wren", "yarn", "yawn",
            "yore", "zeal", "zone",

            // ── People & society ──────────────────────────────────────────────
            "bard", "beau", "boss", "chef", "clan", "crew", "czar",
            "dame", "dean", "duke", "earl", "guru", "heir", "hero",
            "host", "icon", "kern", "king", "knave", "kin",  "lord",
            "mage", "maid", "mate", "monk", "nerd", "page", "peer",
            "poet", "sage", "seer", "serf", "sire", "twin", "ward",
            "waif",

            // ── Emotions & states ─────────────────────────────────────────────
            "awe",  "calm", "daze", "doom", "dread", "envy", "fear",
            "fury", "glee", "glum", "grim", "hate", "hope", "hush",
            "lull", "mope", "rage", "rift", "woe",  "zeal",

            // ── Movement & position ───────────────────────────────────────────
            "away", "back", "down", "fore", "here", "into", "left",
            "near", "next", "over", "past", "rear", "side", "upon",

            // ── Time ──────────────────────────────────────────────────────────
            "ages", "dawn", "days", "dusk", "eons", "hour", "last",
            "late", "lore", "long", "morn", "next", "noon", "once",
            "past", "then", "week", "year", "yore",

        ]
        // Normalize to lowercase, keep exactly 4-char words, deduplicate via Set
        return Set(words.map { $0.lowercased() }.filter { $0.count == 4 })
    }()

    // MARK: - Board Scanning

    struct WordMatch {
        let word: String
        let positions: [(row: Int, col: Int)]
    }

    // Scan board for all valid 4-letter words horizontally and vertically.
    // Rule: all unique tile positions from all matches are cleared simultaneously.
    // If a tile appears in two overlapping words, both words score and the tile is cleared once.
    static func findMatches(in board: BoardModel) -> [WordMatch] {
        var matches: [WordMatch] = []

        // Horizontal
        for r in 0..<BoardModel.size {
            for startC in 0...(BoardModel.size - 4) {
                let positions = (startC..<startC+4).map { (row: r, col: $0) }
                if let match = matchAt(positions: positions, board: board) {
                    matches.append(match)
                }
            }
        }

        // Vertical
        for c in 0..<BoardModel.size {
            for startR in 0...(BoardModel.size - 4) {
                let positions = (startR..<startR+4).map { (row: $0, col: c) }
                if let match = matchAt(positions: positions, board: board) {
                    matches.append(match)
                }
            }
        }

        return matches
    }

    private static func matchAt(positions: [(row: Int, col: Int)], board: BoardModel) -> WordMatch? {
        let tiles = positions.compactMap { board.tile(row: $0.row, col: $0.col) }
        guard tiles.count == 4 else { return nil }
        let word = String(tiles.map { $0.letter })
        guard wordSet.contains(word.lowercased()) else { return nil }
        return WordMatch(word: word, positions: positions)
    }

    // Convenience: does the board contain any valid word?
    static func hasMatch(in board: BoardModel) -> Bool {
        !findMatches(in: board).isEmpty
    }
}
