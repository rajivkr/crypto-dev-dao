// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function purchase(uint256 _tokenId) external payable;

    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);
}

interface ICryptoDevsNFT {
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract CryptoDevsDAO is Ownable {
    enum Vote {
        YES,
        NO
    }
    struct Proposal {
        // The NFT token to buy from the marketplace.
        uint256 nftTokenId;
        // Voting deadline
        uint256 deadline;
        // No. of Votes.
        uint256 yesVotes;
        uint256 noVotes;
        // Output of the proposal.
        bool executed;
        // Check who have voted already.
        mapping(uint256 => bool) voters;
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public numProposals;

    IFakeNFTMarketplace nftMarketplace;
    ICryptoDevsNFT cryptoDevsNFT;

    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_HOLDER");
        _;
    }

    modifier activeProposalOnly(uint256 _proposalId) {
        require(
            proposals[_proposalId].deadline > block.timestamp,
            "PROPOSAL_INACTIVE"
        );
        _;
    }

    modifier inactiveProposalOnly(uint256 _proposalId) {
        require(
            proposals[_proposalId].deadline <= block.timestamp,
            "PROPOSAL_STILL_ACTIVE"
        );
        require(
            proposals[_proposalId].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    // create an proposal - memberonly
    /**
     * @dev _nftTokenId is the NFT to buy from marketplace. Creates a new proposal and returns its id.
     */
    function createProposal(uint256 _nftTokenId)
        external
        nftHolderOnly
        returns (uint256)
    {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");

        Proposal storage propsal = proposals[numProposals];
        propsal.nftTokenId = _nftTokenId;
        propsal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    // vote an proposal - memberonly
    function voteOnProposal(uint256 proposalId, Vote vote)
        external
        nftHolderOnly
        activeProposalOnly(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];

        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);

        uint256 numVotes;

        for (uint8 i = 0; i < voterNFTBalance; ++i) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }

        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YES) {
            proposal.yesVotes += numVotes;
        } else if (vote == Vote.NO) {
            proposal.noVotes += numVotes;
        }
    }

    //execute the proposal - memberonly.
    function executeProposal(uint256 proposalId)
        external
        nftHolderOnly
        inactiveProposalOnly(proposalId)
    {
        Proposal storage proposal = proposals[proposalId];

        // Did the proposal succed?
        if (proposal.yesVotes >= proposal.noVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_PRICE");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }

        proposal.executed = true;
    }

    // fetch the profits and distributed among members.
    function withdrawEther() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
