import { expect } from "chai";
import hre from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { EntropyERC7984ToERC20Wrapper } from "../types";

/**
 * @title EntropyERC7984ToERC20Wrapper Tests
 * @notice Comprehensive tests for ERC7984 to ERC20 wrapper with EntropyOracle integration
 * @chapter openzeppelin
 */
describe("EntropyERC7984ToERC20Wrapper", function () {
  async function deployContractsFixture() {
    const [owner, user1, user2] = await hre.ethers.getSigners();
    
    // Check if we're on Sepolia and have real oracle address
    const network = await hre.ethers.provider.getNetwork();
    const isSepolia = network.chainId === BigInt(11155111);
    const realOracleAddress = process.env.ENTROPY_ORACLE_ADDRESS || "0x75b923d7940E1BD6689EbFdbBDCD74C1f6695361";
    
    let oracleAddress: string;
    let oracle: any;
    let chaosEngine: any;
    
    if (isSepolia && realOracleAddress && realOracleAddress !== "0x0000000000000000000000000000000000000000") {
      // Use real deployed EntropyOracle on Sepolia
      console.log(`Using real EntropyOracle on Sepolia: ${realOracleAddress}`);
      oracleAddress = realOracleAddress;
      const OracleFactory = await hre.ethers.getContractFactory("EntropyOracle");
      oracle = OracleFactory.attach(oracleAddress);
    } else {
      // Deploy locally for testing
      console.log("Deploying EntropyOracle locally for testing...");
      
      // Deploy FHEChaosEngine
      const ChaosEngineFactory = await hre.ethers.getContractFactory("FHEChaosEngine");
      chaosEngine = await ChaosEngineFactory.deploy(owner.address);
      await chaosEngine.waitForDeployment();
      const chaosEngineAddress = await chaosEngine.getAddress();
      
      // Initialize master seed for FHEChaosEngine
      const masterSeedInput = hre.fhevm.createEncryptedInput(chaosEngineAddress, owner.address);
      masterSeedInput.add64(12345);
      const encryptedMasterSeed = await masterSeedInput.encrypt();
      await chaosEngine.initializeMasterSeed(encryptedMasterSeed.handles[0], encryptedMasterSeed.inputProof);
      
      // Deploy EntropyOracle
      const OracleFactory = await hre.ethers.getContractFactory("EntropyOracle");
      oracle = await OracleFactory.deploy(chaosEngineAddress, owner.address, owner.address);
      await oracle.waitForDeployment();
      oracleAddress = await oracle.getAddress();
    }
    
    // Deploy EntropyERC7984ToERC20Wrapper
    const ContractFactory = await hre.ethers.getContractFactory("EntropyERC7984ToERC20Wrapper");
    const contract = await ContractFactory.deploy(
      oracleAddress,
      "Wrapped Token",
      "WPT"
    ) as any;
    await contract.waitForDeployment();
    
    const contractAddress = await contract.getAddress();
    await hre.fhevm.assertCoprocessorInitialized(contract, "EntropyERC7984ToERC20Wrapper");
    
    return { contract, owner, user1, user2, contractAddress, oracleAddress, oracle, chaosEngine: chaosEngine || null };
  }

  describe("Deployment", function () {
    it("Should deploy successfully", async function () {
      const { contract } = await loadFixture(deployContractsFixture);
      expect(await contract.getAddress()).to.be.properAddress;
    });

    it("Should have correct name and symbol", async function () {
      const { contract } = await loadFixture(deployContractsFixture);
      expect(await contract.name()).to.equal("Wrapped Token");
      expect(await contract.symbol()).to.equal("WPT");
    });

    it("Should have EntropyOracle address set", async function () {
      const { contract, oracleAddress } = await loadFixture(deployContractsFixture);
      expect(await contract.getEntropyOracle()).to.equal(oracleAddress);
    });
  });

  describe("Wrapping with Entropy", function () {
    it("Should request entropy for wrapping", async function () {
      const { contract, user1, oracle } = await loadFixture(deployContractsFixture);
      
      const tag = hre.ethers.keccak256(hre.ethers.toUtf8Bytes("wrap"));
      const fee = await oracle.getFee();
      
      await expect(
        contract.connect(user1).requestWrapWithEntropy(tag, { value: fee })
      ).to.emit(contract, "WrapRequested");
    });
  });
});
