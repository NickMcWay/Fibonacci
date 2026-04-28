// WordValidator.swift
// Curated word lists (3–10 letters) for English and Dutch, plus board-scanning logic.
// findMatches(in:language:) automatically scans all window sizes from 3 up to board.size.

import Foundation

final class WordValidator {

    // MARK: - English 3-letter dictionary

    static let threeLetterWordSet: Set<String> = {
        let words = [
            "ACE","ACT","ADD","ADO","AFT","AGE","AGO","AID","AIL","AIM","AIR","ALE","ALL","AMP","AND","ANT","ANY","APE","APP","APT","ARC","ARE","ARK","ARM","ART","ASH","ASK","ASP","ATE","AWE","AXE","AYE",
            "BAD","BAG","BAN","BAR","BAT","BAY","BED","BEE","BEG","BET","BIG","BIN","BIO","BIT","BOA","BOB","BOG","BOO","BOW","BOX","BOY","BRA","BRO","BUD","BUG","BUM","BUN","BUS","BUT","BUY","BYE",
            "CAB","CAN","CAP","CAR","CAT","CHA","COB","COD","COG","CON","COO","COP","COT","COW","COY","CRY","CUB","CUD","CUE","CUP","CUR","CUT",
            "DAD","DAM","DAY","DEN","DEW","DID","DIE","DIG","DIM","DIP","DOC","DOE","DOG","DOT","DRY","DUE","DUH","DUO","DYE",
            "EAR","EAT","EEL","EGG","EGO","ELF","ELK","ELM","EMU","END","ERA","EVE","EWE","EYE",
            "FAD","FAN","FAR","FAT","FED","FEE","FEW","FIG","FIN","FIR","FIT","FIX","FLU","FLY","FOE","FOG","FOR","FOX","FRY","FUN","FUR",
            "GAP","GAS","GAY","GEL","GEM","GET","GIG","GIN","GNU","GOD","GUM","GUN","GUT","GUY","GYM",
            "HAD","HAG","HAM","HAS","HAT","HAY","HEM","HEN","HER","HEW","HEX","HEY","HID","HIM","HIP","HIS","HIT","HOE","HOG","HOT","HOW","HUB","HUE","HUG","HUM","HUT",
            "ICE","ICY","ILL","IMP","INK","INN","ION","IRK","ITS","IVY",
            "JAB","JAM","JAR","JAW","JAY","JET","JIG","JOB","JOG","JOT","JOY","JUG",
            "KID","KIN","KIT",
            "LAD","LAP","LAW","LAX","LAY","LED","LEG","LET","LID","LIE","LIP","LIT","LOG","LOT","LOW",
            "MAD","MAT","MAY","MED","MEN","MET","MID","MIX","MOB","MOO","MOP","MUD","MUG","MUM",
            "NAB","NAG","NAP","NAY","NOD","NOR","NOT","NOW","NUN","NUT",
            "OAF","OAK","OAR","OAT","ODD","ODE","OFF","OIL","OLD","ONE","OPT","ORB","ORE","OUR","OUT","OWE","OWL","OWN",
            "PAD","PAL","PAN","PAR","PAT","PAW","PAY","PEA","PEG","PEN","PEP","PET","PEW","PIE","PIG","PIN","PIT","POD","POP","POT","POW","POX","PRO","PRY","PUB","PUN","PUP","PUS","PUT",
            "RAG","RAM","RAN","RAP","RAT","RAW","RAY","RIB","RID","RIG","RIM","RIP","ROB","ROD","ROE","ROT","ROW","RUB","RUE","RUG","RUM","RUN","RUT","RYE",
            "SAD","SAP","SAT","SAW","SAY","SEA","SEE","SET","SEW","SEX","SHE","SHY","SIN","SIP","SIR","SIS","SIT","SIX","SKI","SKY","SLY","SOB","SOD","SON","SOW","SOY","SPA","SPY","SUB","SUE","SUM","SUN",
            "TAB","TAN","TAP","TAR","TAX","TEA","TEE","TEN","THE","TIE","TIN","TIP","TOE","TON","TOO","TOP","TOT","TOW","TOY","TRY","TUB","TUG","TWO",
            "UFO","UGH","UMP","URN","USE",
            "VAN","VAT","VEG","VET","VEX","VIA","VOW",
            "WAR","WAS","WAX","WAY","WEB","WED","WEE","WET","WHO","WHY","WIG","WIN","WIT","WIZ","WOE","WOK","WON","WOO","WOW",
            "YAK","YAM","YAP","YEN","YEP","YES","YET","YEW","YIN","YOU","YUM","YUP",
            "ZAP","ZED","ZEN","ZIP","ZIT","ZOO",
        ]
        return Set(words.map { $0.lowercased() }.filter { $0.count == 3 })
    }()

    // MARK: - English 4-letter dictionary

    static let wordSet: Set<String> = {
        let words = [
            "ABLE","ACHE","ACID","ACNE","ACRE","ACTS","AGED","AIDE","AIDS","AIMS","AIRS","AIRY","ALSO","ALTO","ALUM","AMEN","AMMO","AMOK","ANTE","ANTI","ANTS","AQUA","ARCH","AREA","ARIA","ARID","ARMS","ARMY","ARTS","ATOM","AVID","AWAY","AXES",
            "BABE","BACK","BAIT","BAKE","BALD","BALE","BALL","BALM","BAND","BANE","BANG","BANK","BARE","BARK","BARN","BARS","BASE","BASH","BASK","BATH","BATS","BEAD","BEAK","BEAM","BEAN","BEAR","BEAT","BEEF","BEEN","BEER","BEES","BEET","BELL","BELT","BEND","BEST","BIAS","BIKE","BILL","BIND","BIRD","BITE","BITS","BLEW","BLOB","BLOG","BLOW","BLUE","BLUR","BOAR","BOAT","BODY","BOIL","BOLD","BOLT","BONE","BOOK","BOOM","BOOT","BORE","BORN","BOSS","BOTH","BOUT","BOWL","BRAG","BRAN","BRAT","BREW","BRIM","BROW","BUFF","BULB","BULK","BULL","BUMP","BUNK","BUOY","BURN","BURP","BURR","BURY","BUSH","BUSY","BUZZ",
            "CAGE","CAKE","CALF","CALL","CALM","CAME","CAMP","CANE","CARD","CARE","CARP","CART","CASE","CASH","CAST","CAVE","CELL","CHAI","CHAR","CHAT","CHEF","CHEW","CHIN","CHIP","CHOP","CITE","CITY","CLAM","CLAP","CLAW","CLAY","CLIP","CLOT","CLUE","COAL","COAT","CODE","COIL","COIN","COLD","COLT","COMA","COMB","COME","CONE","COOL","COPE","CORD","CORE","CORK","CORN","COST","COZY","CRAB","CROP","CROW","CUBE","CURL","CUTE",
            "DARK","DART","DASH","DATA","DATE","DAWN","DAYS","DEAD","DEAL","DEAN","DEAR","DECK","DEED","DEEP","DEER","DEFT","DENY","DESK","DICE","DIET","DIRE","DIRT","DISC","DISH","DISK","DIVE","DOCK","DOLL","DOME","DONE","DOOM","DOOR","DOSE","DOTE","DOVE","DOWN","DOZE","DRAG","DRAW","DREW","DRIP","DROP","DRUM","DUCK","DULL","DUMB","DUMP","DUSK","DUST","DUTY",
            "EACH","EARL","EARN","EASE","EAST","EASY","EDGE","EMIT","ENVY","EPIC","EVEN","EVER","EVIL","EXAM",
            "FACE","FACT","FADE","FAIL","FAIR","FALL","FAME","FANG","FARM","FAST","FATE","FAWN","FEAR","FEAT","FEED","FEEL","FEET","FELL","FELT","FEND","FERN","FLAW","FLEE","FLEW","FLEX","FLIP","FLOW","FOAM","FOLD","FOLK","FOND","FONT","FOOD","FOOL","FOOT","FORD","FORK","FORM","FORT","FOUL","FOUR","FOWL","FRAY","FRET","FROG","FROM","FUEL","FULL","FUME","FUND","FURY","FUSE",
            "GALE","GALL","GAME","GASP","GAVE","GAZE","GEAR","GERM","GIFT","GILL","GIVE","GLAD","GLEE","GLOB","GLUE","GOAL","GOAT","GOLF","GONG","GOOD","GORE","GOWN","GRAB","GRIM","GRIN","GRIP","GRIT","GROW","GULL","GUST","GUTS",
            "HACK","HAIL","HAIR","HALF","HALL","HALO","HALT","HAND","HANG","HARD","HARM","HARP","HASH","HATE","HAUL","HAVE","HAWK","HAZE","HAZY","HEAD","HEAL","HEAP","HEAR","HEAT","HEEL","HELL","HELM","HELP","HERB","HERD","HERO","HIGH","HILL","HINT","HIRE","HISS","HIVE","HOAX","HOLD","HOLE","HOLY","HOME","HONK","HOOD","HOOK","HORN","HOUR","HOWL","HULL","HUMP","HUNT","HURL","HYMN",
            "IDEA","IDLE","INCH","INTO","IRIS","IRON","ISLE","ITCH",
            "JACK","JADE","JAIL","JERK","JEST","JOLT","JUMP","JUST",
            "KEEN","KEEP","KELP","KICK","KILL","KIND","KING","KNOB","KNOT","KNOW",
            "LACE","LACK","LAID","LAKE","LAMB","LAMP","LAND","LANE","LAST","LAVA","LAWN","LAZY","LEAD","LEAF","LEAN","LEAP","LEND","LENS","LIAR","LIFT","LIKE","LIME","LIMP","LINK","LION","LIST","LIVE","LOAD","LOAN","LOCK","LOFT","LONE","LONG","LOOK","LOOM","LOOT","LORE","LOSE","LOSS","LOST","LOUD","LOVE","LUCK","LULL","LUMP","LURE","LURK",
            "MADE","MAID","MAIN","MAKE","MALE","MALL","MANE","MANY","MARK","MAST","MATH","MAZE","MEAL","MEAN","MEAT","MELT","MEMO","MERE","MESH","MICE","MILD","MILK","MILL","MINE","MINT","MIST","MOAN","MOCK","MOLD","MOLE","MOOD","MOON","MOOR","MORE","MOSS","MOST","MOTH","MOVE","MUCH","MUCK","MULE","MUSE","MUSK","MUTE","MYTH",
            "NAIL","NAME","NAVY","NECK","NEED","NEST","NEWS","NEXT","NICE","NICK","NINE","NODE","NONE","NOON","NORM","NOSE","NOTE","NUMB",
            "OATH","OBEY","ODDS","ODOR","OMEN","ONCE","ONLY","OPEN","ORAL","ORCA","OVEN","OVER",
            "PACE","PACK","PAGE","PAIN","PALM","PART","PASS","PAST","PATH","PAVE","PAWN","PEAK","PEEL","PEER","PEST","PICK","PIER","PILE","PINE","PINK","PIPE","PITY","PLAN","PLAY","PLEA","PLOT","PLOW","PLUG","PLUM","PLUS","POEM","POET","POLE","POND","PORE","PORT","POSE","POUR","PREY","PROP","PULL","PULP","PUMP","PURE","PUSH",
            "RAGE","RAID","RAIN","RAKE","RAMP","RANG","RANK","RARE","RASH","RASP","READ","REAL","REAP","REEF","REEL","RELY","RENT","ROBE","ROCK","RODE","ROLE","ROLL","ROOF","ROOK","ROOM","ROOT","ROPE","ROSE","RUDE","RUIN","RULE","RUMP","RUSH","RUST",
            "SAFE","SAGE","SAIL","SAKE","SALT","SAME","SAND","SANE","SANG","SANK","SAVE","SCAM","SCAN","SCAR","SEAM","SEED","SEEP","SELF","SELL","SHED","SHIN","SHIP","SHOE","SHOT","SHOW","SICK","SIGH","SILK","SILL","SING","SINK","SLAB","SLAM","SLAP","SLED","SLIM","SLIP","SLUG","SMUG","SNAP","SNOB","SNOW","SOAK","SOAP","SOAR","SOCK","SOFT","SOIL","SOLD","SOLE","SOME","SONG","SOON","SORT","SOUL","SOUP","SOUR","SPAN","SPIT","SPOT","SPUR","STAB","STAR","STAY","STEM","STEP","STEW","STIR","STOP","STUB","SUCH","SUIT","SULK","SUNG","SUNK","SURF","SWAP","SWAT","SWAY","SWIM",
            "TALE","TALL","TAME","TANG","TANK","TAPE","TART","TASK","TEAL","TEAR","TELL","TEND","TENT","TERM","TEST","THAN","THAT","THEN","THEY","THIN","THIS","TICK","TIDE","TILL","TILT","TIME","TOAD","TOIL","TOLD","TOLL","TOMB","TONE","TOOK","TOOL","TOSS","TOUR","TOWN","TREK","TRIM","TRIO","TRIP","TROT","TUCK","TUFT","TUSK","TWIN",
            "UGLY","UNDO","UNIT","UPON","USED","USER",
            "VAIN","VAST","VEIL","VEIN","VENT","VINE","VISE","VOTE",
            "WADE","WAGE","WAIT","WAKE","WALK","WALL","WAND","WARD","WARM","WARN","WARP","WART","WAVE","WEAK","WELD","WELL","WENT","WEST","WIDE","WILD","WILT","WIND","WINE","WING","WINK","WIRE","WISE","WISH","WOLF","WOMB","WOOD","WOOL","WORD","WORE","WORK","WORM","WORN","WREN",
            "YELL","YOGA","YOKE","YOLK","YOUR",
            "ZONE","ZOOM",
        ]
        return Set(words.map { $0.lowercased() }.filter { $0.count == 4 })
    }()

    // MARK: - English 5-letter dictionary

    static let fiveLetterWordSet: Set<String> = {
        let words = [
            "ABOUT","ABOVE","ABUSE","ADMIT","ADOPT","ADULT","AFTER","AGAIN","AGENT","AGREE","AHEAD","ALARM","ALBUM","ALERT","ALIVE","ALLEY","ALLOW","ALONE","ALONG","ALTER","ANGEL","ANGER","ANGRY","ANKLE","APPLY","ARMED","AROSE","ASIDE","ATLAS","ATTIC","AUDIO","AUDIT","AVOID","AWARD","AWARE","AWFUL",
            "BEACH","BEARD","BEAST","BENCH","BERRY","BLACK","BLADE","BLAME","BLANK","BLAST","BLAZE","BLEND","BLINK","BLOOD","BLOWN","BOARD","BORED","BOUND","BRAID","BRAKE","BRAND","BRAVE","BREAD","BREAK","BRIDE","BRIEF","BRING","BROAD","BROKE","BROOK","BROWN","BRUSH","BUILD","BUNCH","BURNT","BURST",
            "CABIN","CANDY","CARRY","CAUSE","CEDAR","CHAIN","CHAIR","CHALK","CHART","CHASE","CHEAP","CHEEK","CHESS","CHEST","CHIEF","CHILD","CHORD","CHUNK","CIVIC","CIVIL","CLAIM","CLASH","CLASS","CLEAN","CLEAR","CLICK","CLIFF","CLIMB","CLING","CLOCK","CLOSE","CLOTH","CLOUD","COAST","COBRA","COMET","CORAL","COUCH","COULD","COUNT","CRAFT","CRANE","CRASH","CREAM","CREEK","CRIME","CRISP","CROSS","CRUST","CURVE",
            "DAILY","DAIRY","DAISY","DANCE","DEATH","DECOR","DELAY","DENSE","DEPOT","DEPTH","DEVIL","DIRTY","DIZZY","DODGE","DOUGH","DOZEN","DRAFT","DRAIN","DRAMA","DRANK","DRAWN","DREAM","DRESS","DRIED","DRIFT","DRINK","DRIVE","DRONE","DROVE","DRUNK","DYING",
            "EAGLE","EARLY","EARTH","EIGHT","ELECT","EMPTY","ENEMY","ENJOY","ENTER","EQUAL","ESSAY","EVERY","EXACT","EXIST","EXTRA",
            "FABLE","FAINT","FAIRY","FAITH","FANCY","FAVOR","FEAST","FENCE","FERRY","FEVER","FIELD","FIFTH","FIFTY","FIGHT","FINAL","FIRST","FIXED","FLAME","FLASH","FLESH","FLOAT","FLOOD","FLOOR","FLOUR","FLUID","FLUSH","FLUTE","FOCUS","FORGE","FORTE","FORUM","FOUND","FRAME","FRANK","FRESH","FRONT","FROST","FROZE","FRUIT","FULLY","FUNNY",
            "GHOST","GIANT","GIVEN","GLASS","GLOBE","GLOOM","GLORY","GLOVE","GOING","GRACE","GRADE","GRAIN","GRAND","GRANT","GRASP","GRASS","GRAVE","GREAT","GREEN","GREET","GRIEF","GRIME","GRIND","GROAN","GROUP","GROVE","GROWN","GUARD","GUESS","GUEST","GUIDE",
            "HABIT","HAPPY","HARSH","HEART","HEAVY","HELLO","HERBS","HINGE","HIPPO","HONEY","HORSE","HOTEL","HOUSE","HOVER","HUMAN","HUMOR",
            "IMAGE","IMPLY","INNER","INPUT","ISSUE","IVORY",
            "JUDGE","JUICE","JUICY","JUMPY",
            "KAYAK","KNEEL","KNIFE","KNOCK","KNOWN",
            "LABEL","LANCE","LARGE","LASER","LAUGH","LAYER","LEAFY","LEARN","LEASE","LEASH","LEAST","LEMON","LEVEL","LIGHT","LIMIT","LINEN","LINER","LIVER","LOCAL","LODGE","LOGIC","LOWER",
            "MAGIC","MAJOR","MAKER","MAPLE","MARCH","MARSH","MATCH","MAYOR","MEDAL","MERCY","MERIT","MESSY","METAL","MIGHT","MINOR","MINUS","MOIST","MONEY","MONTH","MOTOR","MOUNT","MOUSE","MOUTH","MOVIE","MUDDY","MUSIC","MUSTY",
            "NAIVE","NASTY","NERVE","NEVER","NIGHT","NOBLE","NOISE","NORTH","NOVEL","NURSE",
            "OCCUR","OCEAN","OFFER","OFTEN","OLIVE","ORDER","OTHER","OUGHT","OUTER","OWNED",
            "PAINT","PANEL","PANIC","PAPER","PARTY","PASTA","PATCH","PAUSE","PEACE","PETAL","PHASE","PHONE","PHOTO","PIANO","PILOT","PINCH","PITCH","PIXEL","PLACE","PLAIN","PLANE","PLANT","PLATE","PLAZA","PLUCK","PLUMB","PLUME","POINT","POLAR","POUCH","POUND","POWER","PRESS","PRICE","PRIDE","PRIME","PRINT","PRIOR","PRISM","PRIZE","PROBE","PROOF","PROSE","PROUD","PROVE","PULSE","PURSE",
            "QUEEN","QUEST","QUICK","QUIET","QUILL","QUIRK","QUOTA","QUOTE",
            "RABBI","RADAR","RANGE","RAPID","RAVEN","REACH","READY","REALM","REBEL","REIGN","REPLY","RIDER","RIGHT","RISKY","RIVET","ROBIN","ROCKY","ROUGE","ROUGH","ROUND","ROYAL","RULER","RURAL",
            "SAINT","SALSA","SCOPE","SCOUT","SEDAN","SEIZE","SENSE","SERVE","SEVEN","SHADE","SHAKE","SHALL","SHAME","SHAPE","SHARE","SHARK","SHARP","SHEEN","SHEET","SHELF","SHELL","SHIFT","SHINY","SHORE","SHORT","SHOUT","SIGHT","SINCE","SIXTH","SIXTY","SKILL","SLACK","SLASH","SLATE","SLEEK","SLEEP","SLICK","SLIDE","SLOPE","SLOTH","SMART","SMELL","SMILE","SMOKE","SNACK","SNAKE","SNARL","SNEAK","SOLID","SOLVE","SPEAK","SPEED","SPELL","SPEND","SPICE","SPINE","SPIRE","SPOKE","SPOON","SPORT","SPRAY","STACK","STAFF","STAGE","STAIN","STAIR","STAKE","STALL","STAND","STARK","STATE","STEEL","STEEP","STEER","STERN","STICK","STILL","STOCK","STONE","STOOD","STOOL","STORE","STORM","STORY","STOVE","STRAP","STRAW","STRAY","STRIP","STUFF","STUMP","STYLE","SUGAR","SUITE","SUNNY","SUPER","SURGE","SWAMP","SWEAR","SWEEP","SWEET","SWIFT","SWIPE","SWIRL","SWORD",
            "TABLE","TAKEN","TASTE","TEACH","TENSE","THEFT","THEIR","THEME","THERE","THESE","THICK","THIEF","THING","THINK","THORN","THOSE","THROW","TIDAL","TIGER","TIGHT","TIRED","TOAST","TOKEN","TOTAL","TOUCH","TOUGH","TRACE","TRACK","TRADE","TRAIL","TRAIN","TRAIT","TRASH","TREAT","TREND","TRIAL","TRIBE","TRICK","TRIED","TROUT","TRUCE","TRUCK","TRUNK","TRUST","TRUTH","TULIP","TUMMY","TUTOR","TWINE","TWIST",
            "ULTRA","UNCLE","UNDER","UNION","UNITE","UNTIL","UPPER","UPSET","USHER","UTTER",
            "VALID","VALUE","VAPOR","VERSE","VIGOR","VIRAL","VIRUS","VISIT","VITAL","VIVID","VOCAL","VOTED",
            "WATER","WEARY","WEAVE","WEDGE","WEIRD","WHALE","WHEAT","WHEEL","WHERE","WHICH","WHILE","WHITE","WHOLE","WHOSE","WITCH","WOMAN","WORLD","WORRY","WORTH","WOULD","WOUND","WRATH","WRECK","WRIST","WRITE","WRONG","WROTE",
            "YACHT","YEARN","YIELD","YOUNG","YOUTH","YUMMY",
            "ZEBRA","ZESTY",
        ]
        return Set(words.map { $0.lowercased() }.filter { $0.count == 5 })
    }()

    // MARK: - English 6-letter dictionary

    static let sixLetterWordSet: Set<String> = {
        let words = [
            "ANIMAL","BEAUTY","BETTER","BOTTLE","BRIDGE","BRIGHT","BROKEN","BUTTON",
            "CANDLE","CASTLE","CATTLE","CHANGE","CHOOSE","CHURCH","CIRCLE","CORNER","COTTON","COUPLE","CREDIT",
            "DAMAGE","DANGER","DECIDE","DOUBLE","DURING",
            "ENERGY","ENOUGH","ESCAPE",
            "FACTOR","FAMILY","FATHER","FIGURE","FINGER","FOLLOW","FOREST","FORGET","FUTURE",
            "GARDEN","GATHER","GENTLE","GLOBAL","GOLDEN",
            "HANDLE","HAPPEN","HARDLY","HEALTH","HONEST","HUNGRY",
            "INCOME","ISLAND",
            "JUNGLE",
            "LAUNCH","LEADER","LIQUID","LISTEN","LITTLE","LIVELY","LOVELY",
            "MARKET","MASTER","MIGHTY","MIRROR","MODERN","MOTHER","MOTION","MOVING","MUSCLE",
            "NATURE","NEEDLE","NUMBER",
            "OBJECT","ONLINE","ORANGE","ORCHID","ORIGIN","OYSTER",
            "PARENT","PENCIL","PEOPLE","PERSON","PLANET","PLAYER","POCKET","POLICE","POWDER","PREFER","PRETTY","PRINCE","PROFIT","PURPLE",
            "RABBIT","RATHER","REASON","RECENT","REMAIN","RESCUE","RESULT","RETURN","REVIEW","REWARD","RIBBON","ROCKET","RUBBER",
            "SCHOOL","SECRET","SHADOW","SIGNAL","SIMPLE","SINGLE","SISTER","SLOWLY","SMOOTH","SOCCER","SORROW","SOURCE","SPIDER","SPRING","STRONG","SUMMER","SUNSET","SUPPLY",
            "TALENT","THRONE","TRAVEL",
            "UNFAIR","UNIQUE",
            "VALLEY","VIOLET","VIRTUE","VISION",
            "WINNER","WINTER","WISDOM","WONDER","WORKER",
            "YELLOW",
        ]
        return Set(words.map { $0.lowercased() }.filter { $0.count == 6 })
    }()

    // MARK: - Dutch word sets (3–10 letters)
    // Common Dutch words recognisable to casual Dutch speakers.

    static let dutchThreeLetterWordSet: Set<String> = {
        let words = ["aai","aak","aal","aan","aap","aar","aas","abt","ace","act","aft","aha","aio","air","alg","alk","alm","alp","als","alt","ara","are","ark","arm","art","aso","ast","ave","bad","baf","bah","bak","bal","ban","bar","bas","bat","bed","bef","bei","bek","bel","ben","beo","bes","bet","beu","bib","bic","bid","bie","big","bij","bik","bil","bio","bis","bit","blo","boa","bob","bod","boe","bof","bok","bol","bom","bon","bos","bot","box","boy","bug","bui","buk","bul","bun","bus","bye","cap","cel","ces","cis","col","cox","cru","cue","cup","dab","dag","dak","dal","dam","dan","dar","das","dat","dek","del","den","dep","der","des","dia","die","dij","dik","dim","dip","dis","dit","doe","dof","dog","dok","dol","dom","don","dop","dor","dos","dot","dra","dry","dub","duf","dun","duo","dus","dut","duw","dux","ebt","ecu","eed","eek","een","eer","eet","ego","egt","eik","eis","elf","elk","els","end","ene","eng","enk","ent","epo","era","ere","erf","erg","esp","ets","eva","fan","fat","fax","fee","fel","fep","fes","fez","fik","fis","fit","fix","fok","fop","fox","fut","gaf","gag","gal","gap","gas","gat","gay","gei","gek","gel","gen","ges","gif","gig","gij","gil","gin","gis","git","god","goh","goj","gok","gom","gul","gum","gun","gup","gut","gym","had","haf","hak","hal","ham","hap","har","heb","hef","heg","hei","hek","hel","hem","hen","her","hes","het","hex","hij","hik","hip","hit","hiv","hoe","hof","hoi","hok","hol","hom","hop","hor","hos","hot","hou","hub","hui","huk","hul","hum","hun","hup","hut","huw","iel","iep","iet","ijk","ijl","ijs","int","ion","jak","jam","jan","jap","jas","jat","jee","jen","jet","jeu","jid","jij","job","jog","joh","jok","jol","jon","jou","juf","juk","jus","jut","kaf","kak","kal","kam","kan","kap","kar","kas","kat","kef","keg","kei","kek","ken","keu","kid","kif","kik","kil","kim","kin","kip","kir","kis","kit","koe","kof","kog","kok","kol","kom","kon","kop","kor","kot","kou","kul","kun","kur","kus","kut","lab","laf","lag","lak","lal","lam","lap","las","lat","leb","led","lef","leg","lei","lek","lel","lep","les","let","lex","lid","lig","lij","lik","lil","lip","lis","lob","loc","lof","log","lok","lol","lom","lor","los","lot","lub","lui","luk","lul","lus","luw","lux","maf","mag","mak","mal","mam","man","map","mar","mat","max","mee","mei","mem","men","mep","mes","met","mie","mij","mik","min","mis","mix","moe","mof","mok","mol","mom","mop","mor","mos","mot","mud","muf","mug","mui","mul","mus","nae","nam","nap","nar","nas","nat","neb","nee","neg","nek","nel","nep","nes","net","ney","nik","nip","nis","nix","nog","nok","nol","non","nop","nor","nou","nuf","nuk","nul","nut","och","ode","oef","oei","oen","oer","ohm","oho","oio","oir","oke","olm","oma","ome","ons","oog","ooi","ook","oom","oor","opa","ore","oud","out","pad","paf","pak","pal","pan","pap","par","pas","pat","pax","pee","peg","pek","pel","pen","pep","per","pet","pij","pik","pil","pin","pip","pis","pit","plu","pof","pok","pol","pom","pon","pop","por","pos","pot","pre","pro","pst","pub","puf","pui","puk","pul","pup","pur","pus","put","qat","qua","rad","rag","rai","rak","ral","ram","rap","ras","rat","red","ree","rei","rek","rel","rem","ren","rep","reu","rex","rib","rif","rij","rik","ril","rip","ris","rit","rob","roe","rog","rok","rol","rop","ros","rot","rug","rui","ruk","rul","rum","run","rus","rut","ruw","sak","sap","sar","sas","sax","sec","set","sic","sik","sim","sip","sis","ska","ski","sla","soa","sof","sok","sol","som","sop","sou","spa","sta","sub","suf","sul","sus","tab","taf","tag","tak","tal","tam","tap","tas","tel","tem","ten","ter","tet","tic","tig","tij","tik","til","tin","tip","tja","tob","tod","toe","tof","tok","tol","ton","top","tor","tos","tot","tra","tri","try","tuf","tui","tuk","tul","tut","typ","ufo","uil","uit","ulo","ups","ure","urm","urn","uso","uur","uzi","vak","val","van","var","vat","vee","vei","vel","ven","ver","vet","via","vil","vim","vin","vip","vis","vit","vla","vlo","vod","vol","vos","vul","vut","wad","waf","wak","wal","wam","wan","war","was","wat","wax","web","wed","wee","weg","wei","wek","wel","wem","wen","wet","wie","wig","wij","wik","wil","win","wip","wis","wit","wok","wol","won","wou","wow","wui","yam","yel","yen","yes","yin","yup","zag","zak","zap","zat","zee","zeg","zei","zen","zes","zet","zie","zij","zin","zip","zit","zog","zon","zoo","zot","zou","zul","zus"]

        return Set(words.map { $0.lowercased() })
    }()

    static let dutchFourLetterWordSet: Set<String> = {
        let words = [
            "ACHT","BEEN","BEET","BERG","BIER","BLIK","BODE","BOER",
            "DIER","DIJK","DORP","DUIF","DUIM",
            "EEND","EURO",
            "FILM","FLAT",
            "GANG","GAST","GEEL","GEIT","GELD","GEUR","GLAS","GOLF","GOUD","GRAP",
            "HAAR","HAAS","HAAN","HEMD","HOEK","HOOP","HUID",
            "JONG",
            "KAAS","KALF","KAMP","KANT","KEEL","KERS","KIST","KLAP","KLAS","KLEI","KLOK","KLOS","KNIE","KOEL","KOUD","KOUS",
            "LANG","LANS","LEER","LIED","LINT","LOON",
            "MAAR","MAAT","MAND","MAST","MEEL","MEER","MIER","MOND","MUIS",
            "NAAM","NAAD","NEUS","NORM","NORS",
            "PAAR","PAAL","PACT","PAND","PARK","PERS","PIJN","PILS","PLAN","POLS",
            "RAAM","RAND","RANG","REEP","ROOK","ROOS","RUIM","RUPS",
            "SPAN","SPEK","SPIN","STER","STOK",
            "TAAL","TAND","TANG","TEEN","TENT","THEE","TONG","TRAM","TREK",
            "UIER",
            "VALS","VEEN","VELD","VERS","VEST","VLAK","VLAM","VLOT","VOOR","VORK","VUIL","VUUR",
            "WAND","WARM","WEET","WIJN","WIND","WOND",
            "ZAAL","ZAND","ZEEP","ZELF","ZIEL",
        ]
        return Set(words.map { $0.lowercased() })
    }()

    static let dutchFiveLetterWordSet: Set<String> = {
        let words = [
            "AARDE","AVOND",
            "BEEST","BEGIN","BEURT","BLAUW","BLIND","BLOED","BLOEM","BOVEN","BREED","BRIEF","BROOD","BRUIN","BUURT",
            "DATUM","DICHT","DRAAD",
            "EIGEN",
            "FEEST","FIETS","FLINK",
            "GELUK","GRAAN","GRENS","GROEN","GROND","GROOT",
            "HEMEL","HOREN",
            "KAART","KAMER","KAPOT","KASSA","KEREL","KLAAR","KLEED","KLEUR","KNOOP","KOERS","KOMST","KORTE","KRANT","KROON","KUNST",
            "LAARS","LAKEN","LATER","LEVEN","LICHT",
            "MACHT","NAAST","NACHT","NADER","NODIG",
            "PAREN","PAUZE",
            "RECHT","REGIO","RENTE","RIJKE","RIJST","RONDE",
            "SCHIP","SCHAT","SLAAP","SLAAN","SLANK","SMAAK","SOORT","SPOOR","SPORT","STAAL","STAND","START","STEEN","STEIL","STOEP",
            "TAFEL","TANTE","TEMPO","THUIS","TOETS","TONEN","TRAAG","TREIN","TROTS",
            "VAREN","VLEES","VUIST",
            "WAGEN","WAPEN","WEIDE","WOORD",
            "ZACHT","ZAKEN","ZEKER","ZOMER","ZWAAR","ZWAAN",
        ]
        return Set(words.map { $0.lowercased() })
    }()

    static let dutchSixLetterWordSet: Set<String> = {
        let words = [
            "ANDERS",
            "BERGEN","BEWUST",
            "DINGEN","DONKER","DORPEN",
            "EERDER","ENKELE",
            "FEITEN",
            "GELOOF","GEZOND",
            "HARDER","HELDER","HOEVEN",
            "IEMAND",
            "JONGEN",
            "KUNNEN",
            "LANGER","LIEVER",
            "MENSEN","METEEN","MORGEN",
            "NOEMEN",
            "PAKKEN",
            "RECHTS","REIZEN","RIJDEN",
            "SCHOOL","SLAPEN","SLAGEN","SPELEN","STROOM","STUREN",
            "TWEEDE",
            "VINDEN","VOLGEN","VROEGE",
            "WERELD","WORDEN","WORTEL",
            "ZEGGEN","ZETTEN","ZINNEN","ZOEKEN",
        ]
        return Set(words.map { $0.lowercased() })
    }()

    static let dutchSevenLetterWordSet: Set<String> = {
        let words = [
            "BEWONER",
            "DRINKEN",
            "EERLIJK","EENVOUD",
            "FAMILIE",
            "GRAPPIG",
            "KLEUREN",
            "LICHAAM",
            "RIJKDOM",
            "VERHAAL","VERTELD","VERTREK","VRIJDAG",
        ]
        return Set(words.map { $0.lowercased() })
    }()

    static let dutchEightLetterWordSet: Set<String> = {
        let words = [
            "BEWONERS",
            "FEESTDAG",
            "GEZONDER",
            "KINDEREN",
            "LEVENDIG",
            "MEUBELEN",
            "VRIJHEID",
        ]
        return Set(words.map { $0.lowercased() })
    }()

    static let dutchNineLetterWordSet: Set<String> = {
        let words = [
            "AFGELOPEN",
            "GEDACHTEN",
            "ONDERWIJS",
        ]
        return Set(words.map { $0.lowercased() })
    }()

    static let dutchTenLetterWordSet: Set<String> = {
        let words = [
            "BELANGRIJK",
            "GEZONDHEID",
            "SCHOONHEID",
        ]
        return Set(words.map { $0.lowercased() })
    }()

    // MARK: - Word Match

    struct WordMatch {
        let word: String
        let positions: [(row: Int, col: Int)]
    }

    // MARK: - Board Scanning

    /// Returns all word matches on the board for the given language.
    /// Scans horizontal and vertical windows of length 3 up to board.size.
    static func findMatches(in board: BoardModel, language: GameLanguage = .english) -> [WordMatch] {
        var matches: [WordMatch] = []
        let size = board.size

        for windowSize in 3...max(3, size) {
            let set = wordSetForLength(windowSize, language: language)
            guard !set.isEmpty else { continue }

            for r in 0..<size {
                for startC in 0...(size - windowSize) {
                    let positions = (startC..<startC+windowSize).map { (row: r, col: $0) }
                    if let match = matchAt(positions: positions, board: board, set: set) {
                        matches.append(match)
                    }
                }
            }

            for c in 0..<size {
                for startR in 0...(size - windowSize) {
                    let positions = (startR..<startR+windowSize).map { (row: $0, col: c) }
                    if let match = matchAt(positions: positions, board: board, set: set) {
                        matches.append(match)
                    }
                }
            }
        }
        return matches
    }

    static func wordSetForLength(_ length: Int, language: GameLanguage = .english) -> Set<String> {
        switch language {
        case .dutch:
            switch length {
            case 3:  return dutchThreeLetterWordSet
            case 4:  return dutchFourLetterWordSet
            case 5:  return dutchFiveLetterWordSet
            case 6:  return dutchSixLetterWordSet
            case 7:  return dutchSevenLetterWordSet
            case 8:  return dutchEightLetterWordSet
            case 9:  return dutchNineLetterWordSet
            case 10: return dutchTenLetterWordSet
            default: return []
            }
        default: // English (and other languages fall back to English for now)
            switch length {
            case 3: return threeLetterWordSet
            case 4: return wordSet
            case 5: return fiveLetterWordSet
            case 6: return sixLetterWordSet
            default: return []
            }
        }
    }

    private static func matchAt(positions: [(row: Int, col: Int)], board: BoardModel, set: Set<String>) -> WordMatch? {
        let tiles = positions.compactMap { board.tile(row: $0.row, col: $0.col) }
        guard tiles.count == positions.count else { return nil }
        let pattern = String(tiles.map { $0.isJoker ? "*" : $0.letter })
        guard let resolved = resolveWildcardWord(from: pattern, in: set) else { return nil }
        return WordMatch(word: resolved, positions: positions)
    }

    static func hasMatch(in board: BoardModel, language: GameLanguage = .english) -> Bool {
        !findMatches(in: board, language: language).isEmpty
    }

    /// Validate an arbitrary sequence of letters (for drawn words).
    static func isValidWord(_ word: String, language: GameLanguage = .english) -> Bool {
        let lower = word.lowercased()
        let length = lower.count
        return resolveWildcardWord(from: lower, in: wordSetForLength(length, language: language)) != nil
    }

    private static func resolveWildcardWord(from pattern: String, in set: Set<String>) -> String? {
        let lower = pattern.lowercased()
        if !lower.contains("*") {
            return set.contains(lower) ? lower : nil
        }

        let chars = Array(lower)
        for candidate in set {
            let candidateChars = Array(candidate)
            guard candidateChars.count == chars.count else { continue }

            var matches = true
            for i in chars.indices {
                let ch = chars[i]
                if ch != "*" && ch != candidateChars[i] {
                    matches = false
                    break
                }
            }
            if matches { return candidate }
        }
        return nil
    }
}
