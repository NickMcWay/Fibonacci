// WordValidator.swift
// Curated word list (3- and 4-letter) and board-scanning logic.
// Words are stored in Sets for O(1) lookup.
// Extend either wordSet to add more words — the rest of the engine adapts automatically.

import Foundation

final class WordValidator {

    // MARK: - Dictionary (3-letter words)
    // Common, recognizable 3-letter English words every casual player would know.

    static let threeLetterWordSet: Set<String> = {
        let words: [String] = [
            "ACE", "ACT", "ADD", "ADO", "AFT", "AGE", "AGO", "AID", "AIL", "AIM", "AIR", "ALE", "ALL", "AMP", "AND", "ANT", "ANY", "APE", "APP", "APT", "ARC", "ARE", "ARK", "ARM", "ART", "ASH", "ASK", "ASP", "ATE", "AWE", "AXE", "AYE",
            "BAD", "BAG", "BAN", "BAR", "BAT", "BAY", "BED", "BEE", "BEG", "BET", "BIG", "BIN", "BIO", "BIT", "BOA", "BOB", "BOG", "BOO", "BOW", "BOX", "BOY", "BRA", "BRO", "BUD", "BUG", "BUM", "BUN", "BUS", "BUT", "BUY", "BYE",
            "CAB", "CAN", "CAP", "CAR", "CAT", "CHA", "COB", "COD", "COG", "CON", "COO", "COP", "COT", "COW", "COY", "CRY", "CUB", "CUD", "CUE", "CUP", "CUR", "CUT",
            "DAD", "DAM", "DAY", "DEN", "DEW", "DID", "DIE", "DIG", "DIM", "DIP", "DOC", "DOE", "DOG", "DOT", "DRY", "DUE", "DUH", "DUO", "DYE",
            "EAR", "EAT", "EEL", "EGG", "EGO", "ELF", "ELK", "ELM", "EMU", "END", "ERA", "EVE", "EWE", "EYE",
            "FAD", "FAN", "FAR", "FAT", "FED", "FEE", "FEW", "FIG", "FIN", "FIR", "FIT", "FIX", "FLU", "FLY", "FOE", "FOG", "FOR", "FOX", "FRY", "FUN", "FUR",
            "GAP", "GAS", "GAY", "GEL", "GEM", "GET", "GIG", "GIN", "GNU", "GOD", "GUM", "GUN", "GUT", "GUY", "GYM",
            "HAD", "HAG", "HAM", "HAS", "HAT", "HAY", "HEM", "HEN", "HER", "HEW", "HEX", "HEY", "HID", "HIM", "HIP", "HIS", "HIT", "HOE", "HOG", "HOT", "HOW", "HUB", "HUE", "HUG", "HUM", "HUT",
            "ICE", "ICY", "ILL", "IMP", "INK", "INN", "ION", "IRK", "ITS", "IVY",
            "JAB", "JAM", "JAR", "JAW", "JAY", "JET", "JIG", "JOB", "JOG", "JOT", "JOY", "JUG",
            "KID", "KIN", "KIT",
            "LAD", "LAP", "LAW", "LAX", "LAY", "LED", "LEG", "LET", "LID", "LIE", "LIP", "LIT", "LOG", "LOT", "LOW",
            "MAD", "MAT", "MAY", "MED", "MEN", "MET", "MID", "MIX", "MOB", "MOO", "MOP", "MUD", "MUG", "MUM",
            "NAB", "NAG", "NAP", "NAY", "NOD", "NOR", "NOT", "NOW", "NUN", "NUT",
            "OAF", "OAK", "OAR", "OAT", "ODD", "ODE", "OFF", "OIL", "OLD", "ONE", "OPT", "ORB", "ORE", "OUR", "OUT", "OWE", "OWL", "OWN",
            "PAD", "PAL", "PAN", "PAR", "PAT", "PAW", "PAY", "PEA", "PEG", "PEN", "PEP", "PET", "PEW", "PIE", "PIG", "PIN", "PIT", "POD", "POP", "POT", "POW", "POX", "PRO", "PRY", "PUB", "PUN", "PUP", "PUS", "PUT",
            "RAG", "RAM", "RAN", "RAP", "RAT", "RAW", "RAY", "RIB", "RID", "RIG", "RIM", "RIP", "ROB", "ROD", "ROE", "ROT", "ROW", "RUB", "RUE", "RUG", "RUM", "RUN", "RUT", "RYE",
            "SAD", "SAP", "SAT", "SAW", "SAY", "SEA", "SEE", "SET", "SEW", "SEX", "SHE", "SHY", "SIN", "SIP", "SIR", "SIS", "SIT", "SIX", "SKI", "SKY", "SLY", "SOB", "SOD", "SON", "SOW", "SOY", "SPA", "SPY", "SUB", "SUE", "SUM", "SUN",
            "TAB", "TAN", "TAP", "TAR", "TAX", "TEA", "TEE", "TEN", "THE", "TIE", "TIN", "TIP", "TOE", "TON", "TOO", "TOP", "TOT", "TOW", "TOY", "TRY", "TUB", "TUG", "TWO",
            "UFO", "UGH", "UMP", "URN", "USE",
            "VAN", "VAT", "VEG", "VET", "VEX", "VIA", "VOW",
            "WAR", "WAS", "WAX", "WAY", "WEB", "WED", "WEE", "WET", "WHO", "WHY", "WIG", "WIN", "WIT", "WIZ", "WOE", "WOK", "WON", "WOO", "WOW",
            "YAK", "YAM", "YAP", "YEN", "YEP", "YES", "YET", "YEW", "YIN", "YOU", "YUM", "YUP",
            "ZAP", "ZED", "ZEN", "ZIP", "ZIT", "ZOO",
        ]
        return Set(words.map { $0.lowercased() }.filter { $0.count == 3 })
    }()

    // MARK: - Dictionary (4-letter words)
    // ~600 common, recognizable 4-letter English words.
    // No obscure crossword words — every word here a casual player would know.

    static let wordSet: Set<String> = {
        let words: [String] = [
            "ABLE", "ACHE", "ACID", "ACNE", "ACRE", "ACTS", "AGED", "AIDE", "AIDS", "AIMS", "AIRS", "AIRY", "ALSO", "ALTO", "ALUM", "AMEN", "AMMO", "AMOK", "ANTE", "ANTI", "ANTS", "AQUA", "ARCH", "AREA", "ARIA", "ARID", "ARMS", "ARMY", "ARTS", "ATOM", "AVID", "AWAY", "AXES",
            "BABE", "BACK", "BAIT", "BAKE", "BALD", "BALE", "BALL", "BALM", "BAND", "BANE", "BANG", "BANK", "BARE", "BARK", "BARN", "BARS", "BASE", "BASH", "BASK", "BATH", "BATS", "BEAD", "BEAK", "BEAM", "BEAN", "BEAR", "BEAT", "BEEF", "BEEN", "BEER", "BEES", "BEET", "BELL", "BELT", "BEND", "BEST", "BIAS", "BIKE", "BILL", "BIND", "BIRD", "BITE", "BITS", "BLEW", "BLOB", "BLOG", "BLOW", "BLUE", "BLUR", "BOAR", "BOAT", "BODY", "BOIL", "BOLD", "BOLT", "BONE", "BOOK", "BOOM", "BOOT", "BORE", "BORN", "BOSS", "BOTH", "BOUT", "BOWL", "BRAG", "BRAN", "BRAT", "BREW", "BRIM", "BROW", "BUFF", "BULB", "BULK", "BULL", "BUMP", "BUNK", "BUOY", "BURN", "BURP", "BURR", "BURY", "BUSH", "BUSY", "BUZZ",
            "CAGE", "CAKE", "CALF", "CALL", "CALM", "CAME", "CAMP", "CANE", "CARD", "CARE", "CARP", "CART", "CASE", "CASH", "CAST", "CAVE", "CELL", "CHAI", "CHAR", "CHAT", "CHEF", "CHEW", "CHIN", "CHIP", "CHOP", "CITE", "CITY", "CLAM", "CLAP", "CLAW", "CLAY", "CLIP", "CLOT", "CLUE", "COAL", "COAT", "CODE", "COIL", "COIN", "COLD", "COLT", "COMA", "COMB", "COME", "CONE", "COOL", "COPE", "CORD", "CORE", "CORK", "CORN", "COST", "COZY", "CRAB", "CROP", "CROW", "CUBE", "CURL", "CUTE",
            "DARK", "DART", "DASH", "DATA", "DATE", "DAWN", "DAYS", "DEAD", "DEAL", "DEAN", "DEAR", "DECK", "DEED", "DEEP", "DEER", "DEFT", "DENY", "DESK", "DICE", "DIET", "DIRE", "DIRT", "DISC", "DISH", "DISK", "DIVE", "DOCK", "DOLL", "DOME", "DONE", "DOOM", "DOOR", "DOSE", "DOTE", "DOVE", "DOWN", "DOZE", "DRAG", "DRAW", "DREW", "DRIP", "DROP", "DRUM", "DUCK", "DULL", "DUMB", "DUMP", "DUSK", "DUST", "DUTY",
            "EACH", "EARL", "EARN", "EASE", "EAST", "EASY", "EDGE", "EMIT", "ENVY", "EPIC", "EVEN", "EVER", "EVIL", "EXAM",
            "FACE", "FACT", "FADE", "FAIL", "FAIR", "FALL", "FAME", "FANG", "FARM", "FAST", "FATE", "FAWN", "FEAR", "FEAT", "FEED", "FEEL", "FEET", "FELL", "FELT", "FEND", "FERN", "FLAW", "FLEE", "FLEW", "FLEX", "FLIP", "FLOW", "FOAM", "FOLD", "FOLK", "FOND", "FONT", "FOOD", "FOOL", "FOOT", "FORD", "FORK", "FORM", "FORT", "FOUL", "FOUR", "FOWL", "FRAY", "FRET", "FROG", "FROM", "FUEL", "FULL", "FUME", "FUND", "FURY", "FUSE",
            "GALE", "GALL", "GAME", "GASP", "GAVE", "GAZE", "GEAR", "GERM", "GIFT", "GILL", "GIVE", "GLAD", "GLEE", "GLOB", "GLUE", "GOAL", "GOAT", "GOLF", "GONG", "GOOD", "GORE", "GOWN", "GRAB", "GRIM", "GRIN", "GRIP", "GRIT", "GROW", "GULL", "GUST", "GUTS",
            "HACK", "HAIL", "HAIR", "HALF", "HALL", "HALO", "HALT", "HAND", "HANG", "HARD", "HARM", "HARP", "HASH", "HATE", "HAUL", "HAVE", "HAWK", "HAZE", "HAZY", "HEAD", "HEAL", "HEAP", "HEAR", "HEAT", "HEEL", "HELL", "HELM", "HELP", "HERB", "HERD", "HERO", "HIGH", "HILL", "HINT", "HIRE", "HISS", "HIVE", "HOAX", "HOLD", "HOLE", "HOLY", "HOME", "HONK", "HOOD", "HOOK", "HORN", "HOUR", "HOWL", "HULL", "HUMP", "HUNT", "HURL", "HYMN",
            "IDEA", "IDLE", "INCH", "INTO", "IRIS", "IRON", "ISLE", "ITCH",
            "JACK", "JADE", "JAIL", "JERK", "JEST", "JOLT", "JUMP", "JUST",
            "KEEN", "KEEP", "KELP", "KICK", "KILL", "KIND", "KING", "KNOB", "KNOT", "KNOW",
            "LACE", "LACK", "LAID", "LAKE", "LAMB", "LAMP", "LAND", "LANE", "LAST", "LAVA", "LAWN", "LAZY", "LEAD", "LEAF", "LEAN", "LEAP", "LEND", "LENS", "LIAR", "LIFT", "LIKE", "LIME", "LIMP", "LINK", "LION", "LIST", "LIVE", "LOAD", "LOAN", "LOCK", "LOFT", "LONE", "LONG", "LOOK", "LOOM", "LOOT", "LORE", "LOSE", "LOSS", "LOST", "LOUD", "LOVE", "LUCK", "LULL", "LUMP", "LURE", "LURK",
            "MADE", "MAID", "MAIN", "MAKE", "MALE", "MALL", "MANE", "MANY", "MARK", "MAST", "MATH", "MAZE", "MEAL", "MEAN", "MEAT", "MELT", "MEMO", "MERE", "MESH", "MICE", "MILD", "MILK", "MILL", "MINE", "MINT", "MIST", "MOAN", "MOCK", "MOLD", "MOLE", "MOOD", "MOON", "MOOR", "MORE", "MOSS", "MOST", "MOTH", "MOVE", "MUCH", "MUCK", "MULE", "MUSE", "MUSK", "MUTE", "MYTH",
            "NAIL", "NAME", "NAVY", "NECK", "NEED", "NEST", "NEWS", "NEXT", "NICE", "NICK", "NINE", "NODE", "NONE", "NOON", "NORM", "NOSE", "NOTE", "NUMB",
            "OATH", "OBEY", "ODDS", "ODOR", "OMEN", "ONCE", "ONLY", "OPEN", "ORAL", "ORCA", "OVEN", "OVER",
            "PACE", "PACK", "PAGE", "PAIN", "PALM", "PART", "PASS", "PAST", "PATH", "PAVE", "PAWN", "PEAK", "PEEL", "PEER", "PEST", "PICK", "PIER", "PILE", "PINE", "PINK", "PIPE", "PITY", "PLAN", "PLAY", "PLEA", "PLOT", "PLOW", "PLUG", "PLUM", "PLUS", "POEM", "POET", "POLE", "POND", "PORE", "PORT", "POSE", "POUR", "PREY", "PROP", "PULL", "PULP", "PUMP", "PURE", "PUSH",
            "RAGE", "RAID", "RAIN", "RAKE", "RAMP", "RANG", "RANK", "RARE", "RASH", "RASP", "READ", "REAL", "REAP", "REEF", "REEL", "RELY", "RENT", "ROBE", "ROCK", "RODE", "ROLE", "ROLL", "ROOF", "ROOK", "ROOM", "ROOT", "ROPE", "ROSE", "RUDE", "RUIN", "RULE", "RUMP", "RUSH", "RUST",
            "SAFE", "SAGE", "SAIL", "SAKE", "SALT", "SAME", "SAND", "SANE", "SANG", "SANK", "SAVE", "SCAM", "SCAN", "SCAR", "SEAM", "SEED", "SEEP", "SELF", "SELL", "SHED", "SHIN", "SHIP", "SHOE", "SHOT", "SHOW", "SICK", "SIGH", "SILK", "SILL", "SING", "SINK", "SLAB", "SLAM", "SLAP", "SLED", "SLIM", "SLIP", "SLUG", "SMUG", "SNAP", "SNOB", "SNOW", "SOAK", "SOAP", "SOAR", "SOCK", "SOFT", "SOIL", "SOLD", "SOLE", "SOME", "SONG", "SOON", "SORT", "SOUL", "SOUP", "SOUR", "SPAN", "SPIT", "SPOT", "SPUR", "STAB", "STAR", "STAY", "STEM", "STEP", "STEW", "STIR", "STOP", "STUB", "SUCH", "SUIT", "SULK", "SUNG", "SUNK", "SURF", "SWAP", "SWAT", "SWAY", "SWIM",
            "TALE", "TALL", "TAME", "TANG", "TANK", "TAPE", "TART", "TASK", "TEAL", "TEAR", "TELL", "TEND", "TENT", "TERM", "TEST", "THAN", "THAT", "THEN", "THEY", "THIN", "THIS", "TICK", "TIDE", "TILL", "TILT", "TIME", "TOAD", "TOIL", "TOLD", "TOLL", "TOMB", "TONE", "TOOK", "TOOL", "TOSS", "TOUR", "TOWN", "TREK", "TRIM", "TRIO", "TRIP", "TROT", "TUCK", "TUFT", "TUSK", "TWIN",
            "UGLY", "UNDO", "UNIT", "UPON", "USED", "USER",
            "VAIN", "VAST", "VEIL", "VEIN", "VENT", "VINE", "VISE", "VOTE",
            "WADE", "WAGE", "WAIT", "WAKE", "WALK", "WALL", "WAND", "WARD", "WARM", "WARN", "WARP", "WART", "WAVE", "WEAK", "WELD", "WELL", "WENT", "WEST", "WIDE", "WILD", "WILT", "WIND", "WINE", "WING", "WINK", "WIRE", "WISE", "WISH", "WOLF", "WOMB", "WOOD", "WOOL", "WORD", "WORE", "WORK", "WORM", "WORN", "WREN",
            "YELL", "YOGA", "YOKE", "YOLK", "YOUR",
            "ZONE", "ZOOM",
        ]
        return Set(words.map { $0.lowercased() }.filter { $0.count == 4 })
    }()

    // MARK: - Board scanning

    // Returns every word (3- or 4-letter) visible on the board right now.
    static func findMatches(in board: BoardModel) -> [WordMatch] {
        var matches: [WordMatch] = []
        let sets: [Set<String>] = [threeLetterWordSet, wordSet]

        for set in sets {
            let length = set.first?.count ?? 0
            guard length > 0 else { continue }

            // Scan rows
            for row in 0..<board.rows {
                for col in 0...(board.cols - length) {
                    let positions = (col..<(col + length)).map { GridPosition(row: row, col: $0) }
                    if let match = matchAt(positions: positions, in: board, set: set) {
                        matches.append(match)
                    }
                }
            }

            // Scan columns
            for col in 0..<board.cols {
                for row in 0...(board.rows - length) {
                    let positions = (row..<(row + length)).map { GridPosition(row: $0, col: col) }
                    if let match = matchAt(positions: positions, in: board, set: set) {
                        matches.append(match)
                    }
                }
            }
        }

        return matches
    }

    private static func matchAt(positions: [GridPosition], in board: BoardModel, set: Set<String>) -> WordMatch? {
        let tiles = positions.compactMap { board.tile(at: $0) }
        guard tiles.count == positions.count else { return nil }
        let word = String(tiles.map { $0.letter })
        guard set.contains(word.lowercased()) else { return nil }
        return WordMatch(word: word, positions: positions)
    }

    // Convenience: does the board contain any valid word?
    static func hasMatch(in board: BoardModel) -> Bool {
        !findMatches(in: board).isEmpty
    }

    // Validate an arbitrary sequence of letters (for drawn words).
    static func isValidWord(_ word: String) -> Bool {
        let lower = word.lowercased()
        return threeLetterWordSet.contains(lower) || wordSet.contains(lower)
    }
}
