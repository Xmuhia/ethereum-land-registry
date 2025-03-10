// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title ILandRegistry
 * @dev Interface for the land registry system to enable future extensions and upgrades
 */
interface ILandRegistry {
    /**
     * @dev Structure to store land parcel information
     */
    struct LandParcel {
        string location;             // Description or coordinates
        string physicalSurveyData;   // Could be IPFS hash to detailed survey
        bool verified;               // Whether the claim is verified
        uint256 registrationDate;    // When the land was registered
        string[] documents;          // IPFS hashes to ownership documents
    }

    /**
     * @dev Events that must be emitted by implementers
     */
    event LandRegistered(uint256 tokenId, address owner, string location);
    event LandVerified(uint256 tokenId);
    event VerifierAdded(address verifier);
    event VerifierRemoved(address verifier);
    event DocumentAdded(uint256 tokenId, string documentURI);

    /**
     * @dev Add a verifier who can validate land claims
     * @param verifier Address of the verifier to add
     */
    function addVerifier(address verifier) external;

    /**
     * @dev Remove a verifier
     * @param verifier Address of the verifier to remove
     */
    function removeVerifier(address verifier) external;

    /**
     * @dev Register a new land parcel
     * @param location Text description or coordinates of the land
     * @param physicalSurveyData IPFS hash to survey data
     * @param documentURI IPFS hash to initial ownership document
     * @return tokenId of the newly registered land
     */
    function registerLand(
        string memory location,
        string memory physicalSurveyData,
        string memory documentURI
    ) external returns (uint256);

    /**
     * @dev Verify a land claim (only by authorized verifiers)
     * @param tokenId ID of the land token to verify
     */
    function verifyLand(uint256 tokenId) external;

    /**
     * @dev Add a document to a land parcel's records
     * @param tokenId ID of the land token
     * @param documentURI IPFS hash of the document
     */
    function addDocument(uint256 tokenId, string memory documentURI) external;

    /**
     * @dev Transfer land and update owner mappings
     * @param to Address to transfer the land to
     * @param tokenId ID of the land token
     */
    function transferLand(address to, uint256 tokenId) external;

    /**
     * @dev Get all documents for a land parcel
     * @param tokenId ID of the land token
     * @return Array of document URIs
     */
    function getLandDocuments(uint256 tokenId) external view returns (string[] memory);

    /**
     * @dev Get all land parcels owned by an address
     * @param owner Address to check
     * @return Array of token IDs owned by the address
     */
    function getLandsByOwner(address owner) external view returns (uint256[] memory);

    /**
     * @dev Get land parcel details
     * @param tokenId ID of the land token
     * @return location Description or coordinates
     * @return physicalSurveyData IPFS hash to survey data
     * @return verified Whether the claim is verified
     * @return registrationDate When the land was registered
     * @return documentCount Number of documents attached
     */
    function getLandDetails(uint256 tokenId) external view returns (
        string memory location,
        string memory physicalSurveyData,
        bool verified,
        uint256 registrationDate,
        uint256 documentCount
    );
}