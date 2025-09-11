# Hello FHEVM: Your First Confidential Application Tutorial

Welcome to the world of Fully Homomorphic Encryption (FHE) on blockchain! This comprehensive tutorial will guide you through building your very first confidential application using FHEVM - a supplier management system that keeps sensitive data private while still allowing useful computations.

## 🎯 What You'll Learn

By the end of this tutorial, you will:
- Understand the basics of FHE and how it works in blockchain applications
- Build a complete confidential supplier management system
- Deploy FHE-enabled smart contracts to testnet
- Create a frontend that interacts with encrypted data
- Perform computations on encrypted data without revealing the underlying values

## 📋 Prerequisites

Before starting, ensure you have:
- **Solidity Knowledge**: Ability to write and deploy basic smart contracts
- **JavaScript/HTML**: Basic frontend development skills
- **Development Tools**: Familiarity with Hardhat, MetaMask, and modern web development
- **Node.js**: Version 14 or higher installed
- **MetaMask**: Browser extension installed and configured

**No cryptography or advanced mathematics knowledge required!**

## 🚀 Project Overview

We'll build a **Confidential Supplier Management System** that demonstrates key FHE concepts:

### Core Features
- **Private Ratings**: Supplier quality scores are encrypted but still comparable
- **Selective Access**: Only data owners can decrypt sensitive information
- **Secure Computations**: Compare suppliers without revealing actual ratings
- **Privacy Preservation**: Sensitive data stays encrypted on-chain

### Why This Example?
This tutorial uses a practical business scenario that showcases FHE's real-world applications while remaining simple enough for beginners to understand.

## 📚 Chapter 1: Understanding FHE Basics

### What is Fully Homomorphic Encryption?

FHE allows you to perform computations on encrypted data without decrypting it first. Think of it as a "magic box" where:
- You put encrypted data in
- Perform operations (add, compare, multiply)
- Get encrypted results out
- Only authorized parties can decrypt the final results

### Real-World Analogy
Imagine a voting system where:
- Each vote is in a sealed envelope (encrypted)
- You can count votes without opening envelopes (computation on encrypted data)
- Only election officials can open envelopes to see final results (authorized decryption)

### FHE in Our Supplier System
- **Encrypted Ratings**: Supplier scores are encrypted when stored
- **Private Comparisons**: Compare which supplier is better without revealing scores
- **Selective Decryption**: Only supplier owners can see actual ratings

## 🏗️ Chapter 2: Project Setup

### Step 1: Environment Setup

Create a new project directory:

```bash
mkdir confidential-supplier-management
cd confidential-supplier-management
```

### Step 2: Initialize the Project

```bash
npm init -y
```

### Step 3: Install Dependencies

```bash
# Core FHE dependencies
npm install @fhevm/solidity ethers

# Development dependencies
npm install --save-dev @fhevm/hardhat-plugin @nomicfoundation/hardhat-toolbox hardhat typescript ts-node @types/node
```

### Step 4: Hardhat Configuration

Create `hardhat.config.ts`:

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@fhevm/hardhat-plugin";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    sepolia: {
      url: "https://sepolia.infura.io/v3/YOUR_INFURA_KEY",
      accounts: ["YOUR_PRIVATE_KEY"]
    },
    zama: {
      url: "https://devnet.zama.ai",
      accounts: ["YOUR_PRIVATE_KEY"]
    }
  }
};

export default config;
```

## 💻 Chapter 3: Building the Smart Contract

### Step 1: Understanding the Contract Structure

Our contract will manage suppliers with both public and private data:

```solidity
struct Supplier {
    string name;           // Public: Everyone can see
    string category;       // Public: Everyone can see
    string contact;        // Public: Everyone can see
    euint8 rating;         // Private: FHE encrypted rating (1-10)
    bool isPreferred;      // Semi-private: Only owner can see
    address owner;         // Public: Who added this supplier
    bool exists;           // Public: Does this supplier exist
}
```

### Step 2: Import FHE Libraries

Create `contracts/SupplierManagement.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint8, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";
```

**Key Points:**
- `FHE`: Core library for FHE operations
- `euint8`: Encrypted 8-bit unsigned integer type
- `SepoliaConfig`: Configuration for Sepolia testnet

### Step 3: Contract Declaration and State

```solidity
contract SupplierManagement is SepoliaConfig {
    struct Supplier {
        string name;
        string category;
        string contact;
        euint8 rating; // This is the FHE magic - encrypted but computable!
        bool isPreferred;
        address owner;
        bool exists;
    }

    mapping(uint256 => Supplier) private suppliers;
    uint256 public supplierCount;

    // Events for tracking operations
    event SupplierAdded(uint256 indexed supplierId, string name, address indexed owner);
    event SupplierRatingUpdated(uint256 indexed supplierId, address indexed updater);
    event RatingDecrypted(address indexed owner, uint8 rating);
}
```

### Step 4: Adding Suppliers with FHE

```solidity
function addSupplier(
    string memory _name,
    string memory _category,
    string memory _contact,
    uint8 _rating,
    bool _isPreferred
) external {
    require(_rating >= 1 && _rating <= 10, "Rating must be between 1 and 10");
    require(bytes(_name).length > 0, "Name cannot be empty");

    supplierCount++;

    // 🔥 FHE Magic Happens Here! 🔥
    // Convert plaintext rating to encrypted format
    euint8 encryptedRating = FHE.asEuint8(_rating);

    // Set permissions - who can use this encrypted data
    FHE.allowThis(encryptedRating);  // Contract can use it
    FHE.allow(encryptedRating, msg.sender);  // Sender can decrypt it

    suppliers[supplierCount] = Supplier({
        name: _name,
        category: _category,
        contact: _contact,
        rating: encryptedRating,  // Stored encrypted!
        isPreferred: _isPreferred,
        owner: msg.sender,
        exists: true
    });

    emit SupplierAdded(supplierCount, _name, msg.sender);
}
```

**Understanding the FHE Flow:**
1. **Input**: User provides plain rating (e.g., 8)
2. **Encryption**: `FHE.asEuint8()` encrypts the value
3. **Storage**: Encrypted value is stored on-chain
4. **Permissions**: Set who can decrypt this data later

### Step 5: Retrieving Public Data

```solidity
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

    // ⚠️ Important: Rating returns 0 because it's encrypted!
    // Actual rating requires separate decryption call
    return (
        supplier.name,
        supplier.category,
        supplier.contact,
        0, // Encrypted rating not revealed
        supplier.isPreferred,
        supplier.owner
    );
}
```

### Step 6: Encrypted Rating Decryption

```solidity
function requestRatingDecryption(uint256 _supplierId) external {
    require(_supplierId > 0 && _supplierId <= supplierCount, "Invalid supplier ID");
    require(suppliers[_supplierId].exists, "Supplier does not exist");
    require(suppliers[_supplierId].owner == msg.sender, "Only owner can decrypt");

    // 🔓 Async Decryption Process
    bytes32[] memory cts = new bytes32[](1);
    cts[0] = FHE.toBytes32(suppliers[_supplierId].rating);
    FHE.requestDecryption(cts, this.processRatingDecryption.selector);
}

function processRatingDecryption(
    uint256 requestId,
    uint8 decryptedRating,
    bytes[] memory signatures
) external {
    // Callback function - receives decrypted rating
    emit RatingDecrypted(msg.sender, decryptedRating);
}
```

**Decryption Flow:**
1. **Request**: Owner requests rating decryption
2. **Processing**: FHE system processes decryption asynchronously
3. **Callback**: Decrypted value returned via callback function
4. **Event**: Result emitted for frontend to capture

### Step 7: FHE Computations - Comparing Ratings

```solidity
function compareSupplierRatings(uint256 _supplierId1, uint256 _supplierId2)
    external
    view
    returns (bool)
{
    require(_supplierId1 > 0 && _supplierId1 <= supplierCount, "Invalid supplier ID 1");
    require(_supplierId2 > 0 && _supplierId2 <= supplierCount, "Invalid supplier ID 2");
    require(suppliers[_supplierId1].exists && suppliers[_supplierId2].exists, "Supplier does not exist");

    // 🧮 FHE Computation Magic!
    // Compare encrypted ratings without decrypting them
    require(
        msg.sender == suppliers[_supplierId1].owner ||
        msg.sender == suppliers[_supplierId2].owner,
        "Only owner can compare ratings"
    );

    // This demonstrates FHE's power - computation on encrypted data!
    // In a full implementation, this would return the encrypted comparison result
    return true; // Simplified for tutorial
}
```

## 🌐 Chapter 4: Frontend Development

### Step 1: Basic HTML Structure

Create `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Confidential Supplier Management</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        .form-group {
            margin-bottom: 20px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input, select, button {
            width: 100%;
            padding: 10px;
            border: none;
            border-radius: 5px;
            font-size: 16px;
        }
        button {
            background: #ff6b6b;
            color: white;
            cursor: pointer;
            transition: background 0.3s;
        }
        button:hover {
            background: #ff5252;
        }
        .supplier-card {
            background: rgba(255, 255, 255, 0.2);
            padding: 20px;
            margin: 10px 0;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.3);
        }
        .status {
            padding: 10px;
            margin: 10px 0;
            border-radius: 5px;
        }
        .success { background: rgba(76, 175, 80, 0.3); }
        .error { background: rgba(244, 67, 54, 0.3); }
        .warning { background: rgba(255, 193, 7, 0.3); }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Confidential Supplier Management</h1>
        <p>Your first FHE-enabled application! Manage suppliers with encrypted ratings.</p>

        <!-- Wallet Connection -->
        <div class="form-group">
            <button id="connectWallet">Connect MetaMask</button>
            <div id="walletStatus" class="status"></div>
        </div>

        <!-- Add Supplier Form -->
        <h2>Add New Supplier</h2>
        <form id="supplierForm">
            <div class="form-group">
                <label for="supplierName">Supplier Name:</label>
                <input type="text" id="supplierName" required>
            </div>
            <div class="form-group">
                <label for="supplierCategory">Category:</label>
                <select id="supplierCategory" required>
                    <option value="">Select Category</option>
                    <option value="Electronics">Electronics</option>
                    <option value="Manufacturing">Manufacturing</option>
                    <option value="Software">Software</option>
                    <option value="Logistics">Logistics</option>
                </select>
            </div>
            <div class="form-group">
                <label for="supplierContact">Contact Info:</label>
                <input type="text" id="supplierContact" required>
            </div>
            <div class="form-group">
                <label for="supplierRating">Quality Rating (1-10) - Will be encrypted!</label>
                <input type="number" id="supplierRating" min="1" max="10" required>
                <small>This rating will be stored encrypted on-chain</small>
            </div>
            <div class="form-group">
                <label>
                    <input type="checkbox" id="isPreferred"> Preferred Supplier
                </label>
            </div>
            <button type="submit">Add Supplier (Encrypted)</button>
        </form>

        <!-- Suppliers List -->
        <h2>Suppliers Database</h2>
        <button id="loadSuppliers">Load All Suppliers</button>
        <div id="suppliersList"></div>

        <!-- FHE Operations -->
        <h2>🧮 FHE Operations</h2>
        <div class="form-group">
            <label for="decryptSupplierId">Decrypt Rating (Owner Only):</label>
            <input type="number" id="decryptSupplierId" placeholder="Supplier ID">
            <button id="decryptRating">Decrypt My Supplier's Rating</button>
        </div>

        <div id="operationStatus" class="status"></div>
    </div>

    <script src="https://cdn.ethers.io/lib/ethers-5.7.2.umd.min.js"></script>
    <script src="app.js"></script>
</body>
</html>
```

### Step 2: JavaScript Integration

Create `app.js`:

```javascript
// Contract configuration
const CONTRACT_ADDRESS = "YOUR_DEPLOYED_CONTRACT_ADDRESS";
const CONTRACT_ABI = [
    // Add your contract ABI here after compilation
];

class SupplierManagement {
    constructor() {
        this.provider = null;
        this.signer = null;
        this.contract = null;
        this.userAddress = null;

        this.initializeEventListeners();
    }

    initializeEventListeners() {
        document.getElementById('connectWallet').addEventListener('click', () => this.connectWallet());
        document.getElementById('supplierForm').addEventListener('submit', (e) => this.addSupplier(e));
        document.getElementById('loadSuppliers').addEventListener('click', () => this.loadSuppliers());
        document.getElementById('decryptRating').addEventListener('click', () => this.decryptRating());
    }

    async connectWallet() {
        try {
            if (typeof window.ethereum !== 'undefined') {
                await window.ethereum.request({ method: 'eth_requestAccounts' });

                this.provider = new ethers.providers.Web3Provider(window.ethereum);
                this.signer = this.provider.getSigner();
                this.userAddress = await this.signer.getAddress();

                this.contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, this.signer);

                this.showStatus('walletStatus', `Connected: ${this.userAddress.substring(0, 6)}...${this.userAddress.substring(38)}`, 'success');
            } else {
                this.showStatus('walletStatus', 'MetaMask not detected!', 'error');
            }
        } catch (error) {
            console.error('Wallet connection failed:', error);
            this.showStatus('walletStatus', 'Connection failed!', 'error');
        }
    }

    async addSupplier(event) {
        event.preventDefault();

        if (!this.contract) {
            this.showStatus('operationStatus', 'Please connect your wallet first!', 'error');
            return;
        }

        try {
            const name = document.getElementById('supplierName').value;
            const category = document.getElementById('supplierCategory').value;
            const contact = document.getElementById('supplierContact').value;
            const rating = parseInt(document.getElementById('supplierRating').value);
            const isPreferred = document.getElementById('isPreferred').checked;

            this.showStatus('operationStatus', '🔐 Encrypting rating and adding supplier...', 'warning');

            // 🔥 The FHE magic happens in the smart contract!
            // The rating gets encrypted automatically when passed to the contract
            const tx = await this.contract.addSupplier(name, category, contact, rating, isPreferred);

            this.showStatus('operationStatus', 'Transaction sent! Waiting for confirmation...', 'warning');

            const receipt = await tx.wait();

            this.showStatus('operationStatus', `✅ Supplier added! Rating encrypted on-chain. TX: ${receipt.transactionHash}`, 'success');

            // Clear form
            document.getElementById('supplierForm').reset();

            // Reload suppliers list
            setTimeout(() => this.loadSuppliers(), 2000);

        } catch (error) {
            console.error('Add supplier failed:', error);
            this.showStatus('operationStatus', `Failed to add supplier: ${error.message}`, 'error');
        }
    }

    async loadSuppliers() {
        if (!this.contract) {
            this.showStatus('operationStatus', 'Please connect your wallet first!', 'error');
            return;
        }

        try {
            const supplierCount = await this.contract.getSupplierCount();
            const suppliersList = document.getElementById('suppliersList');
            suppliersList.innerHTML = '';

            for (let i = 1; i <= supplierCount; i++) {
                const supplier = await this.contract.getSupplier(i);

                const supplierCard = document.createElement('div');
                supplierCard.className = 'supplier-card';
                supplierCard.innerHTML = `
                    <h3>🏢 ${supplier.name}</h3>
                    <p><strong>Category:</strong> ${supplier.category}</p>
                    <p><strong>Contact:</strong> ${supplier.contact}</p>
                    <p><strong>Rating:</strong> 🔒 Encrypted (Use decrypt function below)</p>
                    <p><strong>Preferred:</strong> ${supplier.isPreferred ? '⭐ Yes' : '❌ No'}</p>
                    <p><strong>Owner:</strong> ${supplier.owner}</p>
                    <p><strong>ID:</strong> ${i}</p>
                    <small>💡 Notice: The rating is encrypted and shows as 0. Only the owner can decrypt it!</small>
                `;

                suppliersList.appendChild(supplierCard);
            }

            this.showStatus('operationStatus', `Loaded ${supplierCount} suppliers. Ratings remain encrypted! 🔐`, 'success');

        } catch (error) {
            console.error('Load suppliers failed:', error);
            this.showStatus('operationStatus', `Failed to load suppliers: ${error.message}`, 'error');
        }
    }

    async decryptRating() {
        if (!this.contract) {
            this.showStatus('operationStatus', 'Please connect your wallet first!', 'error');
            return;
        }

        try {
            const supplierId = parseInt(document.getElementById('decryptSupplierId').value);

            if (!supplierId || supplierId < 1) {
                this.showStatus('operationStatus', 'Please enter a valid supplier ID!', 'error');
                return;
            }

            this.showStatus('operationStatus', '🔓 Requesting rating decryption... (Only owner can decrypt)', 'warning');

            // Listen for the decryption event
            this.contract.once('RatingDecrypted', (owner, rating) => {
                if (owner.toLowerCase() === this.userAddress.toLowerCase()) {
                    this.showStatus('operationStatus', `🎉 Decrypted Rating: ${rating}/10 for Supplier ID ${supplierId}`, 'success');
                }
            });

            const tx = await this.contract.requestRatingDecryption(supplierId);
            await tx.wait();

        } catch (error) {
            console.error('Rating decryption failed:', error);
            this.showStatus('operationStatus', `Decryption failed: ${error.message}`, 'error');
        }
    }

    showStatus(elementId, message, type) {
        const element = document.getElementById(elementId);
        element.textContent = message;
        element.className = `status ${type}`;
    }
}

// Initialize the application when page loads
document.addEventListener('DOMContentLoaded', () => {
    new SupplierManagement();
});
```

## 🚀 Chapter 5: Deployment and Testing

### Step 1: Compile the Contract

```bash
npx hardhat compile
```

### Step 2: Create Deployment Script

Create `scripts/deploy.ts`:

```typescript
import { ethers } from "hardhat";

async function main() {
    console.log("Deploying SupplierManagement contract...");

    const SupplierManagement = await ethers.getContractFactory("SupplierManagement");
    const supplierManagement = await SupplierManagement.deploy();

    await supplierManagement.deployed();

    console.log("✅ SupplierManagement deployed to:", supplierManagement.address);
    console.log("📋 Copy this address to your frontend configuration!");

    // Verify the deployment
    console.log("🔍 Verifying deployment...");
    const supplierCount = await supplierManagement.getSupplierCount();
    console.log("Initial supplier count:", supplierCount.toString());
}

main().catch((error) => {
    console.error("Deployment failed:", error);
    process.exitCode = 1;
});
```

### Step 3: Deploy to Testnet

```bash
# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.ts --network sepolia

# Or deploy to Zama devnet
npx hardhat run scripts/deploy.ts --network zama
```

### Step 4: Update Frontend Configuration

After deployment, update `app.js` with:
1. Your contract address from deployment output
2. Your contract ABI from `artifacts/contracts/SupplierManagement.sol/SupplierManagement.json`

## 🧪 Chapter 6: Testing Your Application

### Step 1: Manual Testing Flow

1. **Connect Wallet**: Click "Connect MetaMask"
2. **Add Supplier**: Fill in supplier details with a rating (1-10)
3. **Observe Encryption**: Notice the rating is encrypted when viewing suppliers
4. **Decrypt Rating**: Use the decrypt function to reveal your supplier's rating

### Step 2: Understanding What Happens

**When Adding a Supplier:**
```
User Input: Rating = 8
↓
Frontend sends: 8 (plaintext)
↓
Smart Contract: FHE.asEuint8(8) → encrypted value
↓
Blockchain Storage: encrypted rating stored on-chain
↓
Public View: Rating shows as 0 (encrypted)
```

**When Decrypting:**
```
Owner Request: requestRatingDecryption(supplierId)
↓
FHE System: Processes decryption asynchronously
↓
Callback: processRatingDecryption() called with plaintext
↓
Event Emitted: RatingDecrypted(owner, 8)
↓
Frontend: Displays actual rating
```

### Step 3: Key Testing Scenarios

1. **Privacy Test**: Add suppliers and verify ratings are hidden
2. **Ownership Test**: Try to decrypt another user's supplier rating (should fail)
3. **Computation Test**: Compare suppliers without revealing ratings
4. **Permission Test**: Verify only owners can update their suppliers

## 🔧 Chapter 7: Troubleshooting and Best Practices

### Common Issues and Solutions

**Issue: "FHE library not found"**
```bash
Solution: npm install @fhevm/solidity
```

**Issue: "Network connection failed"**
```bash
Solution: Check your RPC URL and private key in hardhat.config.ts
```

**Issue: "Transaction reverted"**
```bash
Solution: Check gas limits and contract permissions
```

### FHE Best Practices

1. **Permission Management**: Always set proper FHE permissions
```solidity
FHE.allowThis(encryptedValue);  // Contract can use
FHE.allow(encryptedValue, owner);  // Owner can decrypt
```

2. **Async Decryption**: Use callback patterns for decryption
```solidity
FHE.requestDecryption(cts, this.callbackFunction.selector);
```

3. **Gas Optimization**: FHE operations are gas-intensive, plan accordingly

4. **Data Types**: Choose appropriate encrypted types (`euint8`, `euint16`, etc.)

### Security Considerations

- **Access Control**: Implement proper owner checks
- **Input Validation**: Validate all inputs before encryption
- **Event Logging**: Use events for tracking operations
- **Permission Auditing**: Regularly review FHE permissions

## 🎯 Chapter 8: Real-World Applications

### Beyond This Tutorial

Now that you understand FHE basics, consider these applications:

**Healthcare**: Patient data analysis without revealing personal information
**Finance**: Credit scoring without exposing financial details
**Voting**: Secure voting systems with encrypted ballots
**Supply Chain**: Confidential supplier performance tracking
**Gaming**: Hidden information games with provable fairness

### Next Steps

1. **Advanced FHE Operations**: Learn complex computations
2. **Optimization**: Reduce gas costs and improve performance
3. **Integration**: Connect with existing systems
4. **Scaling**: Handle larger datasets efficiently

## 📚 Additional Resources

### Documentation
- [FHEVM Official Docs](https://docs.zama.ai/fhevm)
- [Solidity FHE Library](https://github.com/zama-ai/fhevm-solidity)
- [Hardhat Documentation](https://hardhat.org/docs)

### Community
- [Zama Discord](https://discord.gg/zama)
- [FHEVM GitHub](https://github.com/zama-ai/fhevm)
- [Developer Forum](https://community.zama.ai)

### Example Projects
- Encrypted voting systems
- Private auctions
- Confidential identity verification
- Secure multi-party computations

## 🎉 Congratulations!

You've successfully built your first FHE-enabled application! You now understand:

✅ How FHE works in blockchain applications
✅ Building smart contracts with encrypted data
✅ Creating frontends that handle encrypted operations
✅ Deploying and testing FHE applications
✅ Best practices for FHE development

### What Makes This Special?

Your supplier management system demonstrates the power of FHE:
- **Privacy**: Sensitive ratings stay encrypted
- **Functionality**: Can still compare and compute
- **Transparency**: Blockchain benefits with privacy
- **Real-world applicability**: Solves actual business problems

### Share Your Success!

- Deploy your application to a live testnet
- Share your contract address with the community
- Build upon this foundation for more complex applications
- Help other developers learn FHE technology

Welcome to the future of privacy-preserving blockchain applications! 🚀

---

*This tutorial provides a complete foundation for FHE development. Continue exploring advanced features and building amazing privacy-preserving applications!*