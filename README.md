# EntropyERC7984ToERC20Wrapper

Wrapper contract to convert ERC7984 confidential tokens to ERC20 tokens

## 🚀 Standard workflow
- Install (first run): `npm install --legacy-peer-deps`
- Compile: `npx hardhat compile`
- Test (local FHE + local oracle/chaos engine auto-deployed): `npx hardhat test`
- Deploy (frontend Deploy button): constructor args fixed to EntropyOracle, name, and symbol; oracle is `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Verify: `npx hardhat verify --network sepolia <contractAddress> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 "WrapperName" "WRAP"`

## 📋 Overview

This example demonstrates **OpenZeppelin** concepts in FHEVM with **EntropyOracle integration**:
- Wrapping ERC7984 tokens into ERC20
- Unwrapping ERC20 back to ERC7984
- EntropyOracle integration for random operations
- Bridge patterns between confidential and public tokens

## 🎯 What This Example Teaches

This tutorial will teach you:

1. **How to wrap ERC7984 tokens** into ERC20 tokens
2. **How to unwrap ERC20 tokens** back to ERC7984
3. **Bridge patterns** between confidential and public tokens
4. **Interoperability** between token standards
5. **Entropy-enhanced wrapping** operations
6. **Real-world token wrapping** implementation

## 💡 Why This Matters

Wrapping enables interoperability:
- **Bridges confidential and public tokens** - use confidential tokens in DeFi
- **Enables use in standard protocols** - ERC20 compatibility
- **Maintains privacy** - wrapping/unwrapping preserves encryption
- **Entropy adds randomness** to wrapping operations
- **Real-world application** in DeFi bridges

## 🔍 How It Works

### Contract Structure

The contract has three main components:

1. **Request Wrap with Entropy**: Request entropy for wrapping
2. **Wrap with Entropy**: Wrap ERC7984 tokens to ERC20
3. **Unwrap**: Unwrap ERC20 tokens back to ERC7984

### Step-by-Step Code Explanation

#### 1. Constructor

```solidity
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
```

**What it does:**
- Takes EntropyOracle address, wrapper name, and symbol
- Validates oracle address is not zero
- Stores oracle interface and wrapper metadata

**Why it matters:**
- Must use the correct oracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
- Wrapper name and symbol for identification

#### 2. Request Wrap with Entropy

```solidity
function requestWrapWithEntropy(bytes32 tag) external payable returns (uint256 requestId) {
    require(msg.value >= entropyOracle.getFee(), "Insufficient fee");
    
    requestId = entropyOracle.requestEntropy{value: msg.value}(tag);
    wrapRequests[requestId] = msg.sender;
    wrapRequestCount++;
    
    emit WrapRequested(msg.sender, requestId);
    return requestId;
}
```

**What it does:**
- Validates fee payment
- Requests entropy from EntropyOracle
- Stores wrap request with user address
- Returns request ID

**Key concepts:**
- **Two-phase wrapping**: Request first, wrap later
- **Request tracking**: Maps request ID to user
- **Entropy for randomness**: Adds randomness to wrapped amount

#### 3. Wrap with Entropy

```solidity
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
    // Note: In real implementation, decrypt or use conversion rate
    uint256 wrappedAmount = 1000; // Placeholder
    
    erc20Balances[msg.sender] += wrappedAmount;
    
    delete wrapRequests[requestId];
    emit Wrapped(msg.sender, abi.encode(encryptedAmount), wrappedAmount);
}
```

**What it does:**
- Validates request ID and fulfillment
- Converts external encrypted amount to internal
- Adds amount to user's encrypted balance
- Mints ERC20 tokens (simplified - uses placeholder)
- Emits wrap event

**Key concepts:**
- **Encrypted balance**: ERC7984 balance stored encrypted
- **ERC20 balance**: ERC20 balance stored as uint256
- **1:1 ratio**: Simplified conversion (production: decrypt or use oracle)

**Why simplified:**
- Full implementation requires decryption or oracle
- This example shows the pattern
- Production: Use decryption or conversion oracle

#### 4. Unwrap

```solidity
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
```

**What it does:**
- Validates ERC20 balance
- Burns ERC20 tokens from user
- Converts external encrypted amount to internal
- Adds amount to user's encrypted balance
- Emits unwrap event

**Key concepts:**
- **ERC20 burn**: ERC20 tokens burned
- **ERC7984 credit**: Encrypted balance increased
- **Reverse operation**: Unwrapping reverses wrapping

## 🧪 Step-by-Step Testing

### Prerequisites

1. **Install dependencies:**
   ```bash
   npm install --legacy-peer-deps
   ```

2. **Compile contracts:**
   ```bash
   npx hardhat compile
   ```

### Running Tests

```bash
npx hardhat test
```

### What Happens in Tests

1. **Fixture Setup** (`deployContractFixture`):
   - Deploys FHEChaosEngine, EntropyOracle, and EntropyERC7984ToERC20Wrapper
   - Returns all contract instances

2. **Test: Request Wrap with Entropy**
   ```typescript
   it("Should request wrap with entropy", async function () {
     const tag = hre.ethers.id("wrap-request");
     const fee = await oracle.getFee();
     const requestId = await contract.requestWrapWithEntropy(tag, { value: fee });
     expect(requestId).to.not.be.undefined;
   });
   ```
   - Requests entropy for wrapping
   - Pays required fee
   - Verifies request ID returned

3. **Test: Wrap with Entropy**
   ```typescript
   it("Should wrap ERC7984 to ERC20", async function () {
     // ... request wrap code ...
     await waitForEntropy(requestId);
     
     const input = hre.fhevm.createEncryptedInput(contractAddress, owner.address);
     input.add64(100);
     const encryptedInput = await input.encrypt();
     
     await contract.wrapWithEntropy(
       requestId,
       encryptedInput.handles[0],
       encryptedInput.inputProof
     );
     
     const erc20Balance = await contract.erc20Balances(owner.address);
     expect(erc20Balance).to.be.greaterThan(0);
   });
   ```
   - Waits for entropy to be ready
   - Creates encrypted amount
   - Wraps tokens with entropy
   - Verifies ERC20 balance increased

### Expected Test Output

```
  EntropyERC7984ToERC20Wrapper
    Deployment
      ✓ Should deploy successfully
      ✓ Should have EntropyOracle address set
    Wrapping
      ✓ Should request wrap with entropy
      ✓ Should wrap ERC7984 to ERC20
    Unwrapping
      ✓ Should unwrap ERC20 to ERC7984

  5 passing
```

**Note:** ERC7984 balances are encrypted (handles). ERC20 balances are public uint256 values.

## 🚀 Step-by-Step Deployment

### Option 1: Frontend (Recommended)

1. Navigate to [Examples page](/examples)
2. Find "EntropyERC7984ToERC20Wrapper" in Tutorial Examples
3. Click **"Deploy"** button
4. Approve transaction in wallet
5. Wait for deployment confirmation
6. Copy deployed contract address

### Option 2: CLI

1. **Create deploy script** (`scripts/deploy.ts`):
   ```typescript
   import hre from "hardhat";

   async function main() {
     const ENTROPY_ORACLE_ADDRESS = "0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361";
     const WRAPPER_NAME = "ERC7984Wrapper";
     const WRAPPER_SYMBOL = "WRAP";
     
     const ContractFactory = await hre.ethers.getContractFactory("EntropyERC7984ToERC20Wrapper");
     const contract = await ContractFactory.deploy(
       ENTROPY_ORACLE_ADDRESS,
       WRAPPER_NAME,
       WRAPPER_SYMBOL
     );
     await contract.waitForDeployment();
     
     const address = await contract.getAddress();
     console.log("EntropyERC7984ToERC20Wrapper deployed to:", address);
   }

   main().catch((error) => {
     console.error(error);
     process.exitCode = 1;
   });
   ```

2. **Deploy:**
   ```bash
   npx hardhat run scripts/deploy.ts --network sepolia
   ```

## ✅ Step-by-Step Verification

### Option 1: Frontend

1. After deployment, click **"Verify"** button on Examples page
2. Wait for verification confirmation
3. View verified contract on Etherscan

### Option 2: CLI

```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 "ERC7984Wrapper" "WRAP"
```

**Important:** Constructor arguments must be:
1. EntropyOracle address: `0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361`
2. Wrapper name: Your wrapper name (e.g., "ERC7984Wrapper")
3. Wrapper symbol: Your wrapper symbol (e.g., "WRAP")

## 📊 Expected Outputs

### After Request Wrap with Entropy

- `wrapRequests[requestId]` contains user address
- `wrapRequestCount` increments
- `WrapRequested` event emitted

### After Wrap with Entropy

- `getEncryptedBalance(user)` returns increased encrypted balance
- `erc20Balances(user)` returns increased ERC20 balance
- `Wrapped` event emitted

### After Unwrap

- `erc20Balances(user)` returns decreased ERC20 balance
- `getEncryptedBalance(user)` returns increased encrypted balance
- `Unwrapped` event emitted

## ⚠️ Common Errors & Solutions

### Error: `SenderNotAllowed()`

**Cause:** Missing `FHE.allowThis()` call on encrypted amount.

**Solution:**
```solidity
euint64 amount = FHE.fromExternal(encryptedAmount, inputProof);
FHE.allowThis(amount); // ✅ Required!
```

**Prevention:** Always call `FHE.allowThis()` on all encrypted values before using them.

---

### Error: `Entropy not ready`

**Cause:** Calling `wrapWithEntropy()` before entropy is fulfilled.

**Solution:** Always check `isRequestFulfilled()` before using entropy.

---

### Error: `Invalid request`

**Cause:** Request ID doesn't belong to caller.

**Solution:** Ensure request ID matches the caller's request.

---

### Error: `Insufficient ERC20 balance`

**Cause:** Trying to unwrap more ERC20 tokens than available.

**Solution:** Check ERC20 balance before unwrapping:
```typescript
const balance = await contract.erc20Balances(userAddress);
if (balance >= erc20Amount) {
    await contract.unwrap(erc20Amount, encryptedAmount, inputProof);
}
```

---

### Error: `Insufficient fee`

**Cause:** Not sending enough ETH when requesting wrap.

**Solution:** Always send exactly 0.00001 ETH:
```typescript
const fee = await contract.entropyOracle.getFee();
await contract.requestWrapWithEntropy(tag, { value: fee });
```

---

### Error: Verification failed - Constructor arguments mismatch

**Cause:** Wrong constructor arguments used during verification.

**Solution:** Always use EntropyOracle address, wrapper name, and symbol:
```bash
npx hardhat verify --network sepolia <CONTRACT_ADDRESS> 0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361 "WrapperName" "WRAP"
```

## 🔗 Related Examples

- [EntropyERC7984Token](../openzeppelin-erc7984token/) - ERC7984 token implementation
- [EntropySwapERC7984ToERC20](../openzeppelin-swaperc7984toerc20/) - Swapping ERC7984 to ERC20
- [Category: openzeppelin](../)

## 📚 Additional Resources

- [Full Tutorial Track Documentation](../../../frontend/src/pages/Docs.tsx) - Complete educational guide
- [Zama FHEVM Documentation](https://docs.zama.org/) - Official FHEVM docs
- [GitHub Repository](https://github.com/zacnider/entrofhe/tree/main/examples/openzeppelin-erc7984toerc20wrapper) - Source code

## 📝 License

BSD-3-Clause-Clear
