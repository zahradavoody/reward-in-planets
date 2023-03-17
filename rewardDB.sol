// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract RewardDB is Ownable {

    struct reward
    {

        uint256 rewardId;
        uint256 rewardAmount;
        bool exist;
        bool enable;
        bool received;
        string rewardType;

    }


    struct winReward
    {
        uint256 rewardId;
        int256 x;
        int256 y;
        int256 z;
        
    }

    address private checkReward;


    mapping (address => bool )  private admins;

    mapping (uint256 => mapping (uint256 => reward)) public rewardInfo;

    mapping (uint256 => uint256) totalRewardAmount ;

    mapping (address => mapping (uint256 => mapping (int256 => mapping (int256 => mapping(int256 => uint256))))) public WinRewardId;

    mapping (address => mapping (uint256 => mapping( uint256 => winReward))) public WinRewardXYZ;


    modifier onlyOwnerOrAdmins()
    {
        require( msg.sender == owner() || admins[msg.sender] , " checkReward - onlyOwners - Owner/Admin Role Required." ) ;
        _;
    }

    modifier onlyCheckReward()
    {
        require ( msg.sender == checkReward , "only checkReward smart contract can call this function");
        _;
    }


    modifier onlyOwnerOrAdminsOrCheckReward()
    {
        require( msg.sender == owner() || admins[msg.sender] || msg.sender == checkReward, " checkReward - only Owners or Admins or CheckReward smart contract Role Required." ) ;
        _;
    }



    event AddAdminRole(address indexed adminAddress, string indexed role );
    event DelAdminRole(address indexed adminAddress, string indexed role );


    function addAdminRole ( address subject  ) external onlyOwner
    {

        admins[subject] = true ; 
        emit AddAdminRole( subject , "Admin" ) ; 

    }

    function removeAdminRole ( address subject  ) external onlyOwner
    {
        require ( subject != owner() , "NFT1155 - Owner Can't be Deleted" ) ; 
        admins[subject] = false ; 
        emit DelAdminRole( subject , "Admin") ; 

    }


    function setCheckRewardAddress (address _CheckReward ) external onlyOwner
    {
        require ( _CheckReward != address(0), " address shouldn't be 0 ");
        checkReward =_CheckReward;

    }


    function insertReward( uint256 _planetId, uint256 _rewardId , uint256 _rewardAmount , string memory _rewardType) external onlyOwnerOrAdmins returns(bool)
    {
        require ( rewardInfo[_planetId][_rewardId].exist == false , " reward Already Exist");
        require (_rewardId != 0 && _rewardAmount != 0 , " rewardId and rewardAmount shouldn't be 0");

        reward memory temp = reward( _rewardId , _rewardAmount  , true , true , false , _rewardType);
        rewardInfo[_planetId][_rewardId] = temp; 

        totalRewardAmount[_planetId]++;

        //  emit PrizeCreatedInXyz( _x, _y , _z , _tokenId, _tokenAmount);
       return true ;         
    }


    function getTotalRewardAmount (uint256 _planetId) external view onlyOwnerOrAdminsOrCheckReward returns (uint256)
    {

        return totalRewardAmount[_planetId];

    }
   

   function updateRewardInfo( uint256 _planetId, uint256 _rewardId , uint256 _rewardAmount , string memory _rewardType) external onlyOwnerOrAdmins returns(bool)
   {

        require ( rewardInfo[_planetId][_rewardId].exist == true , " reward dosn't Already Exist");
        require (_rewardId != 0 && _rewardAmount != 0 , " rewardId and rewardAmount shouldnt be 0");
        rewardInfo[_planetId][_rewardId].rewardAmount = _rewardAmount;
        rewardInfo[_planetId][_rewardId].rewardType = _rewardType;      

        return true;
   }


   function insertWinnerInfo( address _recipient, uint256 _planetId, int256 _x, int256 _y, int256 _z , uint256 _rewardId) external onlyCheckReward returns( bool)
   {
      
        WinRewardId[_recipient][_planetId][_x][_y][_z] = _rewardId; 

        winReward memory temp = winReward( _rewardId, _x  , _y , _z );
        WinRewardXYZ[ _recipient][_planetId][ _rewardId] = temp;

       return true;

   }


   function getWinRewardId (address _recipient, uint256 _planetId , int256 _x, int256 _y, int256 _z) external view onlyOwnerOrAdmins returns(uint256)
    {

        return WinRewardId[_recipient][_planetId][_x][_y][_z];

   }

   function getWinRewardXYZ (address _recipient, uint256 _planetId , uint256 _rewardId) external view onlyOwnerOrAdmins returns(winReward memory)
   {
       return WinRewardXYZ[_recipient][_planetId][_rewardId];
   }


   function setRewardRecieved(uint256 _planetId, uint256 _rewardId, bool _recieved) external onlyCheckReward returns( bool)
   {
       rewardInfo[_planetId][_rewardId].received = _recieved;
       return true; 
   }


   function getRewardInfo (uint256 _planetId, uint256 _rewardId) external onlyOwnerOrAdminsOrCheckReward view returns (reward memory)
   {
       reward memory rewardInfoTemp = rewardInfo[_planetId][_rewardId];
        return rewardInfoTemp; 

   }

}
