# Confidential Supplier Management System

A privacy-preserving supplier management platform built on blockchain technology with Fully Homomorphic Encryption (FHE) capabilities.

## 🔒 Core Concepts

### FHE Smart Contracts
This platform leverages Fully Homomorphic Encryption (FHE) to protect sensitive supplier information while maintaining functionality. The smart contract enables:

- **Encrypted Rating System**: Supplier quality ratings (1-10) are encrypted using FHE, allowing computations without revealing actual values
- **Privacy-Preserving Comparisons**: Compare supplier ratings without exposing the underlying scores
- **Selective Data Access**: Only authorized parties can decrypt sensitive information
- **On-chain Privacy**: Sensitive data remains encrypted even when stored on the public blockchain

### Confidential Supplier Management

The system provides comprehensive privacy protection for supplier information:

#### 🔐 Privacy-Protected Supplier Information
- **Encrypted Quality Ratings**: Supplier performance scores are encrypted and can only be decrypted by authorized owners
- **Selective Information Disclosure**: Public information (name, category, contact) remains accessible while sensitive data stays protected
- **Owner-Only Access**: Rating decryption and preference status are restricted to data owners
- **Secure Updates**: All sensitive data modifications maintain encryption integrity

## 🚀 Live Demo

**Website**: [https://supplier-management-iota.vercel.app/](https://supplier-management-iota.vercel.app/)

**GitHub Repository**: [https://github.com/KennithPollich/SupplierManagement](https://github.com/KennithPollich/SupplierManagement)

## 📋 Features

### Smart Contract Capabilities
- **Add Suppliers**: Register new suppliers with encrypted rating information
- **Update Ratings**: Modify supplier ratings while maintaining encryption
- **Compare Suppliers**: Privacy-preserving rating comparisons using FHE operations
- **Preference Management**: Set and update preferred supplier status
- **Secure Queries**: Retrieve supplier information with privacy controls

### Security & Privacy
- **FHE Encryption**: Utilizes Zama's FHE library for on-chain privacy
- **Access Control**: Owner-based permission system for sensitive operations
- **Async Decryption**: Secure rating decryption through callback mechanisms
- **Event Logging**: Comprehensive event system for tracking operations

## 🏗️ Technical Architecture

### Smart Contract Structure
```solidity
contract SupplierManagement {
    struct Supplier {
        string name;           // Public
        string category;       // Public
        string contact;        // Public
        euint8 rating;         // FHE Encrypted
        bool isPreferred;      // Owner-only access
        address owner;         // Public
        bool exists;           // Public
    }
}
```

### Core Functions
- `addSupplier()` - Register new suppliers with encrypted ratings
- `updateSupplierRating()` - Modify ratings while preserving encryption
- `requestRatingDecryption()` - Async decryption for authorized users
- `compareSupplierRatings()` - Privacy-preserving rating comparisons
- `getSupplier()` - Retrieve public supplier information

## 🎬 Demonstration

### Video Demo
The project includes a comprehensive video demonstration showcasing (./SupplierManagement.mp4):
- Supplier registration process
- Rating encryption and decryption
- Privacy-preserving operations
- User interface interactions

### On-chain Transaction Evidence (./On-chain Transaction Evidence.png)
Screenshots are provided showing actual blockchain transactions, demonstrating:
- Successful smart contract deployments
- Transaction confirmations on Sepolia testnet
- Gas usage and contract interactions
- Real-world blockchain integration

## 🔗 Contract Information

The smart contract is deployed and operational on the Sepolia testnet, providing a live demonstration of FHE-enabled supplier management functionality.

## 💡 Use Cases

### Enterprise Applications
- **Supply Chain Management**: Protect supplier performance data while enabling comparisons
- **Vendor Evaluation**: Confidential rating systems for procurement decisions
- **Competitive Analysis**: Compare suppliers without revealing sensitive metrics
- **Regulatory Compliance**: Maintain data privacy while meeting transparency requirements

### Privacy Benefits
- **Confidential Ratings**: Supplier scores remain private while supporting decision-making
- **Selective Disclosure**: Choose what information to share with different stakeholders
- **Audit Trail**: Maintain transparent operations without compromising sensitive data
- **Trust Building**: Demonstrate commitment to supplier data protection

## 🛠️ Technology Stack

- **Blockchain**: Ethereum (Sepolia Testnet)
- **Smart Contracts**: Solidity with FHE integration
- **Encryption**: Zama FHE Library
- **Frontend**: HTML5, CSS3, JavaScript
- **Development**: Hardhat framework
- **Hosting**: Vercel platform

## 🔮 Future Enhancements

- **Multi-party Computations**: Enable collaborative supplier evaluations
- **Advanced Analytics**: Privacy-preserving supplier performance analytics
- **Integration APIs**: Connect with existing procurement systems
- **Mobile Application**: Native mobile interface for supplier management
- **Advanced Encryption**: Additional FHE operations for complex business logic

---

*This project demonstrates the practical application of Fully Homomorphic Encryption in real-world business scenarios, providing a foundation for privacy-preserving enterprise applications.*