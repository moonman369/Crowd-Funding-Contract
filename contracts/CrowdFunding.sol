// SPDX-License-Identifier: GNU

import "./DeFundToken.sol";

pragma solidity ^0.8.5;

/// @title CrowdFunding
/// @author Ayan Maiti
/// @notice This is a simple smart contract that implements the functionalities of a crowd funding platform where users can create, donate to and withdraw funds from campaigns with custom parameters like target, deadline, etc. 
/// @dev This is a simple non-upgradable contract. DFND token contract must be deployed and its address must be passed as a parameter while calling this contract's constructor

contract CrowdFunding {


    /* ================================== EVENTS ================================== */

    /// @notice This event is emitted everytime a new campaign is created
    /// @dev Logs can be indexed by new campaign id
    /// @param id: New campaign id
    /// @param owner: Address of owner/creator of the campaign
    event CampaignCreation(uint256 indexed id, address indexed owner);

    /// @notice This event is emitted everytime a donation is made to a campaign
    /// @dev Logs can be indexed by new campaign id
    /// @param id: Id of campaign to which donation was made
    /// @param amount: Amount of tokens donated
    event Donation(uint256 indexed id, uint256 amount);

    /// @notice This event is emitted whenever a campaign owner withdraws collected funds if campaign goal was reached
    /// @dev Logs can be indexed by campaign id and reciver (owner) address
    /// @param id: Campaign id from which funds were withdrawn
    /// @param recipient: Address of recipient i.e campaign owner in this case
    /// @param amount: Amount withdrawn equal to amount collected by the campaign before deadline
    event CollectionWithdrawal(uint256 indexed id, address indexed recipient, uint256 amount);

    /// @notice This event is emitted whenever a donor withdraws donated funds if campaign goal was not reached
    /// @dev Logs can be indexed by campaign id and reciver (donor) address
    /// @param id: Campaign id from which funds were withdrawn
    /// @param recipient: Address of recipient i.e campaign donor in this case
    /// @param amount: Amount withdrawn equal to total amount donated by donor before deadline
    event DonationWithdrawal(uint256 indexed id, address indexed recipient, uint256 amount);

    /// @notice Enumeration to track status of a campaign
    /// @param GOAL_NOT_MET: When campaign goal has not met (0)
    /// @param GOAL_MET: When campaign goal has met (1)
    enum CampaignStatus {
        GOAL_NOT_MET,
        GOAL_MET
    }


    /* ================================== STRUCTS ================================== */

    /// @notice Custom type to store the details of a donor for every donation
    /// @dev This is to be destructured as a tuple on client side. Helps maitain a history of donation events
    /// @param account: Account address of donor
    /// @param amount: Amount donated to donor
    struct Donor {
        address account;
        uint256 amount;
    }

    /// @notice Custom type to store details of a campaign
    /// @param owner: Address of owner of the campaign 
    /// @param goal: Target amount of the campaign
    /// @param deadline: Unix timestamp of the deadline of the campaign (wrt block.timestamp)
    /// @param amountCollected: Amount donated to the campaign at any given time
    /// @param collectionWithdrawn: Indicates if owner has withdrawn collected funds. Prevents double spend 
    /// @param metadataUri: Stores a string containing the URI of campaign metadata such as description, image, etc
    /// @param donors: Dynamic array of type Donorto store the record of every donation event
    /// @param status: Enumeration type parameter to store status of a campaign
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


    /* ================================== STATE VARIABLES ================================== */

    /// @notice Maps integer campaign id keys to Campaign type values
    mapping(uint256 => Campaign) private campaigns;

    /// @notice Nested mapping variable that maps campaign ids to mappings of donor addresses to their donations
    mapping(uint256 => mapping(address => uint256)) private totalDonations;

    /// @notice Nested mapping variable that maps campaign ids to mappings of donor addresses to their donation statuses
    /// @dev Prevents double spend for donation withdrawals
    mapping(uint256 => mapping(address => bool)) private donationWithdrawn;

    /// @notice Stores total number of campaigns created (initial value is set to 0)
    uint256 public campaignCount = 0;

    /// @notice Instance of DeFund token contract to implement transfers. Initialized in constructor with token address
    DeFundToken dfnd;



    /* ================================== CONSTRUCTOR ================================== */

    /// @notice Contract constructor
    /// @dev Initializes DeFund token instance
    /// @param _erc20Address: Address of DFND ERC20 token contract
    constructor(address _erc20Address) {
        dfnd = DeFundToken(payable(_erc20Address));
    }


    /* ================================== MODIFIERS ================================== */

    /// @notice Modifier to check if supplied campaign id maps to an existing campaign
    /// @param _id: Supplied campaign id
    modifier campaignIsValid (uint256 _id) {
        require(
            _id >= 0 && _id < campaignCount, 
            "DeFund: Campaign with passed id doesn't exist."
        );
        _;
    }

    /// @notice Modifier to check if supplied address is not null
    /// @param _owner: Supplied address
    modifier ownerIsValid (address _owner) {
        require(
            _owner != address(0x0), 
            "DeFund: Owner cannot be null address."
        );
        _;
    }

    /// @notice Modifier to check if atleast a minimum of 10 DFND were donated
    /// @param _amount: Donated amount
    modifier minAmount (uint256 _amount) {
        require(
            _amount >= 10, 
            "DeFund: Minimum donation amount is 10 DFND."
        );
        _;
    }

    /// @notice Modifier to check if a function is not being called before particular campaign deadline
    /// @param _id: Campaign id 
    modifier notBeforeDeadline (uint256 _id) {
        Campaign storage campaign = campaigns[_id];
        require(
            campaign.deadline < block.timestamp, 
            "DeFund: Cannot withdraw funds before deadline."
        );
        _;
    }

    /// @notice Modifier to check if a function is not being called after particular campaign deadline
    /// @param _id: Campaign id 
    modifier notAfterDeadline (uint256 _id) {
        Campaign storage campaign = campaigns[_id];
        require(
            campaign.deadline > block.timestamp, 
            "DeFund: Cannot fund campaign after deadline."
        );
        _;
    }

    /* ================================== STATE CHANGING FUNCTIONS ================================== */

    /// @notice Call to create a new campaign with custom parameters
    /// @dev State changing external function 
    /// @param _owner: Address of owner of the new campaign
    /// @param _goal: Target amount of the campaign
    /// @param _deadline: Deadline timestamp of new campaign
    /// @param _metadataUri: Metadata URI
    /// @return id of new campaign 
    function createCampaign(
        address _owner, 
        uint256 _goal, 
        uint256 _deadline, 
        string memory _metadataUri
    ) 
      external 
      ownerIsValid(_owner) // Throws if owner is null.
      returns (uint256) 
      {
        Campaign storage campaign = campaigns[campaignCount]; // Creating a copy object instead of directly updating the mapping for gas efficiency

        require(
            _deadline > block.timestamp, 
            "DeFund: Deadline should be after the current timestamp."
        ); // Throws if deadline is in the past

        // Assigning passed values to campaign instance
        campaign.owner = _owner;
        campaign.goal = _goal;
        campaign.deadline = _deadline;
        campaign.amountCollected = 0;
        campaign.metadataUri = _metadataUri;
        campaign.status = CampaignStatus.GOAL_NOT_MET;

        // Incrementing by one
        campaignCount ++;

        // Emit event with suitable params
        emit CampaignCreation(campaignCount - 1, campaign.owner);

        // Return new campaign id (0 indexed)
        return campaignCount - 1;
    }

    /// @notice Call to donate funds to a specific campaign
    /// @dev State changing external function 
    /// @param _id: Id of campaign to donate to
    /// @param _amount: Amount in DFND to be donated
    /// @return true if token transfer was successful 
    function donateToCampaign(uint256 _id, uint256 _amount) 
    external
    campaignIsValid(_id) // Throws if campaign id is invalid
    notAfterDeadline(_id) // Throws if function is called after deadline
    minAmount(_amount) // Throws if donated amount is less than 10 DFND
    returns (bool) 
    {
        Campaign storage campaign = campaigns[_id];

        // Changing the state of the campaign instance
        campaign.amountCollected += _amount; // Incrementing amountCollected
        campaign.donors.push(Donor({account: msg.sender, amount: _amount})); // Pushing donor details to donors array
        totalDonations[_id][msg.sender] += _amount; // Updating total donations of donor for this campaign

        // Updating campaign status if goal was met
        if(campaign.amountCollected >= campaign.goal) {
            campaign.status = CampaignStatus.GOAL_MET;
        }

        // Calling ERC20 transferFrom to tranfer the funds to the contract account
        bool success = dfnd.transferFrom(msg.sender, address(this), _amount);

        // Emit event with suitable params
        emit Donation(_id, _amount);

        // Return transfer output
        return success;
    }

    /// @notice Call to withdraw collected funds from a campaign after deadline
    /// @dev To be called by campaign owner only
    /// @param _id: Campaign id
    function withdrawCollectedFunds(uint256 _id) 
    external
    campaignIsValid(_id) // Throws if campaign id is invalid
    notBeforeDeadline(_id) // Throws if function is called before deadline
    {
        Campaign storage campaign = campaigns[_id];

        // Throws if function is not called by the owner 
        require(
            campaign.owner == msg.sender, 
            "DeFund: Only owner can withdraw collected funds."
        );

        // Throws if campaign goal was not reached
        require(
            campaign.amountCollected >= campaign.goal, 
            "DeFund: Campaign goal was not met."
        );

        // Throws if the owner has already withdrawn funds
        require(
            !campaign.collectionWithdrawn, 
            "DeFund: Collected funds were already withdrawn."
        );

        // Updating state of campaign instance
        campaign.status = CampaignStatus.GOAL_MET; // If all the above checks pass, it means the campaign goal was met
        campaign.collectionWithdrawn = true; // Collection withdrawn is set to true

        // Calling ERC20 transferFrom to tranfer the funds to the owner address
        dfnd.transfer(msg.sender, campaign.amountCollected);

        // Emit event with suitable params
        emit CollectionWithdrawal(_id, campaign.owner, campaign.amountCollected);
    }

    /// @notice Call to withdraw donated funds from a campaign after deadline if goal was not met
    /// @dev To be called by campaign donors only 
    /// @param _id Campaign id
    function withdrawDonatedFunds(uint256 _id) 
    external
    campaignIsValid(_id) // Throws if campaign id is invalid
    notBeforeDeadline(_id) // Throws if function is called before deadline
    {
        Campaign storage campaign = campaigns[_id];

        // Throws if caller is not a donor
        require(
            totalDonations[_id][msg.sender] > 0, 
            "DeFund: No funds were donated to this campaign by caller."
        );

        // Throws if donor has already withdrawn funds once
        require(
            !donationWithdrawn[_id][msg.sender], 
            "DeFund: Donated funds were already withdrawn."
        );

        // Throws if campaign goal was met
        if (campaign.amountCollected >= campaign.goal) {
            campaign.status = CampaignStatus.GOAL_MET;
            revert("DeFund: Campaign goal was met.");
        }

        // Storing total donated amount in a temporary variable
        uint256 amount = totalDonations[_id][msg.sender];

        // Calling ERC20 transferFrom to tranfer the funds to the donor account
        dfnd.transfer(msg.sender, amount);

        // Setting value to true to prevent double spend
        donationWithdrawn[_id][msg.sender] = true;

        // Emit event with suitable params
        emit DonationWithdrawal(_id, msg.sender, amount);
    }


    /* ================================== VIEW FUNCTIONS ================================== */

    /// @notice Get the record of donors of a particular campaign in chronological order
    /// @param _id: Campaign id
    /// @return Array of Donor type
    function getDonors(uint256 _id) 
    public 
    view 
    returns (Donor[] memory) 
    {
        return campaigns[_id].donors;
    }

    /// @notice Get details of a campaign with given id
    /// @param _id: Campaign id
    /// @return Campaign type value
    function getCampaignById(uint256 _id) 
    public 
    view 
    campaignIsValid(_id) // Throws is campaign id is invalid
    returns (Campaign memory) 
    {
        Campaign memory campaign = campaigns[_id];
        return campaign;
    }

    /// @notice Get details of all existing campaigns
    /// @return Array of Campaign type values
    function getAllCampaigns() public view returns (Campaign[] memory) {
        // Initializing static array of Campaign type with campaignCound length
        Campaign[] memory allCampaigns = new Campaign[](campaignCount);

        // Iterating from 0 to campaignCount - 1
        for (uint256 i = 0; i < campaignCount; i ++) {
            allCampaigns[i] = campaigns[i];
        }

        return allCampaigns;
    }

    /// @notice Return block.timestamp value
    /// @dev This function provides a reference when calling create campaign. Especially in passing acceptable deadlines
    /// @return block.timestamp
    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

}