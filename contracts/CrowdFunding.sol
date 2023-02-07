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
        string metadataUri;
        Donator [] donators;
        CampaignStatus status;
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public totalDonations;
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


        // (bool sent, ) = payable(campaign.owner).call{value: msg.value}("");


        // if (sent) {
        //     campaign.donators.push(Donator({account: msg.sender, amount: msg.value}));
        //     // campaign.totalDonations[msg.sender] += msg.value;
        //     campaign.amountCollected += msg.value;
        // }

        campaign.amountCollected += _amount;
        totalDonations[_id][msg.sender] += _amount;
        bool success = dfnd.transferFrom(msg.sender, address(this), _amount);

        return success;
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