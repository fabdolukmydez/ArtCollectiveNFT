// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ArtCollectiveNFT
/// @notice ERC721-like NFT with allowlist, reveal mechanic, and per-wallet mint limit.
contract ArtCollectiveNFT {
    string public name = "ArtCollective";
    string public symbol = "ARTC";
    uint256 public totalSupply;
    uint256 public maxSupply;
    uint256 public price; // in wei
    address public owner;
    bool public revealed;
    string public baseURI;

    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public minted;
    mapping(address => bool) public allowlist;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Mint(address indexed to, uint256 indexed id);

    constructor(uint256 _maxSupply, uint256 _price) {
        owner = msg.sender;
        maxSupply = _maxSupply;
        price = _price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "owner");
        _;
    }

    function setAllowlist(address[] calldata adds, bool allowed) external onlyOwner {
        for(uint256 i=0;i<adds.length;i++) allowlist[adds[i]] = allowed;
    }

    function mintAllowlist() external payable {
        require(allowlist[msg.sender], "not allowed");
        require(totalSupply < maxSupply, "sold out");
        require(minted[msg.sender] < 2, "wallet limit");
        require(msg.value >= price, "insufficient");
        uint256 id = totalSupply + 1;
        totalSupply = id;
        ownerOf[id] = msg.sender;
        balanceOf[msg.sender] += 1;
        minted[msg.sender] += 1;
        emit Mint(msg.sender, id);
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        require(ownerOf[id] != address(0), "no token");
        if(!revealed) return "ipfs://unrevealed";
        return string(abi.encodePacked(baseURI, uint2str(id)));
    }

    function reveal(string calldata _base) external onlyOwner {
        baseURI = _base;
        revealed = true;
    }

    // simple transfer
    function transferFrom(address from, address to, uint256 id) external {
        require(ownerOf[id] == from, "not owner");
        ownerOf[id] = to;
        balanceOf[from] -= 1;
        balanceOf[to] += 1;
        emit Transfer(from, to, id);
    }

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        j = _i;
        while (j != 0) { k = k-1; bstr[k] = bytes1(uint8(48 + j % 10)); j /= 10; }
        return string(bstr);
    }

    // withdraw funds
    function withdraw(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }

    receive() external payable {}
}
