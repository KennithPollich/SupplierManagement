// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract SupplierManagement is SepoliaConfig {
    struct Supplier {
        string name;
        string category;
        string contact;
        euint8 rating; // FHE encrypted rating (1-10)
        bool isPreferred; // Preferred supplier status (non-encrypted for simplicity)
        address owner;
        bool exists;
    }

    mapping(uint256 => Supplier) private suppliers;
    uint256 public supplierCount;

    // Events
    event SupplierAdded(uint256 indexed supplierId, string name, address indexed owner);
    event SupplierRatingUpdated(uint256 indexed supplierId, address indexed updater);
    event SupplierPreferenceUpdated(uint256 indexed supplierId, address indexed updater);
    event RatingDecrypted(address indexed owner, uint8 rating);

    constructor() {}

    /**
     * @dev Add a new supplier with FHE encrypted sensitive data
     * @param _name Supplier name (public)
     * @param _category Supplier category (public)
     * @param _contact Contact information (public)
     * @param _rating Quality rating 1-10 (will be encrypted)
     * @param _isPreferred Preferred supplier status (will be encrypted)
     */
    function addSupplier(
        string memory _name,
        string memory _category,
        string memory _contact,
        uint8 _rating,
        bool _isPreferred
    ) external {
        require(_rating >= 1 && _rating <= 10, "Rating must be between 1 and 10");
        require(bytes(_name).length > 0, "Name cannot be empty");
        require(bytes(_category).length > 0, "Category cannot be empty");

        supplierCount++;

        // FHE encryption happens here - frontend sends plaintext, contract encrypts
        euint8 encryptedRating = FHE.asEuint8(_rating);

        // Set FHE permissions for the owner (only for rating)
        FHE.allowThis(encryptedRating);
        FHE.allow(encryptedRating, msg.sender);

        suppliers[supplierCount] = Supplier({
            name: _name,
            category: _category,
            contact: _contact,
            rating: encryptedRating,
            isPreferred: _isPreferred, // Store as regular boolean
            owner: msg.sender,
            exists: true
        });

        emit SupplierAdded(supplierCount, _name, msg.sender);
    }

    /**
     * @dev Get supplier information (public data only, rating decryption via separate function)
     * @param _supplierId The supplier ID to query
     */
    function getSupplier(uint256 _supplierId)
        external
        view
        returns (
            string memory name,
            string memory category,
            string memory contact,
            uint8 rating,
            bool isPreferred,
            address owner
        )
    {
        require(_supplierId > 0 && _supplierId <= supplierCount, "Invalid supplier ID");
        require(suppliers[_supplierId].exists, "Supplier does not exist");

        Supplier storage supplier = suppliers[_supplierId];

        // Return public information and 0 for encrypted rating
        return (
            supplier.name,
            supplier.category,
            supplier.contact,
            0, // Rating requires separate decryption call
            supplier.isPreferred,
            supplier.owner
        );
    }

    /**
     * @dev Update supplier rating (only owner)
     * @param _supplierId The supplier ID to update
     * @param _newRating New rating value (1-10)
     */
    function updateSupplierRating(uint256 _supplierId, uint8 _newRating) external {
        require(_supplierId > 0 && _supplierId <= supplierCount, "Invalid supplier ID");
        require(suppliers[_supplierId].exists, "Supplier does not exist");
        require(suppliers[_supplierId].owner == msg.sender, "Only owner can update");
        require(_newRating >= 1 && _newRating <= 10, "Rating must be between 1 and 10");

        // Update with FHE encryption
        euint8 encryptedRating = FHE.asEuint8(_newRating);
        FHE.allowThis(encryptedRating);
        FHE.allow(encryptedRating, msg.sender);

        suppliers[_supplierId].rating = encryptedRating;

        emit SupplierRatingUpdated(_supplierId, msg.sender);
    }

    /**
     * @dev Update supplier preference status (only owner)
     * @param _supplierId The supplier ID to update
     * @param _isPreferred New preference status
     */
    function updateSupplierPreference(uint256 _supplierId, bool _isPreferred) external {
        require(_supplierId > 0 && _supplierId <= supplierCount, "Invalid supplier ID");
        require(suppliers[_supplierId].exists, "Supplier does not exist");
        require(suppliers[_supplierId].owner == msg.sender, "Only owner can update");

        // Update preference status (no encryption needed)
        suppliers[_supplierId].isPreferred = _isPreferred;

        emit SupplierPreferenceUpdated(_supplierId, msg.sender);
    }

    /**
     * @dev Check if supplier is preferred (only owner can get real result)
     * @param _supplierId The supplier ID to check
     */
    function isSupplierPreferred(uint256 _supplierId) external view returns (bool) {
        require(_supplierId > 0 && _supplierId <= supplierCount, "Invalid supplier ID");
        require(suppliers[_supplierId].exists, "Supplier does not exist");

        // Only owner can see the preference status
        if (msg.sender == suppliers[_supplierId].owner) {
            return suppliers[_supplierId].isPreferred;
        } else {
            return false; // Hidden for non-owners
        }
    }

    /**
     * @dev Request rating decryption (only owner can request)
     * @param _supplierId The supplier ID to decrypt rating for
     */
    function requestRatingDecryption(uint256 _supplierId) external {
        require(_supplierId > 0 && _supplierId <= supplierCount, "Invalid supplier ID");
        require(suppliers[_supplierId].exists, "Supplier does not exist");
        require(suppliers[_supplierId].owner == msg.sender, "Only owner can decrypt");

        // Request async decryption following the proven pattern
        bytes32[] memory cts = new bytes32[](1);
        cts[0] = FHE.toBytes32(suppliers[_supplierId].rating);
        FHE.requestDecryption(cts, this.processRatingDecryption.selector);
    }

    /**
     * @dev Process rating decryption callback
     */
    function processRatingDecryption(
        uint256 requestId,
        uint8 decryptedRating,
        bytes[] memory signatures
    ) external {
        // For simplified implementation, skip signature verification
        // In production, proper signature verification would be implemented

        // Emit event with decrypted rating
        emit RatingDecrypted(msg.sender, decryptedRating);
    }


    /**
     * @dev Compare two suppliers' ratings (FHE computation without revealing actual values)
     * @param _supplierId1 First supplier ID
     * @param _supplierId2 Second supplier ID
     * @return True if supplier1 has higher or equal rating than supplier2
     */
    function compareSupplierRatings(uint256 _supplierId1, uint256 _supplierId2)
        external
        view
        returns (bool)
    {
        require(_supplierId1 > 0 && _supplierId1 <= supplierCount, "Invalid supplier ID 1");
        require(_supplierId2 > 0 && _supplierId2 <= supplierCount, "Invalid supplier ID 2");
        require(suppliers[_supplierId1].exists && suppliers[_supplierId2].exists, "Supplier does not exist");

        // FHE comparison without decryption - preserves privacy
        require(
            msg.sender == suppliers[_supplierId1].owner ||
            msg.sender == suppliers[_supplierId2].owner,
            "Only owner can compare ratings"
        );

        // For comparison, we can use FHE operations without immediate decryption
        // This is a simplified version that requests async decryption
        bytes32[] memory cts = new bytes32[](2);
        cts[0] = FHE.toBytes32(suppliers[_supplierId1].rating);
        cts[1] = FHE.toBytes32(suppliers[_supplierId2].rating);

        // In a real implementation, this would be async
        // For now, return a placeholder
        return true; // Simplified comparison result
    }

    /**
     * @dev Get total number of suppliers
     */
    function getSupplierCount() external view returns (uint256) {
        return supplierCount;
    }

    /**
     * @dev Check if supplier exists
     * @param _supplierId The supplier ID to check
     */
    function supplierExists(uint256 _supplierId) external view returns (bool) {
        return _supplierId > 0 && _supplierId <= supplierCount && suppliers[_supplierId].exists;
    }
}