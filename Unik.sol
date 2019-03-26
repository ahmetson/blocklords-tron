pragma solidity ^0.4.23;

contract Unik {
    
    uint STAGE_INIT = 5;
    uint STAGE_1 = 1;
    uint STAGE_2 = 2;
    uint STAGE_3 = 3;
    uint STAGE_4 = 4;
    uint STAGE_END = 6;
    uint STAGE_CANCEL = 7;

    function random(uint entropy, uint number) private view returns (uint8) {   // NOTE: This random generator is not entirely safe and could potentially compromise the game, 
                                                                                // I would recommend game owners to use solutions from trusted oracles
           return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%number);
       }
    
    function randomFromAddress(address entropy) private view returns (uint8) {  
           return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%256);
       }


// ////////////////////////////////////////////////////////////////////////////////////////////////////    
// For now, hero information will be stopped

// ///////////////////////////////////// HERO STRUCT ////////////////////////////////////////////////    

//     struct Hero{
//         address OWNER;     // Wallet address of Player that owns Hero
//         uint TROOPS_CAP;   // Troops limit for this hero
//         uint LEADERSHIP;   // Leadership Stat value
//         uint INTELLIGENCE; // Intelligence Stat value
//         uint STRENGTH;     // Strength Stat value
//         uint SPEED;        // Speed Stat value
//         uint DEFENSE;      // Defense Stat value
//         // bytes32 TX;     // Transaction ID where Hero creation was recorded
//     }
    
//     mapping (uint => Hero) heroes;
    
//     function putHero(uint id, address owner, uint troopsCap, uint leadership,  uint intelligence, uint strength, uint speed, uint defense) public onlyOwner { 
//             require(id > 0, 
//             "Please insert id higher than 0");
//             require(payments[id].PAYER == owner, 
//             "Payer and owner do not match");
//             require(heroes[id].OWNER == 0x0000000000000000000000000000000000000000,
//             "Hero with this id already exists");
            
//             delete payments[id]; // delete payment hash after the hero was created in order to prevent double spend
//             heroes[id] = Hero(owner, troopsCap, leadership,  intelligence, strength, speed, defense);
//     }
    
//     function getHero(uint id) public view returns(address, uint, uint, uint, uint, uint, uint){ 
//             return (heroes[id].OWNER, heroes[id].TROOPS_CAP, heroes[id].LEADERSHIP, heroes[id].INTELLIGENCE, heroes[id].STRENGTH, heroes[id].SPEED, heroes[id].DEFENSE);
//         }

////////////////////////////////////////////////////////////////////////////////////////////////////    

///////////////////////////////////// ITEM STRUCT //////////////////////////////////////////////////   

    struct Element{
        uint id;
        string json;
        string element_type;
        address owner;
        uint xp;
        uint wins;
        uint created_time;
    }
    
    mapping (uint => Element) public elements;

    // creationType StrongholdReward: 0, createHero 1
    function putElement(uint id, string json, string element_type, uint xp ) public returns (bool) { // only contract owner can put new items
            require(id > 0,
            "Please insert id higher than 0");
            require(elements[id].owner == 0x0000000000000000000000000000000000000000, "Element with such ID already exists. Please create another one");

            elements[id] = Element(id, json, element_type, msg.sender, xp, 0, now);

            return true;
        }

    function getElement(uint id) public view returns(uint, string, string, address, uint, uint, uint){
            return (elements[id].id, elements[id].json, elements[id].element_type, elements[id].owner, elements[id].xp, elements[id].wins, elements[id].created_time);
        }
    
    // function updateItemsStats(uint[] itemIds) public {
    //     for (uint i=0; i < itemIds.length ; i++){
            
    //         uint id = itemIds[i];
    //         Item storage item = items[id];
    //         uint seed = item.GENERATION+item.LEVEL+item.STAT_VALUE+item.XP + itemIds.length + randomFromAddress(item.OWNER); // my poor attempt to make the random generation a little bit more random

    //         // Increase XP that represents on how many battles the Item was involved into
    //         item.XP = item.XP + 1;
            
    //         // Increase Level
    //         if (item.QUALITY == 1 && item.LEVEL == 3 ||
    //             item.QUALITY == 2 && item.LEVEL == 5 ||
    //             item.QUALITY == 3 && item.LEVEL == 7 ||
    //             item.QUALITY == 4 && item.LEVEL == 9 ||
    //             item.QUALITY == 5 && item.LEVEL == 10){
    //                 // return "The Item reached max possible level. So do not update it";
    //                 continue;
    //         } if (
    //             item.LEVEL == 1 && item.XP >= 4 ||
    //             item.LEVEL == 2 && item.XP >= 14 ||
    //             item.LEVEL == 3 && item.XP >= 34 ||
    //             item.LEVEL == 4 && item.XP >= 74 ||
    //             item.LEVEL == 5 && item.XP >= 144 ||
    //             item.LEVEL == 6 && item.XP >= 254 ||
    //             item.LEVEL == 7 && item.XP >= 404 ||
    //             item.LEVEL == 8 && item.XP >= 604 ||
    //             item.LEVEL == 9 && item.XP >= 904
    //             ) {
                    
    //                 item.LEVEL = item.LEVEL + 1;
    //                 // return "Item level is increased by 1";
    //         } 
    //         // Increase Stats based on Quality
    //         if (item.QUALITY == 1){
    //             item.STAT_VALUE = item.STAT_VALUE + random(seed, 3);
    //         } else if (item.QUALITY == 2){
    //             item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 3;
    //         } else if (item.QUALITY == 2){
    //             item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 6;
    //         } else if (item.QUALITY == 2){
    //             item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 9;
    //         } else if (item.QUALITY == 2){
    //             item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 12;
    //         }

    //     }
        
    // }
    

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////// BATTLELOG STRUCT /////////////////////////////////////////////////////////

    struct Battle{
        uint id;
        address fighter1;
        address fighter2;
        
        uint[] fighter1_selected;   // 4 selected elements
        uint[] fighter2_selected;   // 4 selected elements
        
        uint stage;                 // 0 - not initialized, 1 - stage 1, 2 - stage 2, 3 - stage 3, 4 - stage 4, 5 - init, 6 - end, 7 - cancel
        
        bool[] fighter1_approved;   //
        bool[] fighter2_approved;   //
        
        uint[] update_ids;
        uint[] update_xps;
        
        uint update_amount;
        
        uint[] remove_ids;
        
        uint remove_amount;
    }
        
    mapping(uint => Battle) battles;
    
    function initBattle(uint battleId, address opponent, uint[] selected, uint[] opponentSelected)  public returns(bool) {
        /// TODO check that selected elements exist and belong to appropriated owners
        if (battles[battleId].id == 0) {
            uint[] emptyUint;
            bool[] emptyBool;
            bool[] approves;
            approves.push(true);    // init     0
            approves.push(false);   // 1
            approves.push(false);   // 2
            approves.push(false);   // 3
            approves.push(false);   // 4
            approves.push(false);   // end 5
            approves.push(false);   // cancel 6
            battles[battleId] = Battle(battleId, msg.sender, opponent, selected, opponentSelected, STAGE_INIT, emptyBool, emptyBool, emptyUint, emptyUint, 0, emptyUint, 0);
        } else {
            require(battles[battleId].stage == STAGE_INIT, "battle is not in Init stage");
            require(battles[battleId].fighter1 == opponent, "first player doesn't match");
            require(battles[battleId].fighter2 == msg.sender, "second player doesn't match");
            require(keccak256(abi.encodePacked(battles[battleId].fighter1_selected)) == keccak256(abi.encodePacked(opponentSelected)), "Opponent selected items doesn't match");
            require(keccak256(abi.encodePacked(battles[battleId].fighter2_selected)) == keccak256(abi.encodePacked(selected)), "Caller's selected items doesn't match");
            
            bool[] approves2;
            approves2.push(true);    // init
            approves2.push(false);
            approves2.push(false);
            approves2.push(false);
            approves2.push(false);
            approves2.push(false);   // end
            approves2.push(false);   // cancel
            battles[battleId].fighter2_approved = approves2;
        }

        return true;
    }
    
    function updateStage(uint id, uint stage)  public returns(bool) {
        require(battles[id].fighter1 != 0x0000000000000000000000000000000000000000, "Probably battle doesnt exist, since fighter1 is empty");
        require(battles[id].fighter2 != 0x0000000000000000000000000000000000000000, "Probably battle doesnt exist, since fighter2 is empty");
        require(stage <= STAGE_4, "Not updatable stage");
        
        // Check That Previous Item is Correct
        if (stage == STAGE_1) {
            // require(battles[id].stage == STAGE_1, "Battle Should be initialized");
            // require(battles[id].fighter1_approved[0] == true, "Fighter 1 didn't approved");
            // require(battles[id].fighter2_approved[0] == true, "Fighter 2 didn't approved");
            
            if (battles[id].fighter1 == msg.sender) {
                battles[id].fighter1_approved[1] = true;
                
                if (battles[id].fighter2_approved[1] == true) {
                    battles[id].stage = STAGE_1;
                }
            } 
            if (battles[id].fighter2 == msg.sender) {
                battles[id].fighter2_approved[1] = true;
                
                if (battles[id].fighter1_approved[1] == true) {
                    battles[id].stage = STAGE_1;
                }
            }
        }
        if (stage >= STAGE_2) {
            require(battles[id].stage == stage - 1, "Battle Should be at stage 1");
            require(battles[id].fighter1_approved[stage-1] == true, "Fighter 1 didn't approved");
            require(battles[id].fighter2_approved[stage-1] == true, "Fighter 2 didn't approved");

            if (battles[id].fighter1 == msg.sender) {
                battles[id].fighter1_approved[stage] = true;
                
                if (battles[id].fighter2_approved[stage] == true) {
                    battles[id].stage = stage;
                }
            } 
            if (battles[id].fighter2 == msg.sender) {
                battles[id].fighter2_approved[stage] = true;
                
                if (battles[id].fighter1_approved[stage] == true) {
                    battles[id].stage = stage;
                }
            }
        }
        return true;
    }
    
    function endBattle(uint id, uint[] updateIds, uint[] updateXps, uint[] removeIds)  public returns(bool) {
        require(battles[id].stage == STAGE_4, "Stage of battle should be at 4");
        require(updateXps.length == updateIds.length, "Update Xps are not matchin' to update Ids");

        // Update Stage if both players approved
        if (battles[id].fighter1 == msg.sender) {
            battles[id].fighter1_approved[6] = true;
                
            if (battles[id].fighter2_approved[6] == true) {
                require(keccak256(abi.encodePacked(battles[id].update_xps)) == keccak256(abi.encodePacked(updateXps)), "Arguments of players are not matchin' for xps");
                require(keccak256(abi.encodePacked(battles[id].update_ids)) == keccak256(abi.encodePacked(updateIds)), "Arguments of players are not matchin' for ids");
                require(keccak256(abi.encodePacked(battles[id].remove_ids)) == keccak256(abi.encodePacked(removeIds)), "Arguments of players are not matchin' for removing");
                
                battles[id].stage = STAGE_END;
            }
        } 
        if (battles[id].fighter2 == msg.sender) {
            battles[id].fighter2_approved[6] = true;
                
            if (battles[id].fighter1_approved[6] == true) {
                require(keccak256(abi.encodePacked(battles[id].update_xps)) == keccak256(abi.encodePacked(updateXps)), "Arguments of players are not matchin' for xps");
                require(keccak256(abi.encodePacked(battles[id].update_ids)) == keccak256(abi.encodePacked(updateIds)), "Arguments of players are not matchin' for ids");
                require(keccak256(abi.encodePacked(battles[id].remove_ids)) == keccak256(abi.encodePacked(removeIds)), "Arguments of players are not matchin' for removing");
                
                battles[id].stage = STAGE_END;
            }
        }
        
        if (battles[id].stage != STAGE_END) {
            battles[id].remove_ids = removeIds;
            battles[id].update_ids = updateIds;
            battles[id].update_xps = updateXps;
        }
        if (battles[id].stage == STAGE_END) {
            // First Update and Edit Loop
            // Because, if in Update or Remove list will be found invalid data, then all this operation should be stopped
            for(uint i=0; i<updateIds.length; i++) {
                if(elements[ updateIds[i] ].owner != battles[id].fighter1) {
                    require(elements[ updateIds[i] ].owner == battles[id].fighter2, "In battle, players may use only their own elements");
                }
                require(updateXps[i] > elements[updateIds[i]].xp, "Update values are incorrect");
                
            }
            for(uint j=0; j<removeIds.length; j++) {
                if(elements[ removeIds[j] ].owner != battles[id].fighter1) {
                    require(elements[ removeIds[j] ].owner == battles[id].fighter2, "In battle, players may use only their own elements");
                }
            }
            
            // now, apply results
            for(uint k=0; k<updateIds.length; k++) {
                elements[ updateIds[k] ].xp = updateXps[k];
            }
            for(uint l=0; l<removeIds.length; l++) {
                delete elements[ removeIds[l] ];
            }
            
            delete battles[id];
        }

        return true;
    }
    
    function cancelBattle(uint id) public returns(bool) {
        require(battles[id].fighter1 != 0x0000000000000000000000000000000000000000, "Battle exists");
        battles[id].stage = STAGE_CANCEL;
        
        if (battles[id].fighter1 == msg.sender) {
            battles[id].fighter1_approved[6] = true;
        } 
        if (battles[id].fighter2 == msg.sender) {
            battles[id].fighter2_approved[6] = true;
        }
        
        require (battles[id].fighter1_approved[6] == battles[id].fighter2_approved[6], "Cancellation doesn't approved by two sides");
        
        delete battles[id];
        
        return true;
    }
    
    function getBattle(uint id) public view returns( uint, address, address ,uint[],uint[], uint ) {
        return (battles[id].id, battles[id].fighter1, battles[id].fighter2, battles[id].fighter1_selected, battles[id].fighter2_selected, battles[id].stage);
    }
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}