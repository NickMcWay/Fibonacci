// WordValidator.swift
// Curated 4-letter word list and board-scanning logic.
// Words are stored in a Set for O(1) lookup.
// Extend the wordSet to add more words — the rest of the engine adapts automatically.

import Foundation

final class WordValidator {

    // MARK: - Dictionary
    // ~200 common, recognizable 4-letter English words.
    // Organized thematically to make expansion easy.
    // No obscure crossword words — stick to words a casual player would know.

    static let wordSet: Set<String> = {
        let words: [String] = [
            // Body / people
            "arms", "back", "body", "bone", "chin", "ears", "eyes",
            "face", "feet", "fist", "foot", "hair", "hand", "head",
            "heel", "hide", "hips", "knee", "legs", "lips", "mind",
            "nail", "neck", "nose", "shin", "skin", "sole", "toes",
            "torso",

            // Animals
            "bear", "bird", "boar", "bull", "calf", "clam", "claw",
            "colt", "crab", "crow", "deer", "dino", "dove", "duck",
            "fawn", "fish", "flea", "frog", "gnat", "goat", "gull",
            "hare", "hawk", "heron", "horn", "kite", "lamb", "lark",
            "lion", "mole", "moth", "mule", "newt", "pony", "puma",
            "seal", "slug", "snag", "stag", "swan", "toad", "wasp",
            "wolf", "worm", "wren",

            // Nature
            "alga", "bark", "bead", "berm", "bole", "bolt", "bush",
            "cave", "clay", "clod", "coal", "core", "corn", "damp",
            "dawn", "dune", "dusk", "dust", "fern", "fire", "foam",
            "ford", "gale", "gust", "hail", "haze", "hill", "holm",
            "isle", "kelp", "lake", "lava", "leaf", "lime", "loam",
            "mast", "mead", "mesa", "mist", "moor", "moss", "mote",
            "peat", "pine", "pond", "pool", "rain", "reed", "reef",
            "rift", "rock", "root", "rose", "rune", "rust", "sand",
            "seed", "shore", "silt", "sloe", "snow", "soil", "star",
            "stem", "tide", "tree", "vale", "vine", "wave", "weed",
            "well", "wind", "wood",

            // Common verbs
            "ache", "acts", "adds", "aims", "asks", "bake", "band",
            "bare", "base", "beat", "bend", "bite", "blow", "boil",
            "bond", "bore", "born", "brag", "burn", "call", "care",
            "cast", "chat", "chop", "clap", "clip", "coil", "come",
            "cook", "cope", "cost", "dare", "dash", "deal", "deem",
            "dive", "does", "drag", "draw", "drip", "drop", "duel",
            "dump", "earn", "edit", "fade", "fail", "fall", "farm",
            "feel", "fill", "find", "fire", "firm", "fish", "flee",
            "flew", "flip", "flow", "fold", "form", "fume", "gain",
            "gape", "gave", "gaze", "glow", "gnaw", "grab", "grin",
            "grip", "grow", "gulp", "halt", "hang", "hate", "haul",
            "have", "heal", "heap", "hear", "help", "hide", "hint",
            "hire", "hold", "hope", "hurl", "hurt", "join", "jump",
            "keep", "kick", "kill", "know", "land", "last", "lead",
            "lean", "leap", "lend", "lift", "like", "link", "list",
            "live", "load", "lock", "loom", "lose", "love", "lurk",
            "make", "mark", "melt", "miss", "move", "name", "need",
            "note", "open", "pack", "pass", "pave", "pick", "pile",
            "plan", "play", "plot", "plug", "pour", "pull", "push",
            "rake", "read", "rest", "ride", "ring", "rise", "roam",
            "roll", "rope", "ruin", "rule", "rush", "sail", "save",
            "scan", "seal", "seek", "seem", "seep", "send", "shed",
            "show", "sing", "sink", "skip", "slam", "slap", "slip",
            "slow", "snap", "soar", "sort", "spin", "spit", "spot",
            "stem", "step", "stop", "stub", "swap", "swim", "take",
            "talk", "tame", "tear", "tell", "tend", "test", "tilt",
            "toss", "trap", "trim", "trip", "trot", "tuck", "turn",
            "type", "used", "veer", "wait", "walk", "wane", "want",
            "warn", "warp", "wash", "wear", "weld", "went", "whip",
            "wind", "wink", "wipe", "wish", "work", "wrap",

            // Common nouns
            "ache", "ages", "aide", "aims", "arch", "area", "arts",
            "atom", "aunt", "axle", "band", "bank", "barn", "base",
            "bash", "bath", "beak", "beam", "bean", "beer", "bell",
            "belt", "bias", "blab", "blade", "blot", "blue", "blur",
            "boat", "bold", "bomb", "bond", "book", "boom", "boot",
            "bowl", "bunk", "byte", "cake", "camp", "card", "cart",
            "cash", "cast", "cell", "chip", "clue", "coil", "coin",
            "cord", "cost", "couch", "coup", "crew", "crop", "cube",
            "curl", "dais", "dame", "data", "date", "deal", "debt",
            "deck", "deed", "dell", "dens", "desk", "diet", "dime",
            "dish", "disk", "dome", "done", "door", "dose", "dots",
            "draw", "drum", "dump", "dunk", "dust", "door", "edge",
            "epic", "even", "exam", "face", "fact", "fame", "fare",
            "farm", "feat", "feed", "film", "flag", "flaw", "flea",
            "flex", "flip", "flop", "flux", "foam", "fold", "folk",
            "font", "food", "fork", "form", "fort", "fowl", "fray",
            "free", "fuel", "fuse", "gale", "game", "gang", "gate",
            "gear", "gild", "gist", "glad", "glen", "glue", "gold",
            "golf", "gore", "gown", "grab", "grin", "grit", "gulf",
            "guru", "hall", "helm", "herb", "herd", "hero", "high",
            "hilt", "hint", "hire", "hole", "home", "hood", "hook",
            "hoop", "horn", "host", "hump", "hunt", "husk", "icon",
            "idea", "inch", "iron", "isle", "item", "jail", "jest",
            "jibe", "jolt", "junk", "jury", "keen", "kern", "king",
            "knot", "lace", "lane", "latch", "laud", "lawn", "lead",
            "lair", "lore", "lure", "mane", "maze", "meal", "meat",
            "memo", "mile", "milk", "mill", "mine", "mint", "mode",
            "molt", "moon", "more", "muck", "myth", "name", "neck",
            "news", "nick", "node", "norm", "oath", "odds", "omen",
            "orb", "oval", "oven", "pace", "page", "pair", "palm",
            "park", "part", "path", "peak", "peel", "peer", "perk",
            "pest", "pew", "phase", "pier", "pink", "pipe", "pith",
            "poke", "pole", "poll", "pore", "port", "post", "prey",
            "prim", "prod", "prop", "pulp", "pump", "purl", "purse",
            "rack", "raid", "rail", "rake", "ramp", "rank", "rant",
            "raid", "reel", "rein", "rend", "rent", "ribs", "ride",
            "rift", "rind", "ring", "riot", "risk", "road", "robe",
            "rode", "rook", "room", "rout", "rows", "sale", "salt",
            "scar", "scum", "seam", "sect", "self", "shed", "shin",
            "ship", "shot", "shun", "shut", "side", "sill", "sink",
            "site", "size", "slab", "slat", "slaw", "sled", "slim",
            "slot", "slug", "smog", "snag", "snap", "snob", "snow",
            "slab", "sock", "soot", "soul", "soup", "spam", "span",
            "spar", "sped", "spike", "spun", "spur", "stab", "stab",
            "star", "stew", "stub", "stun", "suck", "suit", "sulk",
            "swam", "sync", "tale", "tank", "tape", "task", "team",
            "tech", "term", "text", "thin", "thorn", "tide", "tile",
            "time", "toil", "toll", "tome", "tong", "tool", "tore",
            "town", "trek", "trim", "trio", "tube", "tuft", "tusk",
            "tuft", "twas", "twig", "twin", "type", "urge", "vale",
            "vane", "vent", "vest", "vice", "view", "void", "volt",
            "wail", "wane", "ware", "wart", "weld", "whim", "whirl",
            "wick", "wig", "will", "wisp", "woe", "writ", "yard",
            "yarn", "yawn", "yoke", "zone", "zoom",

            // Adjectives / descriptors used as short words
            "able", "avid", "bald", "bare", "bold", "calm", "cold",
            "cool", "cozy", "dark", "dead", "dear", "deep", "deft",
            "dire", "dull", "dumb", "dune", "dusky", "each", "easy",
            "even", "fair", "fast", "fine", "firm", "flat", "fond",
            "foul", "free", "full", "good", "gray", "grey", "grim",
            "hard", "hazy", "high", "holy", "huge", "idle", "just",
            "keen", "kind", "last", "late", "lazy", "lean", "lush",
            "mild", "near", "neat", "next", "nice", "nude", "null",
            "numb", "obese", "odd", "pale", "past", "peak", "prim",
            "pure", "rapt", "rare", "rash", "real", "rich", "rife",
            "ripe", "rude", "safe", "same", "sane", "slim", "slow",
            "snug", "soft", "sole", "sore", "sour", "stiff", "sure",
            "tall", "tame", "taut", "tidy", "tiny", "true", "vast",
            "vile", "warm", "wary", "weak", "wide", "wild", "wise",
            "worn",
        ]
        // Normalize to lowercase, filter to exactly 4 chars
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
