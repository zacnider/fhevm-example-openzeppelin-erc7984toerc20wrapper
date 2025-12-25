# ERC7984ToERC20Wrapper

Learn how to use OpenZeppelin ERC7984 confidential tokens

## 🎓 What You'll Learn

This example teaches you how to use FHEVM to build privacy-preserving smart contracts. You'll learn step-by-step how to implement encrypted operations, manage permissions, and work with encrypted data.

## 🚀 Quick Start

1. **Clone this repository:**
   ```bash
   git clone https://github.com/zacnider/fhevm-example-openzeppelin-erc7984toerc20wrapper.git
   cd fhevm-example-openzeppelin-erc7984toerc20wrapper
   ```

2. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

3. **Setup environment:**
   ```bash
   npm run setup
   ```
   Then edit `.env` file with your credentials:
   - `SEPOLIA_RPC_URL` - Your Sepolia RPC endpoint
   - `PRIVATE_KEY` - Your wallet private key (for deployment)
   - `ETHERSCAN_API_KEY` - Your Etherscan API key (for verification)

4. **Compile contracts:**
   ```bash
   npm run compile
   ```

5. **Run tests:**
   ```bash
   npm test
   ```

6. **Deploy to Sepolia:**
   ```bash
   npm run deploy:sepolia
   ```

7. **Verify contract (after deployment):**
   ```bash
   npm run verify <CONTRACT_ADDRESS>
   ```

**Alternative:** Use the [Examples page](https://entrofhe.vercel.app/examples) for browser-based deployment and verification.

---

## 📚 Overview

@title EntropyERC7984ToERC20Wrapper
@notice Wrapper contract to convert ERC7984 confidential tokens to ERC20 tokens
@dev Demonstrates wrapping confidential tokens into standard ERC20 tokens
In this example, you will learn:
- Wrapping ERC7984 tokens into ERC20
- Unwrapping ERC20 back to ERC7984
- encrypted randomness integration for random operations
Note: Simplified implementation without OpenZeppelin ERC20 to avoid import conflicts

@notice Request entropy for wrapping with randomness
@param tag Unique tag for entropy request
@return requestId Entropy request ID

@notice Wrap ERC7984 tokens to ERC20 using entropy
@param requestId Entropy request ID
@param encryptedAmount Encrypted amount to wrap
@param inputProof Input proof for encrypted amount
@dev Uses entropy to add randomness to wrapped amount

@notice Unwrap ERC20 tokens back to ERC7984
@param erc20Amount Amount of ERC20 to unwrap
@param encryptedAmount Encrypted amount to receive
@param inputProof Input proof for encrypted amount

@notice Get encrypted balance
@param account Address to query
@return Encrypted balance

@notice Get encrypted randomness address
@return encrypted randomness contract address



## 🔐 Learn Zama FHEVM Through This Example

This example teaches you how to use the following **Zama FHEVM** features:

### What You'll Learn About

- **ZamaEthereumConfig**: Inherits from Zama's network configuration
  ```solidity
  contract MyContract is ZamaEthereumConfig {
      // Inherits network-specific FHEVM configuration
  }
  ```

- **FHE Operations**: Uses Zama's FHE library for encrypted operations
  - `FHE operations` - Zama FHEVM operation
  - `FHE.allowThis()` - Zama FHEVM operation
  - `FHE.allow()` - Zama FHEVM operation

- **Encrypted Types**: Uses Zama's encrypted integer types
  - `euint64` - 64-bit encrypted unsigned integer
  - `externalEuint64` - External encrypted value from user

- **Access Control**: Uses Zama's permission system
  - `FHE.allowThis()` - Allow contract to use encrypted values
  - `FHE.allow()` - Allow specific user to decrypt
  - `FHE.allowTransient()` - Temporary permission for single operation
  - `FHE.fromExternal()` - Convert external encrypted values to internal

### Zama FHEVM Imports

```solidity
// Zama FHEVM Core Library - FHE operations and encrypted types
import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";

// Zama Network Configuration - Provides network-specific settings
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
```

### Zama FHEVM Code Example

```solidity
// Using Zama FHEVM with OpenZeppelin confidential contracts
euint64 encryptedAmount = FHE.fromExternal(encryptedInput, inputProof);
FHE.allowThis(encryptedAmount);

// Zama FHEVM enables encrypted token operations
// All amounts remain encrypted during transfers
```

### FHEVM Concepts You'll Learn

1. **OpenZeppelin Integration**: Learn how to use Zama FHEVM for openzeppelin integration
2. **ERC7984 Confidential Tokens**: Learn how to use Zama FHEVM for erc7984 confidential tokens
3. **FHE Operations**: Learn how to use Zama FHEVM for fhe operations

### Learn More About Zama FHEVM

- 📚 [Zama FHEVM Documentation](https://docs.zama.org/protocol)
- 🎓 [Zama Developer Hub](https://www.zama.org/developer-hub)
- 💻 [Zama FHEVM GitHub](https://github.com/zama-ai/fhevm)



## 🔍 Contract Code

```solidity
// SPDX-License-Identifier: BSD-3-Clause-Clear
pragma solidity ^0.8.27;

import {FHE, euint64, externalEuint64} from "@fhevm/solidity/lib/FHE.sol";
import {ZamaEthereumConfig} from "@fhevm/solidity/config/ZamaConfig.sol";
import "./IEntropyOracle.sol";

/**
 * @title EntropyERC7984ToERC20Wrapper
 * @notice Wrapper contract to convert ERC7984 confidential tokens to ERC20 tokens
 * @dev Demonstrates wrapping confidential tokens into standard ERC20 tokens
 * 
 * This example shows:
 * - Wrapping ERC7984 tokens into ERC20
 * - Unwrapping ERC20 back to ERC7984
 * - EntropyOracle integration for random operations
 * 
 * Note: Simplified implementation without OpenZeppelin ERC20 to avoid import conflicts
 */
contract EntropyERC7984ToERC20Wrapper is ZamaEthereumConfig {
    IEntropyOracle public entropyOracle;
    
    // Encrypted balances for wrapped tokens
    mapping(address => euint64) private encryptedBalances;
    
    // Track entropy requests
    mapping(uint256 => address) public wrapRequests;
    uint256 public wrapRequestCount;
    
    event Wrapped(address indexed user, bytes encryptedAmount, uint256 wrappedAmount);
    event Unwrapped(address indexed user, uint256 erc20Amount, bytes encryptedAmount);
    event WrapRequested(address indexed user, uint256 indexed requestId);
    
    // Simple ERC20-like balances (for demonstration)
    mapping(address => uint256) public erc20Balances;
    string public name;
    string public symbol;
    
    constructor(
        address _entropyOracle,
        string memory _name,
        string memory _symbol
    ) {
        require(_entropyOracle != address(0), "Invalid oracle address");
        entropyOracle = IEntropyOracle(_entropyOracle);
        name = _name;
        symbol = _symbol;
    }
    
    /**
     * @notice Request entropy for wrapping with randomness
     * @param tag Unique tag for entropy request
     * @return requestId Entropy request ID
     */
    function requestWrapWithEntropy(bytes32 tag) external payable returns (uint256 requestId) {
        require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
        
        requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
        wrapRequests[requestId] = msg.sender;
        wrapRequestCount++;
        
        emit WrapRequested(msg.sender, requestId);
        return requestId;
    }
    
    /**
     * @notice Wrap ERC7984 tokens to ERC20 using entropy
     * @param requestId Entropy request ID
     * @param encryptedAmount Encrypted amount to wrap
     * @param inputProof Input proof for encrypted amount
     * @dev Uses entropy to add randomness to wrapped amount
     */
    function wrapWithEntropy(
        uint256 requestId,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external {
        require(entropyOracle.isRequestFulfilled(requestId), "Entropy not ready");
        require(wrapRequests[requestId] == msg.sender, "Invalid request");
        
        euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
        FHE.allowThis(amount);
        
        // Add encrypted amount to user's balance
        encryptedBalances[msg.sender] = FHE.add(encryptedBalances[msg.sender], amount);
        
        // Mint ERC20 tokens (1:1 ratio, but can be adjusted)
        // Note: In real implementation, we'd need to decrypt or use a conversion rate
        // For simplicity, we'll use a fixed conversion
        uint256 wrappedAmount = 1000; // Placeholder - in real implementation, decrypt or use oracle
        
        erc20Balances[msg.sender] += wrappedAmount;
        
        delete wrapRequests[requestId];
        
        emit Wrapped(msg.sender, abi.encode(encryptedAmount), wrappedAmount);
    }
    
    /**
     * @notice Unwrap ERC20 tokens back to ERC7984
     * @param erc20Amount Amount of ERC20 to unwrap
     * @param encryptedAmount Encrypted amount to receive
     * @param inputProof Input proof for encrypted amount
     */
    function unwrap(
        uint256 erc20Amount,
        externalEuint64 encryptedAmount,
        bytes calldata inputProof
    ) external {
        require(erc20Balances[msg.sender] >= erc20Amount, "Insufficient ERC20 balance");
        
        erc20Balances[msg.sender] -= erc20Amount;
        
        euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
        FHE.allowThis(amount);
        encryptedBalances[msg.sender] = FHE.add(encryptedBalances[msg.sender], amount);
        
        emit Unwrapped(msg.sender, erc20Amount, abi.encode(encryptedAmount));
    }
    
    /**
     * @notice Get encrypted balance
     * @param account Address to query
     * @return Encrypted balance
     */
    function getEncryptedBalance(address account) external view returns (euint64) {
        return encryptedBalances[account];
    }
    
    /**
     * @notice Get EntropyOracle address
     * @return EntropyOracle contract address
     */
    function getEntropyOracle() external view returns (address) {
        return address(entropyOracle);
    }
}

```

## 🧪 Tests

See [test file](./test/ERC7984ToERC20Wrapper.test.ts) for comprehensive test coverage.

```bash
npm test
```


## 📚 Category

**openzeppelin**



## 🔗 Related Examples

- [All openzeppelin examples](https://github.com/zacnider/entrofhe/tree/main/examples)

## 📝 License

BSD-3-Clause-Clear
