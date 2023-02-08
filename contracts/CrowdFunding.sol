// SPDX-License-Identifier: GNU

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./DeFundToken.sol";

pragma solidity ^0.8.5;

contract CrowdFunding {

    enum CampaignStatus {
        GOAL_NOT_MET,
        GOAL_MET
    }

    struct Donator {
        address account;
        uint256 amount;
    }

    struct Campaign {
        address owner;
        // mapping (address => uint256) totalDonations;
        uint256 goal;
        uint256 deadline;
        uint256 amountCollected;
        bool fundsWithdrawn;
        string metadataUri;
        Donator [] donators;
        CampaignStatus status;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public totalDonations;
    mapping(uint256 => mapping(address => bool)) public donationWithdrawn;
    uint256 public campaignCount = 0;
    DeFundToken dfnd;
    
    constructor(address _erc20Address) {
        dfnd = DeFundToken(payable(_erc20Address));
    }

    function createCampaign(
        address _owner, 
        uint256 _goal, 
        uint256 _deadline, 
        string memory _metadataUri
    ) external returns (uint256) {
        Campaign storage campaign = campaigns[campaignCount];

        require(_deadline > block.timestamp, "DeFund: Deadline should be a date/time in the future.");

        campaign.owner = _owner;
        campaign.goal = _goal;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.metadataUri = _metadataUri;
        campaign.status = CampaignStatus.GOAL_NOT_MET;

        campaignCount ++;

        return campaignCount - 1;
    }

    function donateToCampaign(uint256 _id, uint256 _amount) external returns (bool) {
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp <= campaign.deadline, "DeFund: Cannot fund campaign after deadline.");



        // (bool sent, ) = payable(campaign.owner).call{value: msg.value}("");


        // if (sent) {
        //     campaign.donators.push(Donator({account: msg.sender, amount: msg.value}));
        //     // campaign.totalDonations[msg.sender] += msg.value;
        //     campaign.amountCollected += msg.value;
        // }

        campaign.amountCollected += _amount;
        campaign.donators.push(Donator({account: msg.sender, amount: _amount}));
        totalDonations[_id][msg.sender] += _amount;

        if(campaign.amountCollected >= campaign.goal) {
            campaign.status = CampaignStatus.GOAL_MET;
        }

        bool success = dfnd.transferFrom(msg.sender, address(this), _amount);

        return success;
    }

    function withdrawCollectedFunds(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];

        require(campaign.owner == msg.sender, "DeFund: Only owner can withdraw collected funds.");
        require(campaign.amountCollected >= 0, "DeFund: No funds were donated to this campaign.");
        require(campaign.deadline < block.timestamp, "DeFund: Cannot withdraw funds before deadline.");
        require(campaign.amountCollected >= campaign.goal, "DeFund: Campaign goal was not met.");
        require(!campaign.fundsWithdrawn, "DeFund: Collected funds were already withdrawn.");

        campaign.status = CampaignStatus.GOAL_MET;
        campaign.fundsWithdrawn = true;

        dfnd.transfer(msg.sender, campaign.amountCollected);
    }

    function withdrawDonatedFunds(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];

        require(totalDonations[_id][msg.sender] > 0, "DeFund: No funds were donated to this campaign by caller.");
        require(campaign.deadline < block.timestamp, "DeFund: Cannot withdraw funds before deadline.");
        require(!donationWithdrawn[_id][msg.sender], "DeFund: Donated funds were already withdrawn.");

        if (campaign.amountCollected >= campaign.goal) {
            campaign.status = CampaignStatus.GOAL_MET;
            revert("DeFund: Campaign goal was met.");
        }

        dfnd.transfer(msg.sender, totalDonations[_id][msg.sender]);
        donationWithdrawn[_id][msg.sender] = true;
    }

    function getDonators(uint256 _id) public view returns (Donator[] memory) {
        return campaigns[_id].donators;
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

}