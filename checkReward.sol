
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";




import "./RewardDB.sol";
import "./Token1155.sol";
import "./Token721.sol";

contract CheckReward is Ownable {


    constructor(address _token1155 , address _token721)  
    {

       token1155 = GameNFT (_token1155);
       token721 = GameItem (_token721);
               
    }


           
    mapping (address => mapping ( uint256 => mapping (int256 => mapping (int256 => mapping(int256 => uint256))))) public xyzRewardForUser;//xyzPrizeAsUser[userAddrress][x][y][z][rewardId]

    
    mapping (address => bool )  private admins;

    RewardDB rewardDB;
    GameNFT token1155;
    GameItem token721;

    modifier onlyOwnerOrAdmins()
    {
        require( msg.sender == owner() || admins[msg.sender] , "checkPrize - onlyOwners - Owner/Admin Role Required." ) ;
        _;
    }



    event RewardCreatedInXyz( address , uint256 , uint256 , int256 , int256 , int256 , uint256 , uint256 ,uint256 , int256 ,int256 , int256); 
    event RewardExist(int256, int256 , int256, uint256, uint256);
    event RewardRecieved(address, uint256 , uint256 , uint256); 
    event AddAdminRole(address indexed adminAddress, string indexed role );
    event DelAdminRole(address indexed adminAddress, string indexed role );



    function setRewardDBAddress(address _rewardDB) external onlyOwner
    {
        require ( _rewardDB != address(0), " address shouldn't be 0 ");
        rewardDB = RewardDB( _rewardDB );

    }


    function addAdminRole ( address subject  ) public onlyOwner
    {

        admins[subject] = true ; 
        emit AddAdminRole( subject , "Admin" ) ; 

    }

    function removeAdminRole ( address subject  ) public onlyOwner
    {
        require ( subject != owner() , "NFT1155 - Owner Can't be Deleted" ) ; 
        admins[subject] = false ; 
        emit DelAdminRole( subject , "Admin") ; 

    }


  

    function createRewardForUser(address _user, uint256 _planetId, uint256 _radius , uint256 inputRand) external onlyOwnerOrAdmins
    {
        require ( _radius != 0 , " radius of planet couldn't be 0 ");
        require ( _user != address(0) , " address of user couldn't be 0 ");

        int256 x;
        int256 y;
        int256 z;

        int256 s = 1;
        int256 s1 = 1;
        int256 s2 = 1;
        uint256 rand;
        uint256 totalRewardAmount = rewardDB.getTotalRewardAmount(_planetId);
        

        for (uint256 i=0; i < totalRewardAmount ; i++) {
            s = (i % 2 == 0 )? int256(-1): int256(1);
            s1 = (block.timestamp % 2 == 0)? int256(-1):int256(1);
            s2 = (block.number % 2 == 0)? int256(-1): int256(1);
            
            rand = uint256(keccak256(abi.encodePacked(block.timestamp * block.number * (i + 1 + inputRand + gasleft() + tx.gasprice ))));

             x = int256(rand  % _radius) * s;
             y = int256( (rand / 1000) % _radius) * s1;
             z = int256( (rand / 1000000) % _radius ) * s2;

            xyzRewardForUser[_user][_planetId][x][y][z] = i+1;
          

        }

        
    }


   function rewardExist( address _user, uint256 _planetId, int256 _radius, int256 _x, int256 _y, int256 _z) public onlyOwnerOrAdmins view returns(uint256 , uint256)
   {
       require ( _user != address(0) , " address of user couldn't be 0 ");
       require ( _radius != 0 , " radius cant be 0 " );
       require ( _x <= _radius && _x >= -_radius , " x is not in the range of planet ");
       require ( _y <= _radius && _y >= -_radius , " y is not in the range of planet ");
       require ( _z <= _radius && _z >= -_radius , " z is not in the range of planet ");

       uint256 rewardId = xyzRewardForUser[_user][_planetId][_x][_y][_z]; 

       if(rewardId == 0) {
            return (0,0); // prize dosnt exist
        }
        else {

        require(rewardDB.getRewardInfo(_planetId, rewardId).received == false , " prize received before");


        return(rewardId, rewardDB.getRewardInfo(_planetId,rewardId).rewardAmount); 

    }

   }


    function receiveReward ( uint256 _planetId, int256 _radius,  int256 _x, int256 _y, int256 _z, address _recipient) external onlyOwnerOrAdmins returns(bool){

        require ( _radius != 0 , " radius cant be 0 " );
        require ( _x <= _radius && _x >= -_radius , " x is not in the range of planet ");
        require ( _y <= _radius && _y >= -_radius , " y is not in the range of planet ");
        require ( _z <= _radius && _z >= -_radius , " z is not in the range of planet ");
        require ( _recipient != address(0), " recipient address is zero address");

        uint256 rewardId = xyzRewardForUser[_recipient][_planetId][_x][_y][_z];

        require(rewardDB.getRewardInfo(_planetId,rewardId).exist == true , " prize dosn't exist");
        require(rewardDB.getRewardInfo(_planetId,rewardId).received == false , " prize received before");
       

        if (keccak256(abi.encodePacked(rewardDB.getRewardInfo(_planetId,rewardId).rewardType)) == keccak256(abi.encodePacked("nft1155"))){
           token1155.mintRequestedTokenByAdmin ( _recipient , rewardId , rewardDB.getRewardInfo(_planetId,rewardId).rewardAmount , rewardId); 
        }

        else if (keccak256(abi.encodePacked(rewardDB.getRewardInfo(_planetId,rewardId).rewardType)) == keccak256(abi.encodePacked("nft721"))){
           token721.mintRequestedTokenByAdmin ( _recipient , rewardId ); 
        }

      
        rewardDB.insertWinnerInfo(_recipient, _planetId, _x, _y, _z, rewardId );
        rewardDB.setRewardRecieved(_planetId, rewardId, true ); 

        emit RewardRecieved (_recipient , _planetId, rewardId, rewardDB.getRewardInfo(_planetId,rewardId).rewardAmount); 

        return true; 
    }


}
