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
