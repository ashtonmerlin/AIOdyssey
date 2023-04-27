// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./AINFTToken.sol";
import "erc721a/contracts/ERC721A.sol";

contract AIOdysseyNFTV2 is ERC721A, Pausable, Ownable {
    using Counters for Counters.Counter;
    error InvalidMintPrice(uint256);
    error InvalidUri();
    error IllegalArgument();

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    Counters.Counter private _tokenIdCounter;
    AINFTToken public aiNFTToken;
    mapping(address => uint256) public userMintCount;
    mapping(bytes32 => bool) public usedUri;
    mapping(address => mapping(address => bool)) public referenced;

    struct TokenDistribution {
        uint256 refereeAmount;
        uint128 firstMintAmount;
        uint128 defaultMintAmount;
    }

    TokenDistribution public tokenDistributionConfig;

    uint256 public mintPrice;
    address public signer;
    string public baseURI;

    event UpdateMintPrice(uint256 oldPrice, uint256 newPrice);
    event UpdateSigner(address oldSigner, address newSigner);
    event ConfigureTokenDistribution(TokenDistribution oldConfig, TokenDistribution newConfig);

    constructor(address signer_, address airdropToken_) ERC721A("The AI Odyssey", "AIONFT") {
        tokenDistributionConfig.defaultMintAmount = 5000 * 1e18;
        tokenDistributionConfig.firstMintAmount = 10000 * 1e18;
        tokenDistributionConfig.refereeAmount = 5000 * 1e18;
        signer = signer_;
        aiNFTToken = AINFTToken(airdropToken_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function safeMint(address referee, string calldata uri, bytes calldata signature) external payable {
        if (msg.value != mintPrice) revert InvalidMintPrice(msg.value);

        checkUri(uri, signature);

        address minter = msg.sender;
        uint256 tokenId = _nextTokenId();
        userMintCount[minter] = userMintCount[minter] + 1;
        _mint(minter, 1);
        _setTokenURI(tokenId, uri);

        if (userMintCount[minter] == 1) {
            aiNFTToken.mint(minter, tokenDistributionConfig.firstMintAmount);
        } else {
            aiNFTToken.mint(minter, tokenDistributionConfig.defaultMintAmount);
        }
        if (referee != address(0x0) && referee != minter && !referenced[minter][referee]) {
            referenced[minter][referee] = true;
            aiNFTToken.mint(referee, tokenDistributionConfig.refereeAmount);
        }
    }

    function batchMint(uint256 quantity, bytes calldata signature) external {
        address minter = msg.sender;

        checkSig(minter, signature);
        _mint(minter, quantity);

        uint256 currentMintCount = userMintCount[minter];
        userMintCount[minter] = userMintCount[minter] + quantity;

        if (currentMintCount == 0) {
            aiNFTToken.mint(minter, tokenDistributionConfig.firstMintAmount + tokenDistributionConfig.defaultMintAmount * (quantity - 1));
        } else {
            aiNFTToken.mint(minter, tokenDistributionConfig.defaultMintAmount * quantity);
        }
    }

    function checkUri(string calldata uri, bytes calldata signature) private {
        bytes32 uriHash = ECDSA.toEthSignedMessageHash(bytes(uri));
        if (usedUri[uriHash]) revert InvalidUri();
        if (!SignatureChecker.isValidSignatureNow(signer, uriHash, signature)) revert InvalidUri();
        usedUri[uriHash] = true;
    }

    function checkSig(address minter, bytes calldata signature) view private {
        bytes32 msgHash = ECDSA.toEthSignedMessageHash(abi.encodePacked(minter));
        if (!SignatureChecker.isValidSignatureNow(signer, msgHash, signature)) revert IllegalArgument();
    }

    function configureTokenDistribution(TokenDistribution calldata newTokenDistributionConfig) external onlyOwner {
        emit ConfigureTokenDistribution(tokenDistributionConfig, newTokenDistributionConfig);

        tokenDistributionConfig = newTokenDistributionConfig;
    }

    function updateSigner(address newSigner) external onlyOwner {
        emit UpdateSigner(signer, newSigner);

        signer = newSigner;
    }

    function updateMintPrice(uint256 newMintPrice) external onlyOwner {
        emit UpdateMintPrice(mintPrice, newMintPrice);

        mintPrice = newMintPrice;
    }

    function withdraw(address payable to) external onlyOwner {
        Address.sendValue(to, address(this).balance);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal
        whenNotPaused
        override(ERC721A)
    {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}
}