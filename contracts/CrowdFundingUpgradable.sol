// SPDX-License-Identifier: GNU

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DeFundToken.sol";

pragma solidity ^0.8.5;

contract CrowdFundingUpgradable {

    event CampaignCreation(uint256 indexed id, address indexed owner);
    event Donation(uint256 indexed id, uint256 amount);
    event CollectionWithdrawal(uint256 indexed id, address indexed recipient, uint256 amount);
    event DonationWithdrawal(uint256 indexed id, address indexed recipient, uint256 amount);

    enum CampaignStatus {
        GOAL_NOT_MET,
        GOAL_MET
    }

    struct Donor {
        address account;
        uint256 amount;
    }

    struct Campaign {
        address owner;
        uint256 goal;
        uint256 deadline;
        uint256 amountCollected;
        bool collectionWithdrawn;
        string metadataUri;
        Donor [] donors;
        CampaignStatus status;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public totalDonations;
    mapping(uint256 => mapping(address => bool)) public donationWithdrawn;
    uint256 public campaignCount = 0;
    bool public initializerCalled = false;
    DeFundToken dfnd;
    
    function setTokenAddress(address _erc20Address) public {
        require(
            !initializerCalled,
            "DeFund: Cannot call initializer more than once"
            );
        initializerCalled = true;
        dfnd = DeFundToken(payable(_erc20Address));
    }

    modifier campaignIsValid (uint256 _id) {
        require(
            _id >= 0 && _id < campaignCount, 
            "DeFund: Campaign with passed id doesn't exist."
        );
        _;
    }

    modifier ownerIsValid (address _owner) {
        require(
            _owner != address(0x0), 
            "DeFund: Owner cannot be null address."
        );
        _;
    }

    modifier minAmount (uint256 _amount) {
        require(
            _amount >= 10, 
            "DeFund: Minimum donation amount is 10 DFND."
        );
        _;
    }

    modifier notBeforeDeadline (uint256 _id) {
        Campaign storage campaign = campaigns[_id];
        require(
            campaign.deadline < block.timestamp, 
            "DeFund: Cannot withdraw funds before deadline."
        );
        _;
    }

    modifier notAfterDeadline (uint256 _id) {
        Campaign storage campaign = campaigns[_id];
        require(
            campaign.deadline > block.timestamp, 
            "DeFund: Cannot fund campaign after deadline."
        );
        _;
    }

    function createCampaign(
        address _owner, 
        uint256 _goal, 
        uint256 _deadline, 
        string memory _metadataUri
    ) 
      external 
      ownerIsValid(_owner) 
      returns (uint256) 
      {
        Campaign storage campaign = campaigns[campaignCount];

        require(
            _deadline > block.timestamp, 
            "DeFund: Deadline should be after the current timestamp."
        );

        campaign.owner = _owner;
        campaign.goal = _goal;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.metadataUri = _metadataUri;
        campaign.status = CampaignStatus.GOAL_NOT_MET;

        campaignCount ++;

        emit CampaignCreation(campaignCount - 1, campaign.owner);

        return campaignCount - 1;
    }

    function donateToCampaign(uint256 _id, uint256 _amount) 
    external
    campaignIsValid(_id)
    notAfterDeadline(_id) 
    minAmount(_amount)
    returns (bool) {
        Campaign storage campaign = campaigns[_id];

        campaign.amountCollected += _amount;
        campaign.donors.push(Donor({account: msg.sender, amount: _amount}));
        totalDonations[_id][msg.sender] += _amount;

        if(campaign.amountCollected >= campaign.goal) {
            campaign.status = CampaignStatus.GOAL_MET;
        }

        bool success = dfnd.transferFrom(msg.sender, address(this), _amount);

        emit Donation(_id, _amount);

        return success;
    }

    function withdrawCollectedFunds(uint256 _id) 
    external
    campaignIsValid(_id)
    notBeforeDeadline(_id) {
        Campaign storage campaign = campaigns[_id];

        require(
            campaign.owner == msg.sender, 
            "DeFund: Only owner can withdraw collected funds."
        );

        require(
            campaign.amountCollected >= campaign.goal, 
            "DeFund: Campaign goal was not met."
        );
        require(
            !campaign.collectionWithdrawn, 
            "DeFund: Collected funds were already withdrawn."
        );

        campaign.status = CampaignStatus.GOAL_MET;
        campaign.collectionWithdrawn = true;

        dfnd.transfer(msg.sender, campaign.amountCollected);

        emit CollectionWithdrawal(_id, campaign.owner, campaign.amountCollected);
    }

    function withdrawDonatedFunds(uint256 _id) 
    external
    campaignIsValid(_id)
    notBeforeDeadline(_id) {
        Campaign storage campaign = campaigns[_id];

        require(
            totalDonations[_id][msg.sender] > 0, 
            "DeFund: No funds were donated to this campaign by caller."
        );

        require(
            !donationWithdrawn[_id][msg.sender], 
            "DeFund: Donated funds were already withdrawn."
        );

        if (campaign.amountCollected >= campaign.goal) {
            campaign.status = CampaignStatus.GOAL_MET;
            revert("DeFund: Campaign goal was met.");
        }

        uint256 amount = totalDonations[_id][msg.sender];

        dfnd.transfer(msg.sender, amount);
        donationWithdrawn[_id][msg.sender] = true;

        emit DonationWithdrawal(_id, msg.sender, amount);
    }

    function getDonators(uint256 _id) public view returns (Donor[] memory) {
        return campaigns[_id].donors;
    }

    function getCampaignById(uint256 _id) public view returns (Campaign memory) {
        Campaign memory campaign = campaigns[_id];
        return campaign;
    }

    function getAllCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory allCampaigns = new Campaign[](campaignCount);
        
        for (uint256 i = 0; i < campaignCount; i ++) {
            allCampaigns[i] = campaigns[i];
        }

        return allCampaigns;
    }

    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

}