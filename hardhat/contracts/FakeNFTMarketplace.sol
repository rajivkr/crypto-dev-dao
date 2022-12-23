// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract FakeNFTMarketplace {
    //Mapping TokenIDS to Owners
    mapping(uint256 => address) public tokens;

    uint256 nftPrice = 0.001 ether;

    /**
     * @dev takes some ETH and marks the msg.sender address as the owner, if NFT is available.
     */
    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "NOT_ENOUGH_ETH");
        require(tokens[_tokenId] == address(0), "NOT_FOR_SALE");
        tokens[_tokenId] = msg.sender;
    }

    /**
     * @dev gets the price for the NFTs.
     */
    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    /**
     * @dev checks if the NFT is available for purchase.
     */
    function available(uint256 _tokenId) external view returns (bool) {
        return tokens[_tokenId] == address(0);
    }
}
