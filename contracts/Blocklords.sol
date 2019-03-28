pragma solidity ^0.4.23;

import "./Ownable.sol";

contract Blocklords is Ownable {


/////////////////////////////////////   MISC    ////////////////////////////////////////////////

uint duration8Hours = 28800;      // 28_800 Seconds are 8 hours
uint duration12Hours = 43200;     // 43_200 Seconds are 12 hours
uint duration24Hours = 86400;     // 86_400 Seconds are 24 hours

uint createHeroFee = 500000000; //TRX in SUN, 1 TRX * 1000000
                   //___000000
uint fee8Hours =   50000000;
                 //__000000
uint fee12Hours =  88000000;
                 //__000000
uint fee24Hours = 100000000;
                //___000000
uint siegeBattleFee = 200000000;
                       //000000
uint banditBattleFee = 50000000;
                     //__000000
uint strongholdBattleFee = 100000000;
                         //___000000

uint ATTACKER_WON = 1;
uint ATTACKER_LOSE = 2;
uint DRAW = 3;

uint PVP= 1;       // Player Against Player at the Strongholds
uint PVC= 2;       // Player Against City
uint PVE= 3;       // Player Against NPC on the map



uint coffersTotal = allCoffers();

function getBalance() public view returns(uint) {
    return address(this).balance;
}

function withdraw(uint amount) public returns(bool) { //  withdraw  only to owner's address
    if (amount == 0)
         amount = getBalance();
    require(amount < address(this).balance-coffersTotal, "balance is insufficient");  // Umcomment this requirement if you want the amount stored in coffers to be not withdrawable
    address owner_ = owner();
    owner_.transfer(amount);
    return true;
}

function random(uint entropy, uint number) private view returns (uint8) {
     // NOTE: This random generator is not entirely safe and   could potentially compromise the game,
        return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%number);
   }

function randomFromAddress(address entropy) private view returns (uint8) {
       return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%256);
   }

////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////// PAYMENT STRUCT ///////////////////////////////////////////////

    struct Payment{
        address PAYER;
        uint HERO_ID;
    }

    mapping (uint => Payment) payments;

    function heroCreationPayment(uint heroId) public payable returns(uint, uint, bool){
        require(msg.value == createHeroFee, "Payment fee does not match");
        payments[heroId] = Payment(msg.sender, heroId);
        return(msg.value, createHeroFee, msg.value == createHeroFee);
    }

    function getPayments(uint heroId) public view returns(address, uint){
        return(payments[heroId].PAYER, payments[heroId].HERO_ID);
    } //TODO: add event

////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////// HERO STRUCT ////////////////////////////////////////////////

    struct Hero{
        address OWNER;     // Wallet address of Player that owns Hero
        uint TROOPS_CAP;   // Troops limit for this hero
        uint LEADERSHIP;   // Leadership Stat value
        uint INTELLIGENCE; // Intelligence Stat value
        uint STRENGTH;     // Strength Stat value
        uint SPEED;        // Speed Stat value
        uint DEFENSE;      // Defense Stat value
        // bytes32 TX;     // Transaction ID where Hero creation was recorded
    }

    mapping (uint => Hero) heroes;

    function putHero(uint id, uint troopsCap, uint leadership,  uint intelligence, uint strength, uint speed, uint defense, uint item1, uint item2, uint item3, uint item4, uint item5) public payable returns(bool){
            require(msg.value == createHeroFee, "Payment fee does not match");
            require(id > 0,
            "Please insert id higher than 0");
            //require(payments[id].PAYER == owner, "Payer and owner do not match");
            require(heroes[id].OWNER == 0x0000000000000000000000000000000000000000,
            "Hero with this id already exists");

            // TODO check item is not for stronghold reward
             require(items[item1].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
             require(items[item2].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
             require(items[item3].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
             require(items[item4].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
             require(items[item5].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");

            //delete payments[id]; // delete payment hash after the hero was created in order to prevent double spend
            heroes[id] = Hero(msg.sender, troopsCap, leadership,  intelligence, strength, speed, defense);

            items[item1].OWNER = msg.sender;
            items[item2].OWNER = msg.sender;
            items[item3].OWNER = msg.sender;
            items[item4].OWNER = msg.sender;
            items[item5].OWNER = msg.sender;


            return true;
    }

    function getHero(uint id) public view returns(address, uint, uint, uint, uint, uint, uint){
            return (heroes[id].OWNER, heroes[id].TROOPS_CAP, heroes[id].LEADERSHIP, heroes[id].INTELLIGENCE, heroes[id].STRENGTH, heroes[id].SPEED, heroes[id].DEFENSE);
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
    function putItem(uint creationType, uint id, uint statType, uint quality, uint generation, uint statValue, uint level, uint xp, address itemOwner ) public onlyOwner { // only contract owner can put new items
            require(id > 0,
            "Please insert id higher than 0");

            if (itemOwner == 0x0000000000000000000000000000000000000000) {
              itemOwner = msg.sender;
            }

            items[id] = Item(statType, quality, generation, statValue, level, xp, itemOwner);

            if (creationType == 0){
                addStrongholdReward(id);     //if putItem(stronghold reward) ==> add to StrongholdReward
            }
        }

    function getItem(uint id) public view returns(uint, uint, uint, uint, uint, uint, address){
            return (items[id].STAT_TYPE, items[id].QUALITY, items[id].GENERATION, items[id].STAT_VALUE, items[id].LEVEL, items[id].XP, items[id].OWNER);
        }

    function getUpdatedItem(uint battleId) public view returns(uint) {
      return updated_items[battleId];
    }

    function isUpgradableItem(uint id) private view returns (bool){
      if (items[id].STAT_VALUE == 0) return false;

      if (items[id].QUALITY == 1 && items[id].LEVEL == 3) return false;
      if (items[id].QUALITY == 2 && items[id].LEVEL == 5) return false;
      if (items[id].QUALITY == 3 && items[id].LEVEL == 7) return false;
      if (items[id].QUALITY == 4 && items[id].LEVEL == 9) return false;
      if (items[id].QUALITY == 5 && items[id].LEVEL == 10) return false;

      return true;
    }

    function updateItemsStats(uint[] itemIds, uint battleId) public {
      uint zero = 0;
      uint[5] memory existedItems = [zero, zero, zero, zero, zero];
      uint itemIndexesAmount = zero;

      for (uint i=zero; i<itemIds.length; i++) {
        if (itemIds[i] != zero) {

          // Check if Exp can be increased
          if (isUpgradableItem(itemIds[i])) {

            existedItems[itemIndexesAmount] = itemIds[i];
            itemIndexesAmount++;
          }
        }
      }

      //uint seed = block.number + item.GENERATION+item.LEVEL+item.STAT_VALUE+item.XP + itemIds.length + randomFromAddress(item.OWNER); // my poor attempt to make the random generation a little bit more random

        if (itemIndexesAmount == zero) {
          return;
        }
        uint seed = block.number + randomFromAddress(msg.sender) + getBalance();

        uint randomIndex = random(seed, itemIndexesAmount);
        randomIndex--; // It always starts from 1. While arrays from 0

            uint id = existedItems[randomIndex];

            // Increase XP that represents on how many battles the Item was involved into
            items[id].XP = items[id].XP + 2;

            // Increase Level
            if (
                items[id].LEVEL == 0 && items[id].XP == 2 ||
                items[id].LEVEL == 1 && items[id].XP == 6 ||
                items[id].LEVEL == 2 && items[id].XP == 20 ||
                items[id].LEVEL == 3 && items[id].XP == 48 ||
                items[id].LEVEL == 4 && items[id].XP == 92 ||
                items[id].LEVEL == 5 && items[id].XP == 152 ||
                items[id].LEVEL == 6 && items[id].XP == 228 ||
                items[id].LEVEL == 7 && items[id].XP == 318 ||
                items[id].LEVEL == 8 && items[id].XP == 434 ||
                items[id].LEVEL == 9 && items[id].XP == 580
                ) {

                    items[id].LEVEL = items[id].LEVEL + 1;
                    items[id].STAT_VALUE = items[id].STAT_VALUE + 1;
                    // return "Item level is increased by 1";
            }
            // Increase Stats based on Quality
            /* if (item.QUALITY == 1){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3);
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 3;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 6;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 9;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 12;
            } */
            /* items[id] = item; */

            updated_items[battleId] = id;
    }

////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////// MARKET ITEM STRUCT ///////////////////////////////////////////////

    struct MarketItemData{

            uint Price; // Fixed Price of Item defined by Item owner
            uint AuctionDuration; // 8, 12, 24 hours
            uint AuctionStartedTime; // Unix timestamp in seconds
            uint City; // City ID (item can be added onto the market only through cities.)
            address Seller; // Wallet Address of Item owner
            // bytes32 TX; // Transaction ID, (Transaction that has a record of Item Adding on Market)

    }

    mapping (uint => MarketItemData) market_items_data;

    function addMarketItem(uint itemId, uint price, uint auctionDuration, uint city) public payable { // START AUCTION FUNCTION
            require(items[itemId].OWNER == msg.sender, "You don't own this item");
            require(auctionDuration == duration8Hours || auctionDuration == duration12Hours || auctionDuration == duration24Hours,
            "Incorrect auction duration");
            require(cities[city-1].MarketCap > cities[city-1].MarketAmount, "City Market Is Full");
            if (auctionDuration == duration8Hours){
                require(msg.value == fee8Hours,
                "Incorrect fee amount");
            } else if (auctionDuration == duration12Hours){
                require(msg.value == fee12Hours,
                "Incorrect fee amount");
            } else if (auctionDuration == duration24Hours){
                require(msg.value == fee24Hours,
                "Incorrect fee amount");
            }

            cities[market_items_data[itemId].City-1.].MarketAmount = cities[market_items_data[itemId].City-1].MarketAmount + 1;

            address seller = msg.sender;
            uint auctionStartedTime = now;
            market_items_data[itemId] = MarketItemData(price, auctionDuration, auctionStartedTime, city, seller);
        }
//
    function getMarketItem(uint itemId) public view returns(uint, uint, uint, uint, address){
            return(market_items_data[itemId].Price, market_items_data[itemId].AuctionDuration, market_items_data[itemId].AuctionStartedTime, market_items_data[itemId].City, market_items_data[itemId].Seller);
    }

    function buyMarketItem(uint itemId) public payable returns(bool) {
        require(market_items_data[itemId].AuctionStartedTime+market_items_data[itemId].AuctionDuration>=now,
        "Auction is no longer available"); // check  auction duration time
        require(msg.value == (market_items_data[itemId].Price / 100 * 110),
        "The value sent is incorrect"); // check transaction amount

        uint city = market_items_data[itemId].City; // get the city id

        uint cityHero = cities[city].Hero;  // get the hero id
        address cityOwner = heroes[cityHero].OWNER; // get the hero owner
        address seller = market_items_data[itemId].Seller;

        uint amount = msg.value;

        cities[market_items_data[itemId].City-1].MarketAmount = cities[market_items_data[itemId].City-1].MarketAmount - 1;

        if (cityOwner > 0)
          cityOwner.transfer(amount / 110 * 5); // send 5% to city owner
        seller.transfer(amount / 110 * 100); // send 90% to seller

        items[itemId].OWNER = msg.sender; // change owner
        delete market_items_data[itemId]; // delete auction
        return (true);

    }
//auctionCancel
    function deleteMarketItem(uint itemId) public returns(bool){
        require(market_items_data[itemId].Seller == msg.sender,
                "You do not own this item");
        cities[market_items_data[itemId].City-1.].MarketAmount = cities[market_items_data[itemId].City-1].MarketAmount - 1;
        delete market_items_data[itemId];
        return true;
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

    City[16] public cities;

    mapping(uint => City[16]) public idToCity;

    function putCity(uint id, uint size, uint cofferSize, uint cap) public payable onlyOwner {
        require(msg.value == cofferSize,
                "msg.value does not match cofferSize");
        uint blank = 0;
        cities[id-1] = City(id, blank, size, cofferSize, block.number, cap, blank );
    }

    function getCityData(uint id) public view returns(uint, uint, uint, uint, uint, uint){
        return (cities[id-1].Hero, cities[id-1].Size, cities[id-1].CofferSize, cities[id-1].CreatedBlock, cities[id-1].MarketCap, cities[id-1].MarketAmount);

    }

    function allCoffers() public view returns(uint){
        uint total = 0;
        for (uint i=0; i < cities.length ; i++){
            total += cities[i].CofferSize;
        }
        return total;
    }

    uint cofferBlockNumber = block.number;
    uint CofferBlockDistance = 1;//150000;

    function dropCoffer() public {   // drop coffer (every 25 000 blocks) ==> 30% coffer goes to cityOwner
        require(block.number-cofferBlockNumber > CofferBlockDistance,
        "Please try again later");

        cofferBlockNumber = block.number; // this function can be called every "cofferBlockNumber" blocks

        for (uint cityNumber=0; cityNumber < cities.length ; cityNumber++){ // loop through each city

            uint cityHero = cities[cityNumber].Hero;
            address heroOwner = heroes[cityHero].OWNER;
            uint transferValue = (cities[cityNumber].CofferSize/100)*30;
            cities[cityNumber].CofferSize = (cities[cityNumber].CofferSize/100)*70;

            if (cityHero > 0){
                heroOwner.transfer(transferValue);
            } // else it is goes to nowhere, which means will stay on contract and will be transferred NPC owner.
        }
    }

    function getDropCofferBlock() public view returns(uint) {
      return (cofferBlockNumber);
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////// STRONGHOLD STRUCT //////////////////////////////////////////////////////////

    struct Stronghold{
        uint ID;           // Stronghold ID
        uint Hero;         // Hero ID, that occupies Stronghold on map
        uint CreatedBlock; // The Blockchain Height

    }

    Stronghold[10] public strongholds;

    mapping(uint => Stronghold[10]) public idToStronghold;

    function changeStrongholdOwner(uint id, uint hero) public {
            require(heroes[hero].OWNER != 0x0000000000000000000000000000000000000000,
            "There is no such hero");
            require(heroes[hero].OWNER == msg.sender,
            "You dont own this hero");

            strongholds[id] = Stronghold(id, hero, block.number); // Stronghold ID is the only id that starts from 0, all other id's start from 1
    }

    function getStrongholdData(uint shId) public view returns(uint, uint){
            return(strongholds[shId-1].Hero, strongholds[shId-1].CreatedBlock);
    }

    function putStronghold(uint shId, uint hId) public returns (uint) {
        require(strongholds[shId-1].CreatedBlock == 0, "Stronghold can not be overwritten");

        strongholds[shId-1] = Stronghold(shId, hId, block.number);
        return block.number;
    }

    function leaveStronghold(uint shId, uint heroId) public returns(bool){
            require(strongholds[shId-1].Hero == heroId,
            "Selected hero is not in the stronghold");
             require(heroes[heroId].OWNER == msg.sender,
            "You do not own this hero");
            strongholds[shId-1].Hero = 0;
            //strongholds[shId-1].CreatedBlock = block.number;
            return true;
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////// STRONGLOHD REWARD STRUCT /////////////////////////////////////////////////////////

    struct StrongholdReward{

        uint ID;           // Item ID
        uint CreatedBlock; // The Blockchain Height
    }

    mapping (uint => StrongholdReward) public stronghold_rewards;

    function addStrongholdReward(uint id) public onlyOwner returns(bool){
        stronghold_rewards[id] = StrongholdReward(id, block.number);
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////// BATTLELOG STRUCT /////////////////////////////////////////////////////////

    struct BattleLog{

        uint[] BattleResultType; // BattleResultType[0]: 0 - Attacker WON, 1 - Attacker Lose ; BattleResultType[1]: 0 - City, 1 - Stronghold, 2 - Bandit Camp
        uint Attacker;
        uint[] AttackerTroops;       // Attacker's troops amount that were involved in the battle & remained troops
        uint[] AttackerItems;        // Item IDs that were equipped by Attacker during battle.
        uint DefenderObject;   // City|Stronghold|NPC ID based on battle type
        uint Defender;         // City Owner ID|Stronghold Owner ID or NPC ID
        uint[] DefenderTroops;
        uint[] DefenderItems;
        uint Time;             // Unix Timestamp in seconds. Time, when battle happened
        // bytes32 TX;                   // Transaction where Battle Log was recorded.
        }

    mapping(uint => BattleLog) public battle_logs;

    // result type: win or lose/ battle type
    // last parameter 'dropItem' is only for contest version of game
    function addBattleLog(uint id, uint[] resultType, uint attacker, uint[] attackerTroops, uint[] attackerItems,
                          uint defenderObject, uint defender, uint[] defenderTroops, uint[] defenderItems )//, uint itemDrop*/)

                          public payable returns (bool){

            require(resultType.length <=2 && resultType[0] <= 2 && resultType[1] <= 3 ,
                    "Incorrect number of result parametres or incorrect parametres");
            require(attackerTroops.length == 2,
                    "Incorrect number of arguments for attackerTroops");
            require(attackerItems.length <= 5,
                    "incorrect number of attacker items");
            require(defenderTroops.length == 2,
                    "Incorrect number of arguments for defenderTroops");
            require(defenderItems.length <=5,
                    "incorrect number of defender items");

            if (resultType[1] == PVC){ // siegeBattleFee if atack City
                require(msg.value == siegeBattleFee,
                "Incorrect fee amount");
            } else if (resultType[1] == PVP){ // strongholdBattleFee if atack Stronghold
                require(msg.value == strongholdBattleFee,
                "Incorrect fee amount");
            } else if (resultType[1] == PVE){ // banditBattleFee if atack Bandit Camp
                require(msg.value == banditBattleFee,
                "Incorrect fee amount");
            }

            uint time = now;

            battle_logs[id] = BattleLog(resultType, attacker, attackerTroops,
                                        attackerItems, defenderObject, defender,
                                        defenderTroops, defenderItems, time); //add data to the struct

            //            if (resultType[0] == ATTACKER_WON) {
            //                items[dropItem].OWNER = msg.sender;
            //            }

            if (resultType[0] == ATTACKER_WON && resultType[1] == PVP){
                strongholds[defenderObject-1].Hero = attacker; // if attack Stronghold && WIN ==> change stronghold Owner
                strongholds[defenderObject-1].CreatedBlock = block.number;
            } else if (resultType[1] == PVC) {
              cities[defenderObject-1].CofferSize = cities[defenderObject-1].CofferSize + (siegeBattleFee / 2);
              if (resultType[0] == ATTACKER_WON) {
                cities[defenderObject-1].Hero = attacker; // else if attack City && WIN ==> change city owner
                cities[defenderObject-1].CreatedBlock = block.number;
              }
            } else if (resultType[1] == PVE){
                updateItemsStats(attackerItems, id);     // else if attackBandit ==> update item stats
            }
            return true;
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
    uint blockDistance = 1; // 800 in original

    mapping(uint => DropData) public stronghold_reward_logs;

    function getDropItemBlock() public view returns(uint) {
      return (blockNumber);
    }

    /*
    Stronghold Timer

    StrongholdTimer global variable

    When Putting Stronghold:
    Check if global variable is 0

    */

    /* function minimize(uint number) internal pure returns (uint) {
      if (number >= 100000000)
    return number / 100000000;
      if (number >= 10000000)
    return number / 10000000;
      if (number >= 1000000)
    return number / 1000000;
      if (number >= 100000)
    return number / 100000;
      if (number >= 10000)
    return number / 10000;
      if (number >= 1000)
    return number / 1000;
      if (number >= 100)
    return number / 100;
      if (number >= 10)
    return number / 10;
      return  number;
    } */

    /* function complexDropItems(uint itemId) internal returns(string) {
      uint total = 0;
      uint[10] memory ranges = [ total, total, total, total, total, total, total, total, total, total ];

      if (strongholds[0].Hero > 0) {
        // 200 - 100 => 100
          total = minimize(block.number - strongholds[0].CreatedBlock);
      }
      ranges[0] = total;   // 100



      if (strongholds[1].Hero > 0) { // 0, skipping
          total = minimize(total + (block.number - strongholds[1].CreatedBlock));
      }
      ranges[1] = total;   // 100



      if (strongholds[2].Hero > 0) {
        // 200 - 50 + 100 => 150
          total = minimize(total + (block.number - strongholds[2].CreatedBlock));
      }
      ranges[2] = total;


      if (strongholds[3].Hero > 0) {
        // 200 - 150 + 150 => 200
          total = minimize(total + (block.number - strongholds[3].CreatedBlock));
      }
      ranges[3] = total;


      if (strongholds[4].Hero > 0) {
        // 0
          total =minimize(total + (block.number - strongholds[4].CreatedBlock));
      }
      ranges[4] = total;

      if (strongholds[5].Hero > 0) {
        // 0
          total = minimize(total + (block.number - strongholds[5].CreatedBlock));
      }
      ranges[5] = total;


      if (strongholds[6].Hero > 0) {
        // 200 - 25 + 200 => 375
          total = minimize(total + (block.number - strongholds[6].CreatedBlock));
      }
      ranges[6] = total;


      if (strongholds[7].Hero > 0) {
        // 200 - 75 + 375 => 500
          total = minimize(total + (block.number - strongholds[7].CreatedBlock));
      }
      ranges[7] = total;


      if (strongholds[8].Hero > 0) {
        // 0
          total = minimize(total + (block.number - strongholds[8].CreatedBlock));
      }
      ranges[8] = total;
      if (strongholds[9].Hero > 0) {
        // 0
           total = minimize(total + (block.number - strongholds[9].CreatedBlock));
      }
      ranges[9] = total;

      if (total < 1)
      {
        return("All Strongholds have an NPC");
      }

// 1 - 100, 2 - 0, 3 - 150, 4 - 200, 5 - 0, 6 - 0, 7 - 375, 8 - 500, 9 - 0, 10 - 0
      uint seed = randomFromAddress(msg.sender);// + block.number;

      // 333 - 1 => 332
      uint dot = random(seed, total); // select randomly stronghold

      uint strongholdId = 0;

      // skipping
      if (strongholds[9].Hero > 0) {
          if (dot > ranges[8] && dot <= ranges[9]) {
              strongholdId = 10;
          }
      }
      // skipping
      if (strongholds[8].Hero > 0) {
          if (dot > ranges[7] && dot <= ranges[8]) {
            strongholdId = 9;
          }
      }
      // 332 < 500 => true, strongHold = 8
      if (strongholds[7].Hero > 0) {
          if (dot > ranges[6] && dot <= ranges[7]) {
            strongholdId = 8;
          }
      }
      // 332 < 375 => true, stronghold = 7
      if (strongholds[6].Hero > 0) {
          if (dot > ranges[5] && dot <= ranges[6]) {
            strongholdId = 7;
          }
      }
      if (strongholds[5].Hero > 0) {
          if (dot > ranges[4] && dot <= ranges[5]) {
            strongholdId = 6;
          }
      }
      if (strongholds[4].Hero > 0) {
          if (dot > ranges[3] && dot <= ranges[4]) {
            strongholdId = 5;
          }
      }
      if (strongholds[3].Hero > 0) {
          if (dot > ranges[2] && dot <= ranges[3]) {
            strongholdId = 4;
          }
      }
      if (strongholds[2].Hero > 0) {
          if (dot > ranges[1] && dot <= ranges[2]) {
            strongholdId = 3;
          }
      }
      if (strongholds[1].Hero > 0) {
          if (dot > ranges[0] && dot <= ranges[1]) {
            strongholdId = 2;
          }
      }
      if (strongholds[0].Hero > 0) {
          if (dot > 0 && dot <= ranges[0]) {
            strongholdId = 1;
          }
      }

      if (strongholdId != 0) {
        uint lordId = strongholds[strongholdId-1].Hero;

        items[itemId].OWNER = heroes[lordId].OWNER;

        delete stronghold_rewards[itemId]; //delete item from strongHold reward struct
        delete strongholds[strongholdId-1];

        // Update Block
        uint previousBlock = blockNumber;
        blockNumber = block.number; // this function can be called every "blockDistance" blocks

        stronghold_reward_logs[blockNumber] = DropData(blockNumber, strongholdId, itemId, lordId, previousBlock); //add data to the struct

        // return ("Supreme success");
        return(strConcat(uint2str(dot), " ",uint2str(total), uint2str(strongholdId), uint2str(itemId))); // check if hero exist
          //return rewardStrongholdLord(itemId, strongholdId);
      }

      return ("Failed to reward stronghold lord");
    } */

    function simpleDropItems(uint itemId) internal returns (string) {
      uint zero = 0;
      uint[10] memory occupied = [zero, zero, zero, zero, zero, zero, zero, zero, zero, zero];
      uint occupiedIndexesAmount = zero;

      for (uint i=zero; i<10; i++) {
        if (strongholds[i].Hero > zero) {
          occupied[occupiedIndexesAmount] = i;
          occupiedIndexesAmount++;
        }
      }

      //uint seed = block.number + item.GENERATION+item.LEVEL+item.STAT_VALUE+item.XP + itemIds.length + randomFromAddress(item.OWNER); // my poor attempt to make the random generation a little bit more random

      if (occupiedIndexesAmount == zero) {
          return "All strongholds are occupied by NPC";
      }
      uint seed = block.number + randomFromAddress(msg.sender) + getBalance();

      uint index = random(seed, occupiedIndexesAmount);
      index = occupied[index - 1];

      uint lordId = strongholds[index].Hero;

      items[itemId].OWNER = heroes[lordId].OWNER;

      delete stronghold_rewards[itemId]; //delete item from strongHold reward struct
      delete strongholds[index];

      // Update Block
      uint previousBlock = blockNumber;
      blockNumber = block.number; // this function can be called every "blockDistance" blocks

      stronghold_reward_logs[blockNumber] = DropData(blockNumber, index + 1, itemId, lordId, previousBlock); //add data to the struct

      // return ("Supreme success");
      return(strConcat(uint2str(index), " generated id - ",uint2str(occupiedIndexesAmount), " - from ids, drop: ", uint2str(itemId))); // check if hero exist
    }

    function dropItems(uint itemId) public onlyOwner returns(string) {
        require(stronghold_rewards[itemId].ID > 0,
        "Not a reward item");
        require(block.number-blockNumber > blockDistance,
        "Please try again later");
        return simpleDropItems(itemId);
    }

    /* function rewardStrongholdLord(uint itemId, uint strongholdId) internal returns(string) {

        uint lordId = strongholds[strongholdId-1].Hero;

        items[itemId].OWNER = heroes[lordId].OWNER;

        delete stronghold_rewards[itemId]; //delete item from strongHold reward struct
        delete strongholds[strongholdId-1];

        // Update Block
        uint previousBlock = blockNumber;
        blockNumber = block.number; // this function can be called every "blockDistance" blocks

        stronghold_reward_logs[blockNumber] = DropData(blockNumber, strongholdId, itemId, lordId, previousBlock); //add data to the struct

        // return ("Supreme success");
        return(uint2str(strongholdId)); // check if hero exist
    } */

    // Pass 0 as an Argument to retreive block for latest one
    // TODO return Stronghold id that started from 1.
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

}
