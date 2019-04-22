pragma solidity ^0.4.23;

import "./Ownable.sol";

contract Blocklords is Ownable {

/////////////////////////////////////   Constants    ////////////////////////////////////////////////

  // Market Durations
  uint constant HOURS_8       = 28800;      // 28_800 Seconds are 8 hours
  uint constant HOURS_12      = 43200;     // 43_200 Seconds are 12 hours
  uint constant HOURS_24      = 86400;     // 86_400 Seconds are 24 hours

  // Battle Results
  uint constant ATTACKER_WON  = 1;
  uint constant ATTACKER_LOSE = 2;

  // Battle Types
  uint constant PVP= 1;       // Player Against Player at the Strongholds
  uint constant PVC= 2;       // Player Against City
  uint constant PVE= 3;       // Player Against NPC on the map

  // Fee Key Constants
  string constant HERO_CREATION_FEE         = "HERO_CREATION_FEE"; //= 500000000; //TRX in SUN, 1 TRX * 1000000
  string constant REFERAL_FEE               = "REFERAL_FEE";// = 250000000;
  string constant HOURS_8_FEE               = "HOURS_8_FEE";// =   50000000;
  string constant HOURS_12_FEE              = "HOURS_12_FEE";// =  70000000;
  string constant HOURS_24_FEE              = "HOURS_24_FEE";// = 88000000;
  string constant PVC_FEE                   = "PVC_FEE";// = 200000000;
  string constant PVE_FEE                   = "PVE_FEE";// = 50000000;
  string constant PVP_FEE                   = "PVP_FEE";// = 100000000;
  string constant PURCHASE_PERCENTS         = "PURCHASE_PERCENTS";// = 115;
  string constant LORD_PERCENTS             = "LORD_PERCENTS";// = 10;
  string constant SELLING_COFFER_PERCENTS   = "SELLING_COFFER_PERCENTS";  // 50
  string constant PVC_COFFER_PERCENTS       = "PVC_COFFER_PERCENTS";  // 50
  string constant COFFER_PAY_PERCENTS       = "COFFER_PAY_PERCENTS";  // 30
  string constant COFFER_REMAINING_PERCENTS = "COFFER_REMAINING_PERCENTS";  // 70

  string constant COFFER_INTERVAL_BLOCKS     = "COFFER_INTERVAL_BLOCKS";  // 150 000
  string constant ITEM_DROP_INTERVAL_BLOCKS = "ITEM_DROP_INTERVAL_BLOCKS"; // 800

  // Item Batch Type
  uint constant STRONGHOLD_REWARD_BATCH = 0;

/////////////////////////////////////   Options    /////////////////////////////////////
  mapping ( string => uint ) options;

  function setOption(string key, uint value) public onlyOwner {
    options[key] = value;
  }

  function getOption(string key) public view returns (uint) {
    return options[key];
  }

/////////////////////////////////////   Coffers    /////////////////////////////////////

  uint coffersTotal = allCoffers();

  function getBalance() public view returns(uint) {
      return address(this).balance;
  }

  function withdraw(uint amount) public returns(bool) { //  withdraw  only to owner's address
      if (amount == 0)
           amount = getBalance();
      uint coffers = allCoffers();
      require(amount - coffers > 0, "GENERALLY_NOT_ENOUGH_MONEY");  // Umcomment this requirement if you want the amount stored in coffers to be not withdrawable
      address owner_ = owner();
      owner_.transfer(amount - coffers);
      return true;
  }

  function random(uint entropy, uint number) private view returns (uint8) {
       // NOTE: This random generator is not entirely safe and   could potentially compromise the game,
          return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%number);
     }

  function randomFromAddress(address entropy) private view returns (uint8) {
         return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%256);
   }

///////////////////////////////////// HERO STRUCT ////////////////////////////////////////////////

    struct Hero{
        address OWNER;     // Wallet address of Player that owns Hero
        uint LEADERSHIP;   // Leadership Stat value
        uint INTELLIGENCE; // Intelligence Stat value
        uint STRENGTH;     // Strength Stat value
        uint SPEED;        // Speed Stat value
        uint DEFENSE;      // Defense Stat value
        uint CREATED_TIME;
    }

    mapping (uint => Hero) heroes;
    mapping (address => uint) playerHeroes;

    function getPlayerHeroId(address heroOwner) public view returns(uint) {
      if (heroOwner != 0x0000000000000000000000000000000000000000)
        return playerHeroes[heroOwner];
      return playerHeroes[msg.sender];
    }

    event HeroCreation(address creator, uint id);
    event HeroCreationWithReferalLink(address creator, uint id, address referer_address);

    function putHero(uint id, uint referer_id, address referer_address, uint[] heroStats, uint[] heroItems, uint8 v, bytes32[2] rs) public payable returns(bool){
      require(playerHeroes[msg.sender] == 0, "PLAYER_ALREADY_HAVE_A_HERO");
            require(id > 0, "HERO_ID_MUST_BE_HIGHER");
            //require(payments[id].PAYER == owner, "Payer and owner do not match");
            require(heroes[id].OWNER == 0x0000000000000000000000000000000000000000, "HERO_MUST_NOT_BE_ON_BLOCKCHAIN");
            require(msg.value == options[HERO_CREATION_FEE], "HERO_CREATION_MUST_HAVE_CORRECT_ATTACHMENT");
            require(msg.sender != owner(), "GAME_ADMIN_CAN_NOT_PLAY_GAME");

            if (referer_id > 0) {
                require(heroes[referer_id].OWNER == referer_address, "REFERER_NOT_EXISTS");
                require(referer_address.send(options[REFERAL_FEE]), "REFERER_CAN_NOT_ACCEPT_YOUR_TRANSFERS");
                emit HeroCreationWithReferalLink(msg.sender, id, referer_address);
            }

            require(stronghold_rewards_batch[heroItems[0]] == 0, "ITEM_IN_STRONGHOLD_REWARD_BATCH");
            require(stronghold_rewards_batch[heroItems[1]] == 0, "ITEM_IN_STRONGHOLD_REWARD_BATCH");
            require(stronghold_rewards_batch[heroItems[2]] == 0, "ITEM_IN_STRONGHOLD_REWARD_BATCH");
            require(stronghold_rewards_batch[heroItems[3]] == 0, "ITEM_IN_STRONGHOLD_REWARD_BATCH");
            require(stronghold_rewards_batch[heroItems[4]] == 0, "ITEM_IN_STRONGHOLD_REWARD_BATCH");

            require(items[heroItems[0]].OWNER == owner(), "ITEM_IS_NOT_IN_BLOCKCHAIN");
            require(items[heroItems[0]].STAT_TYPE == 1, "ITEM_TYPE_IS_NOT_VALID");

            require(items[heroItems[1]].OWNER == owner(), "ITEM_IS_NOT_IN_BLOCKCHAIN");
            require(items[heroItems[1]].STAT_TYPE == 2, "ITEM_TYPE_IS_NOT_VALID");

            require(items[heroItems[2]].OWNER == owner(), "ITEM_IS_NOT_IN_BLOCKCHAIN");
            require(items[heroItems[2]].STAT_TYPE == 3, "ITEM_TYPE_IS_NOT_VALID");

            require(items[heroItems[3]].OWNER == owner(), "ITEM_IS_NOT_IN_BLOCKCHAIN");
            require(items[heroItems[3]].STAT_TYPE == 4, "ITEM_TYPE_IS_NOT_VALID");

            require(items[heroItems[4]].OWNER == owner(), "ITEM_IS_NOT_IN_BLOCKCHAIN");
            require(items[heroItems[4]].STAT_TYPE == 5, "ITEM_TYPE_IS_NOT_VALID");

            require(heroStats[0] > 0, "STAT_MUST_BE_HIGHER");
            require(heroStats[1] > 0, "STAT_MUST_BE_HIGHER");
            require(heroStats[2] > 0, "STAT_MUST_BE_HIGHER");
            require(heroStats[3] > 0, "STAT_MUST_BE_HIGHER");
            require(heroStats[4] > 0, "STAT_MUST_BE_HIGHER");

            require(v > 0, "SIGNATURE_PARAMETER_IS_INVALID");
            require(checkHeroCreationSign(id, heroStats, heroItems, v, rs), "SIGNATURE_VALIDATION_FAILED");

            //delete payments[id]; // delete payment hash after the hero was created in order to prevent double spend
            heroes[id] = Hero(msg.sender, heroStats[0], heroStats[1],  heroStats[2], heroStats[3], heroStats[4], block.number);
            playerHeroes[msg.sender] = id;

            items[heroItems[0]].OWNER = msg.sender;
            items[heroItems[1]].OWNER = msg.sender;
            items[heroItems[2]].OWNER = msg.sender;
            items[heroItems[3]].OWNER = msg.sender;
            items[heroItems[4]].OWNER = msg.sender;

            emit HeroCreation(msg.sender, id);

            return true;
    }


    function getHero(uint id) public view returns(address, uint, uint, uint, uint, uint, uint){
        return (heroes[id].OWNER, heroes[id].LEADERSHIP, heroes[id].INTELLIGENCE, heroes[id].STRENGTH, heroes[id].SPEED, heroes[id].DEFENSE, heroes[id].CREATED_TIME);
    }

////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////// ITEM STRUCT //////////////////////////////////////////////////

    struct Item{

        uint STAT_TYPE; // Item can increase only one stat of Hero, there are five: Leadership, Defense, Speed, Strength and Intelligence
        uint QUALITY; // Item can be in different Quality. Used in Gameplay.

        uint GENERATION; // Items are given to Players only as a reward for holding Strongholds on map, or when players create a hero.
                         // Items are given from a list of items batches. Item batches are putted on Blockchain at once by Game Owner.
                         // Each of Item batches is called as a generation.

        uint STAT_VALUE;
        uint LEVEL;
        uint XP;         // Each battle where, Item was used by Hero, increases Experience (XP). Experiences increases Level. Level increases Stat value of Item
        address OWNER;   // Wallet address of Item owner.
    }

    mapping (uint => Item) public items;

    // battle id > item id
    mapping (uint => uint) public updated_items;

    // creationType StrongholdReward: 0, createHero 1
    function putItem (
      uint creationType,
      uint id,
      uint statType,
      uint quality,
      uint generation,
      uint statValue
    ) public onlyOwner {
      require( id > 0, "ITEM_ID_MUST_BE_HIGHER" );
      require( items[id].OWNER == 0x0000000000000000000000000000000000000000, "ITEM_IN_BLOCKCHAIN" );

      items[id] = Item(statType, quality, generation, statValue, 0, 0, msg.sender);

      if ( creationType == STRONGHOLD_REWARD_BATCH ) {
        addStrongholdReward( id );     //if putItem(stronghold reward) ==> add to StrongholdReward
      }
    }

    function getItem(uint id) public view returns(uint, uint, uint, uint, uint, uint, address){
      return (items[id].STAT_TYPE, items[id].QUALITY, items[id].GENERATION, items[id].STAT_VALUE, items[id].LEVEL, items[id].XP, items[id].OWNER);
    }

    function getUpdatedItem(uint battleId) public view returns(uint) {
      return updated_items[battleId];
    }

    function isUpgradableItem(uint id) private view returns (bool){
      if (id == 0) return false;
      if (items[id].STAT_VALUE == 0) return false;

      if (items[id].QUALITY == 1 && items[id].LEVEL == 3) return false;
      if (items[id].QUALITY == 2 && items[id].LEVEL == 5) return false;
      if (items[id].QUALITY == 3 && items[id].LEVEL == 7) return false;
      if (items[id].QUALITY == 4 && items[id].LEVEL == 9) return false;
      if (items[id].QUALITY == 5 && items[id].LEVEL == 10) return false;

      return true;
    }

    function updateItemsStats(uint[5] itemIds, uint battleId, uint battleResult) public {
      uint zero = 0;
      uint[5] memory existedItems = [zero, zero, zero, zero, zero];
      uint itemIndexesAmount = zero;

      for (uint i=zero; i<itemIds.length; i++) {
          // Check if Exp can be increased
          if (isUpgradableItem(itemIds[i])) {

            existedItems[itemIndexesAmount] = itemIds[i];
            itemIndexesAmount++;
          }
      }

      // No Upgradable Items
      if (itemIndexesAmount == zero) {
        return;
      }

      uint seed = block.number + randomFromAddress(msg.sender) + getBalance();
      uint randomIndex = random(seed, itemIndexesAmount);
      randomIndex--; // It always starts from 1. While arrays start from 0

      uint id = existedItems[randomIndex];

      // Increase XP that represents on how many battles the Item was involved into
      if (battleResult == ATTACKER_WON)
        items[id].XP = items[id].XP + 2;
      else
        items[id].XP = items[id].XP + 1;

      // Increase Level
      if (
                items[id].LEVEL == 0 && items[id].XP >= 2 ||
                items[id].LEVEL == 1 && items[id].XP >= 6 ||
                items[id].LEVEL == 2 && items[id].XP >= 20 ||
                items[id].LEVEL == 3 && items[id].XP >= 48 ||
                items[id].LEVEL == 4 && items[id].XP >= 92 ||
                items[id].LEVEL == 5 && items[id].XP >= 152 ||
                items[id].LEVEL == 6 && items[id].XP >= 228 ||
                items[id].LEVEL == 7 && items[id].XP >= 318 ||
                items[id].LEVEL == 8 && items[id].XP >= 434 ||
                items[id].LEVEL == 9 && items[id].XP >= 580
      ) {
        items[id].LEVEL = items[id].LEVEL + 1;
        items[id].STAT_VALUE = items[id].STAT_VALUE + 1;
        // return "Item level is increased by 1";
      }

      updated_items[battleId] = id;
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////// MARKET ITEM STRUCT ///////////////////////////////////////////////

    struct MarketItemData{

            uint Price; // Fixed Price of Item defined by Item owner
            uint Duration; // 8, 12, 24 hours
            uint CreatedTime; // Unix timestamp in seconds
            uint City; // City ID (item can be added onto the market only through cities.)
            address Seller; // Wallet Address of Item owner
            // bytes32 TX; // Transaction ID, (Transaction that has a record of Item Adding on Market)

    }

    mapping (uint => MarketItemData) market_items_data;

    function addMarketItem(uint itemId, uint price, uint duration, uint city) public payable { // START AUCTION FUNCTION
      require(msg.sender != owner(),                                                      "GAME_OWNER_IS_NOT_ALLOWED_TO_PLAY_GAME");
            require(items[itemId].OWNER == msg.sender,                                    "MARKET_ITEM_MUST_BE_MANAGED_BY_OWNER");
            require(price > 0,                                                            "MARKET_ITEM_PRICE_MUST_BE_HIGHER");
            require(duration == HOURS_8 || duration == HOURS_12 || duration == HOURS_24,  "MARKET_ITEM_MUST_HAVE_VALID_DURATION");
            require(hasCorrectMarketFee(duration),                                        "MARKET_ITEM_MUST_HAVE_CORRECT_FEE");
            if (market_items_data[itemId].City != 0) {
              bool notExpired = market_items_data[itemId].CreatedTime+market_items_data[itemId].Duration>now;
              if (!notExpired) {
                uint cityId2 = market_items_data[itemId].City;
                cities[cityId2].MarketAmount = cities[cityId2].MarketAmount - 1;

                delete market_items_data[itemId];
              }
              else {
                require(!notExpired, "MARKET_ITEM_ALREADY_IN_BLOCKCHAIN");
              }
            }
            /* require(removeMarketItemIfExpired(itemId),                                    "MARKET_ITEM_IN_BLOCKCHAIN_AND_ITS_DURATION_DID_NOT_EXPIRED"); */
            require(cities[city].MarketCap > cities[city].MarketAmount,                  "MARKET_ITEM_MUST_CAN_NOT_BE_PUT_ON_FULL_MARKET"); // Also Checks that city exists

            if ( options[SELLING_COFFER_PERCENTS] > 0) {
              uint coffer = msg.value / 100 * options[SELLING_COFFER_PERCENTS];
              cities[city].CofferSize = cities[city].CofferSize + coffer;
            }

            cities[city].MarketAmount = cities[city].MarketAmount + 1;

            market_items_data[itemId] = MarketItemData(price, duration, now, city, msg.sender);
    }

    // It returns false, if item duration did mpt expire
    /* function removeMarketItemIfExpired (uint itemId) internal returns(bool) {
      if (market_items_data[itemId].Cmd != 0x0000000000000000000000000000000000000000) {
        if (market_items_data[itemId].CreatedTime+market_items_data[itemId].Duration>=now) {

          uint cityId = market_items_data[itemId].City;
          cities[cityId].MarketAmount = cities[cityId].MarketAmount - 1;

            delete market_items_data[itemId];
        } else {
          return false;
        }
      }
      return true;
    } */

    function hasCorrectMarketFee(uint duration) internal view returns(bool) {
      if (duration == HOURS_8){
          return msg.value == options[HOURS_8_FEE];
      } else if (duration == HOURS_12){
          return msg.value == options[HOURS_12_FEE];
      } else if (duration == HOURS_24){
          return msg.value == options[HOURS_24_FEE];
      }
      return false;
    }
//
    function getMarketItem(uint itemId) public view returns(uint, uint, uint, uint, address){
            return(market_items_data[itemId].Price, market_items_data[itemId].Duration, market_items_data[itemId].CreatedTime, market_items_data[itemId].City, market_items_data[itemId].Seller);
    }

    function buyMarketItem(uint itemId) public payable returns(string) {
      require(msg.sender != market_items_data[itemId].Seller,                                   "MARKET_ITEM_CAN_NOT_BE_BOUGHT_BY_SELLER");
      require(msg.value == (market_items_data[itemId].Price / 100 * options[PURCHASE_PERCENTS]),   "MARKET_ITEM_MUST_HAVE_CORRECT_ATTACHMENT"); // check transaction amount
      bool notExpired = false;
      notExpired = market_items_data[itemId].CreatedTime+market_items_data[itemId].Duration>now;
      if (!notExpired) {
        uint cityId2 = market_items_data[itemId].City;
        cities[cityId2].MarketAmount = cities[cityId2].MarketAmount - 1;

        delete market_items_data[itemId];

        return("MARKET_ITEM_ALREADY_EXPIRED");
      }
      /* require(removeMarketItemIfExpired(itemId),                                               "MARKET_ITEM_DURATION_NOT_EXPIRED"); */
      require(market_items_data[itemId].City != 0,   "MARKET_ITEM_NOT_IN_BLOCKCHAIN");

        uint cityId = market_items_data[itemId].City; // get the city id

        uint cityHero = cities[cityId].Hero;  // get the hero id
        address cityOwner = heroes[cityHero].OWNER; // get the hero owner
        address seller = market_items_data[itemId].Seller;

        cities[cityId].MarketAmount = cities[cityId].MarketAmount - 1;

        uint zero = 0;
        if (cityHero != zero)
        {
            uint lordFee = msg.value / options[PURCHASE_PERCENTS] * options[LORD_PERCENTS];
            cityOwner.transfer(lordFee); // send 10% to city owner
        }

        seller.transfer(market_items_data[itemId].Price); // send 100% to seller
        items[itemId].OWNER = msg.sender; // change owner
        delete market_items_data[itemId]; // delete auction
        return "Was paid";
    }
    function deleteMarketItem(uint itemId) public {
        require(market_items_data[itemId].Seller == msg.sender, "MARKET_ITEM_MUST_BE_MANAGED_BY_OWNER");
        cities[market_items_data[itemId].City].MarketAmount = cities[market_items_data[itemId].City].MarketAmount - 1;
        delete market_items_data[itemId];
        /* return true; */
    }


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////// CITY STRUCT //////////////////////////////////////////////////////////

    struct City{

        uint ID; // city ID
        uint Hero;  // id of the hero owner
        uint Size; // BIG, MEDIUM, SMALL
        uint CofferSize; // size of the city coffer
        uint CreatedBlock;
        uint MarketCap;
        uint MarketAmount;
    }

    uint cityAmount = 0;
    mapping(uint => City) public cities;

    // cap argument is market capacity
    function putCity(uint id, uint size, uint cofferSize, uint cap) public payable onlyOwner {
        require(msg.value == cofferSize, "CITY_MUST_HAVE_CORRECT_COFFER");
        require(cities[id].ID == 0, "CITY_ALREADY_DEFINED");
        require(id > 0, "CITY_MUST_HAVE_HIGHER_ID");
        cities[id] = City(id, 0, size, cofferSize, block.number, cap, 0 );
        cityAmount = cityAmount + 1;
    }

    function getCity(uint id) public view returns(uint, uint, uint, uint, uint, uint){
        return (cities[id].Hero, cities[id].Size, cities[id].CofferSize, cities[id].CreatedBlock, cities[id].MarketCap, cities[id].MarketAmount);
    }

    function getCityAmount() public view returns(uint) {
      return cityAmount;
    }

    function allCoffers() public view returns(uint){
        uint total = 0;
        for (uint i=1; i < cityAmount ; i++){
            total += cities[i].CofferSize;
        }
        return total;
    }

    uint cofferBlockNumber = block.number;

    function payCoffers() public {   // drop coffer (every 25 000 blocks) ==> 30% coffer goes to cityOwner
        require(block.number-cofferBlockNumber > options[COFFER_INTERVAL_BLOCKS], "COFFER_PAYING_IS_TOO_EARLY");

        cofferBlockNumber = block.number; // this function can be called every "cofferBlockNumber" blocks

        for (uint cityNumber=1; cityNumber < cityAmount ; cityNumber++){ // loop through each city

            uint cityHero = cities[cityNumber].Hero;

            if (heroes[cityHero].OWNER != 0x0000000000000000000000000000000000000000) {
              address heroOwner = heroes[cityHero].OWNER;
              uint transferValue = (cities[cityNumber].CofferSize/100)*options[COFFER_PAY_PERCENTS];
              cities[cityNumber].CofferSize = (cities[cityNumber].CofferSize/100)*options[COFFER_REMAINING_PERCENTS];
              heroOwner.transfer(transferValue);
            } // else it is goes to nowhere, which means will stay on contract and will be transferred NPC owner.
        }
    }

    function getCoffersBlock() public view returns(uint) {
      return (cofferBlockNumber);
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////// STRONGHOLD STRUCT //////////////////////////////////////////////////////////

    struct Stronghold{
        uint ID;           // Stronghold ID
        uint Hero;         // Hero ID, that occupies Stronghold on map
        uint CreatedBlock; // The Blockchain Height

    }

    uint strongholdAmount = 0;
    mapping(uint => Stronghold) public strongholds;


    function getStronghold(uint shId) public view returns(uint, uint){
            return(strongholds[shId].Hero, strongholds[shId].CreatedBlock);
    }

    function putStronghold(uint shId) public {
      require(shId > 0, "STRONGHOLD_ID_MUST_BE_HIGHER");
      require(strongholds[shId].CreatedBlock == 0, "STRONGHOLD_CAN_NOT_BE_OVERRITTEN");

        strongholds[shId] = Stronghold(shId, 0, block.number);
        strongholdAmount = strongholdAmount + 1;
    }

    function isStrongholdOwner(uint hId) internal view returns(bool) {
      uint zero = 0;
      if (hId != zero) {
        for(uint i=1; i<strongholdAmount; i++) {
          if (strongholds[i].Hero == hId) {
            return true;//, "Hero can hold only one stronghold");
          }
        }
      }
      return false;
    }

/////////////////////////////////////// STRONGLOHD REWARD STRUCT /////////////////////////////////////////////////////////

    mapping (uint => uint) public stronghold_rewards_batch;

    function addStrongholdReward(uint id) public onlyOwner{
        stronghold_rewards_batch[id] = block.number;
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////// BATTLELOG STRUCT /////////////////////////////////////////////////////////

    struct BattleLog{

        uint[2] BattleResultType; // BattleResultType[0]: 0 - Attacker WON, 1 - Attacker Lose ; BattleResultType[1]: 0 - City, 1 - Stronghold, 2 - Bandit Camp
        uint Attacker;
        uint[2] AttackerTroops;       // Attacker's troops amount that were involved in the battle & remained troops
        uint[5] AttackerItems;        // Item IDs that were equipped by Attacker during battle.
        uint DefenderObject;   // City|Stronghold|NPC ID based on battle type
        uint Defender;         // City Owner ID|Stronghold Owner ID or NPC ID
        uint[2] DefenderTroops;
        uint[5] DefenderItems;
        uint Time;             // Unix Timestamp in seconds. Time, when battle happened
        // bytes32 TX;                   // Transaction where Battle Log was recorded.
        }

    mapping(uint => BattleLog) public battle_logs;

    // result type: win or lose/ battle type
    // last parameter 'dropItem' is only for contest version of game
    function addBattleLog(
      uint id, // Battle ID
      uint[2] resultType,
      uint attacker, // Attacker ID
      uint[2] attackerTroops,
      uint[5] attackerItems,
      uint defenderObject, // Bandit Camp ID, Stronghold ID or City ID
      uint defender,  // Defender Lord ID
      uint[2] defenderTroops,
      uint[5] defenderItems,
      uint8 v, bytes32[2] rs )
      //, uint itemDrop*/)
          public payable {
            require(msg.sender != owner(), "BATTLE_LOG_IS_NOT_CONSIDERING_GAME_DEVELOPER_AS_PLAYER");
            require(battle_logs[id].Attacker == 0, "BATTLE_LOG_IS_ON_BLOCKCHAIN");
            /* require(resultType.length == 2, "BATTLE_LOG_MUST_HAVE_RESULT_PARAMETER"); */
            require(resultType[0] >= 1 && resultType[0] <= 2, "BATTLE_LOG_MUST_HAVE_CORRECT_RESULT_PARAMETER");
            require(resultType[1] >= 1 && resultType[1] <= 3, "BATTLE_LOG_MUST_HAVE_CORRECT_TYPE_PARAMETER");
            /* require(attackerTroops.length == 2, "BATTLE_LOG_MUST_HAVE_ATTACKER_TROOPS_PARAMETER"); */
            /* require(attackerItems.length == 5, "BATTLE_LOG_MUST_HAVE_ATTACKER_ITEMS_LIST_PARAMETER"); */
            /* require(defenderTroops.length == 2, "BATTLE_LOG_MUST_HAVE_DEFENDER_TROOPS_PARAMETER"); */
            /* require(defenderItems.length ==5, "BATTLE_LOG_MUST_HAVE_DEFENDER_ITEMS_LIST_PARAMETER"); */
            require(hasCorrectBattleFeeAndNotStrongholdOwner(resultType[1], attacker), "BATTLE_LOG_MUST_HAVE_CORRECT_FEE_OR_LORD_IS_STRONGHOLD_OWNER");
            require(checkBattleLogSign(id, resultType, attacker, attackerTroops,attackerItems,defenderObject, defender,defenderTroops,defenderItems, v, rs), "SIGNATURE_VALIDATION_FAILED");

            battle_logs[id] = BattleLog(resultType, attacker, attackerTroops,
                                        attackerItems, defenderObject, defender,
                                        defenderTroops, defenderItems, now); //add data to the struct

            uint zero = 0;

            if (resultType[0] == ATTACKER_WON && resultType[1] == PVP){
                strongholds[defenderObject].Hero = attacker; // if attack Stronghold && WIN ==> change stronghold Owner
                strongholds[defenderObject].CreatedBlock = block.number;
            } else if (resultType[1] == PVC) {
              if (options[PVC_FEE] != zero && options[PVC_COFFER_PERCENTS] != zero ) {
                cities[defenderObject].CofferSize = cities[defenderObject].CofferSize + (options[PVC_FEE] / 100 * options[PVC_COFFER_PERCENTS]);
              }
              if (resultType[0] == ATTACKER_WON) {
                cities[defenderObject].Hero = attacker; // else if attack City && WIN ==> change city owner
                cities[defenderObject].CreatedBlock = block.number;
              }
            } else if (resultType[1] == PVE){
                updateItemsStats(attackerItems, id, resultType[0]);     // else if attackBandit ==> update item stats
            }
    }

    function hasCorrectBattleFeeAndNotStrongholdOwner(uint battleType, uint attacker) internal view returns(bool) {
      if (battleType == PVC){ // options[PVC_FEE] if atack City
          return (msg.value == options[PVC_FEE]);
      } else if (battleType == PVP){ // options[PVP_FEE] if atack Stronghold
          if (msg.value == options[PVP_FEE]) {
            return !isStrongholdOwner(attacker);
          }
      } else if (battleType == PVE){ // options[PVE_FEE] if atack Bandit Camp
          return (msg.value == options[PVE_FEE]);
      }

      return false;
    }


////////////////////////////////////////// DROP DATA STRUCT ///////////////////////////////////////////////////

    struct DropData{       // Information of Item that player can get as a reward.
        uint Block;        // Blockchain Height, in which player got Item as a reward
        uint StrongholdId; // Stronghold on the map, for which player got Item
        uint ItemId;       // Item id that was given as a reward
        uint HeroId;
        uint PreviousBlock;
    }

    uint blockNumber = block.number;

    mapping(uint => DropData) public stronghold_reward_logs;

    function getDropItemBlock() public view returns(uint) {
      return (blockNumber);
    }

    function straightDropItems(uint itemId) internal returns (string) {
      require(strongholdAmount > 0, "How can you drop Items. Initialize Strongholds first");
      uint zero = 0;

      //uint seed = block.number + item.GENERATION+item.LEVEL+item.STAT_VALUE+item.XP + itemIds.length + randomFromAddress(item.OWNER); // my poor attempt to make the random generation a little bit more random
      // Update Block
      uint previousBlock = blockNumber;
      blockNumber = block.number; // this function can be called every "blockDistance" blocks

      uint seed = block.number + randomFromAddress(msg.sender) + getBalance();

      uint id = random(seed, strongholdAmount);

      uint lordId = strongholds[id].Hero;

      delete stronghold_rewards_batch[itemId]; //delete item from strongHold reward struct
      strongholds[id].CreatedBlock = block.number;

      // Stronghold is occupied by NPC
      if (lordId == zero) {
        delete items[itemId];
        return(strConcat(uint2str(id), "", "", " index numbered stornghold lord is NPC. Should be given item for drop with id: ", uint2str(itemId) ) );
      }

      items[itemId].OWNER = heroes[lordId].OWNER;

      // Kick out from Stronghold
      strongholds[id].Hero = zero;

      stronghold_reward_logs[blockNumber] = DropData(blockNumber, id, itemId, lordId, previousBlock); //add data to the struct

      // return ("Supreme success");
      return(strConcat(uint2str(id), "", "", "is generated id for drop id: ", uint2str(itemId) ) ); // check if hero exist
    }


    function dropItems(uint itemId) public onlyOwner returns(string) {
        require(stronghold_rewards_batch[itemId] > 0, "STRONGHOLD_REWARD_BATCH_MUST_HAVE_ITEM");
        require(block.number-blockNumber > options[ITEM_DROP_INTERVAL_BLOCKS], "STRONGHOLD_REWARD_TIME_IS_TOO_EARLY");
        return straightDropItems(itemId);
    }

    // Pass 0 as an Argument to retreive block for latest one
    function getDropData(uint blockAsKey) public view returns(uint, uint, uint, uint) {
        if (blockAsKey == 0)
            blockAsKey = blockNumber;
        return ( stronghold_reward_logs[blockAsKey].StrongholdId, stronghold_reward_logs[blockAsKey].ItemId,
            stronghold_reward_logs[blockAsKey].HeroId, stronghold_reward_logs[blockAsKey].PreviousBlock  );
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string a, string b, string c, string d, string e) internal pure returns (string) {

      return string(abi.encodePacked(a, b, c, d, e));

  }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Signnature Testing
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    address deployer = msg.sender;

    /* uint id, uint referer_id, address referer_address, uint[5] heroStats, uint[5] heroItems */

    function prefixedHeroMessage(uint id, uint[] heroStats, uint[] heroItems) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19TRON Signed Message:\n32', id,
          heroStats, heroItems));
    }

    function checkHeroCreationSign(uint id, uint[] heroStats, uint[] heroItems, uint8 v, bytes32[2] rs) public view returns(bool) {
      bytes32 message = prefixedHeroMessage(id, heroStats, heroItems);

      return ecrecover(message, v, rs[0], rs[1]) == deployer;
    }

    function prefixedBattleLogMessage(uint id, // Battle ID
      uint[2] resultType,
      uint attacker, // Attacker ID
      uint[2] attackerTroops,
      uint[5] attackerItems,
      uint defenderObject, // Bandit Camp ID, Stronghold ID or City ID
      uint defender,  // Defender Lord ID
      uint[2] defenderTroops,
      uint[5] defenderItems) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19TRON Signed Message:\n32', id, resultType, attacker, attackerTroops, attackerItems, defenderObject, defender, defenderTroops, defenderItems));
    }

    function checkBattleLogSign(uint id, // Battle ID
      uint[2] resultType,
      uint attacker, // Attacker ID
      uint[2] attackerTroops,
      uint[5] attackerItems,
      uint defenderObject, // Bandit Camp ID, Stronghold ID or City ID
      uint defender,  // Defender Lord ID
      uint[2] defenderTroops,
      uint[5] defenderItems,
      uint8 v, bytes32[2] rs) public view returns(bool) {
      bytes32 message = prefixedBattleLogMessage(id, resultType, attacker, attackerTroops, attackerItems, defenderObject, defender, defenderTroops, defenderItems);

      return ecrecover(message, v, rs[0], rs[1]) == deployer;
    }

    //function checkSign(bytes32 message, bytes sig) public view returns(string) {
    function checkSign(string str1, string str2, uint8 v, bytes32 r, bytes32 s) public view returns(string) {

        // This recreates the message that was signed on the client.
        bytes32 message = prefixed(str1, str2);

        /* require(recoverSigner(message, sig) == deployer, "Message is not verified"); */
        require(ecrecover(message, v, r, s) == deployer, " Message was not verified!");


        // msg.sender.transfer(amount);
        return "Message was done!";

    }

    function checkArrSign(uint[] arr, uint8 v, bytes32 r, bytes32 s) public view returns(string) {

        // This recreates the message that was signed on the client.
        bytes32 message = prefixedArr(arr);

        /* require(recoverSigner(message, sig) == deployer, "Message is not verified"); */
        require(ecrecover(message, v, r, s) == deployer, " Message was not verified!");


        // msg.sender.transfer(amount);
        return "Array has been verified!";

    }


        // Builds a prefixed hash to mimic the behavior of eth_sign.
        function prefixed(string str1, string str2) internal pure returns (bytes32) {
            return keccak256(abi.encodePacked('\x19TRON Signed Message:\n32', str1, str2));
        }

        function prefixedArr(uint[] arr) internal pure returns (bytes32) {
            return keccak256(abi.encodePacked('\x19TRON Signed Message:\n32', arr));
        }

    // Destroy contract and reclaim leftover funds.
    function kill() public {
        require(msg.sender == deployer);
        selfdestruct(msg.sender);
    }


    // Signature methods

    /* function splitSignature(bytes sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65, "Signnature length is invalid");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := and(mload(add(sig, 65)), 255)
        }

        return (v, r, s);
    } */

    /* function recoverSigner(bytes32 message, bytes sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    } */


}
