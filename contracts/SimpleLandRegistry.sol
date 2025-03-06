// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title SimpleLandRegistry
 * @dev Core contract for registering and managing land ownership on blockchain
 */
contract SimpleLandRegistry is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    struct LandParcel {
        string location;          // Description or coordinates
        string physicalSurveyData; // Could be IPFS hash to detailed survey
        bool verified;            // Whether the claim is verified
        uint256 registrationDate;
        string[] documents;       // IPFS hashes to ownership documents
    }
    
    // Maps tokenId to land details
    mapping(uint256 => LandParcel) public landParcels;
    
    // Maps location hash to tokenId to prevent duplicate registrations
    mapping(bytes32 => uint256) public locationToTokenId;
    
    // Maps address to array of owned tokenIds for easy lookup
    mapping(address => uint256[]) public ownerLandParcels;
    
    // Authorized verifiers who can mark land claims as verified
    mapping(address => bool) public verifiers;
    
    // Events
    event LandRegistered(uint256 tokenId, address owner, string location);
    event LandVerified(uint256 tokenId);
    event VerifierAdded(address verifier);
    event VerifierRemoved(address verifier);
    event DocumentAdded(uint256 tokenId, string documentURI);
    
    constructor() ERC721("Land Ownership Token", "LAND") {}
    
    /**
     * @dev Add a verifier who can validate land claims
     */
    function addVerifier(address verifier) external onlyOwner {
        verifiers[verifier] = true;
        emit VerifierAdded(verifier);
    }
    
    /**
     * @dev Remove a verifier
     */
    function removeVerifier(address verifier) external onlyOwner {
        verifiers[verifier] = false;
        emit VerifierRemoved(verifier);
    }
    
    /**
     * @dev Register a new land parcel
     * @param location Text description or coordinates of the land
     * @param physicalSurveyData IPFS hash to survey data
     * @param documentURI IPFS hash to initial ownership document
     */
    function registerLand(
        string memory location,
        string memory physicalSurveyData,
        string memory documentURI
    ) external returns (uint256) {
        // Create a hash of the location to ensure uniqueness
        bytes32 locationHash = keccak256(abi.encodePacked(location));
        
        // Ensure this location hasn't been registered
        require(locationToTokenId[locationHash] == 0, "Location already registered");
        
        // Increment and get the new token ID
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        // Mint the NFT representing this land parcel
        _safeMint(msg.sender, newTokenId);
        
        // Set token URI to the physical survey data
        _setTokenURI(newTokenId, physicalSurveyData);
        
        // Create the land parcel record
        string[] memory initialDocs = new string[](1);
        initialDocs[0] = documentURI;
        
        landParcels[newTokenId] = LandParcel({
            location: location,
            physicalSurveyData: physicalSurveyData,
            verified: false,
            registrationDate: block.timestamp,
            documents: initialDocs
        });
        
        // Map location to token ID to prevent duplicates
        locationToTokenId[locationHash] = newTokenId;
        
        // Add to owner's land parcels for easy lookup
        ownerLandParcels[msg.sender].push(newTokenId);
        
        emit LandRegistered(newTokenId, msg.sender, location);
        
        return newTokenId;
    }
    
    /**
     * @dev Verify a land claim (only by authorized verifiers)
     */
    function verifyLand(uint256 tokenId) external {
        require(verifiers[msg.sender], "Not an authorized verifier");
        require(_exists(tokenId), "Token does not exist");
        require(!landParcels[tokenId].verified, "Land already verified");
        
        landParcels[tokenId].verified = true;
        emit LandVerified(tokenId);
    }
    
    /**
     * @dev Add a document to a land parcel's records
     */
    function addDocument(uint256 tokenId, string memory documentURI) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        landParcels[tokenId].documents.push(documentURI);
        emit DocumentAdded(tokenId, documentURI);
    }
    
    /**
     * @dev Transfer land and update owner mappings
     */
    function transferLand(address to, uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        
        // Find and remove from current owner's array
        uint256[] storage currentOwnerLands = ownerLandParcels[msg.sender];
        for (uint256 i = 0; i < currentOwnerLands.length; i++) {
            if (currentOwnerLands[i] == tokenId) {
                // Replace with the last element and pop
                currentOwnerLands[i] = currentOwnerLands[currentOwnerLands.length - 1];
                currentOwnerLands.pop();
                break;
            }
        }
        
        // Add to new owner's array
        ownerLandParcels[to].push(tokenId);
        
        // Transfer the token
        _transfer(msg.sender, to, tokenId);
    }
    
    /**
     * @dev Get all documents for a land parcel
     */
    function getLandDocuments(uint256 tokenId) external view returns (string[] memory) {
        require(_exists(tokenId), "Token does not exist");
        return landParcels[tokenId].documents;
    }
    
    /**
     * @dev Get all land parcels owned by an address
     */
    function getLandsByOwner(address owner) external view returns (uint256[] memory) {
        return ownerLandParcels[owner];
    }
    
    /**
     * @dev Get land parcel details
     */
    function getLandDetails(uint256 tokenId) external view returns (
        string memory location,
        string memory physicalSurveyData,
        bool verified,
        uint256 registrationDate,
        uint256 documentCount
    ) {
        require(_exists(tokenId), "Token does not exist");
        LandParcel storage parcel = landParcels[tokenId];
        
        return (
            parcel.location,
            parcel.physicalSurveyData,
            parcel.verified,
            parcel.registrationDate,
            parcel.documents.length
        );
    }
    
    /**
     * @dev Overridden transferFrom to update our mappings
     */
    function transferFrom(address from, address to, uint256 tokenId) public override {
        super.transferFrom(from, to, tokenId);
        
        // Update our mappings
        uint256[] storage fromLands = ownerLandParcels[from];
        for (uint256 i = 0; i < fromLands.length; i++) {
            if (fromLands[i] == tokenId) {
                fromLands[i] = fromLands[fromLands.length - 1];
                fromLands.pop();
                break;
            }
        }
        
        ownerLandParcels[to].push(tokenId);
    }
    
    /**
     * @dev Overridden safeTransferFrom to update our mappings
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        super.safeTransferFrom(from, to, tokenId, data);
        
        // Update our mappings
        uint256[] storage fromLands = ownerLandParcels[from];
        for (uint256 i = 0; i < fromLands.length; i++) {
            if (fromLands[i] == tokenId) {
                fromLands[i] = fromLands[fromLands.length - 1];
                fromLands.pop();
                break;
            }
        }
        
        ownerLandParcels[to].push(tokenId);
    }
}