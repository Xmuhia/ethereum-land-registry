const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleLandRegistry", function () {
  let landRegistry;
  let owner, user1, user2, verifier;
  
  const location = "123 Main St, Anytown, Country";
  const surveyData = "ipfs://QmSurveyDataHash";
  const documentURI = "ipfs://QmDocumentHash";

  beforeEach(async function () {
    // Get signers
    [owner, user1, user2, verifier] = await ethers.getSigners();
    
    // Deploy contract
    const SimpleLandRegistry = await ethers.getContractFactory("SimpleLandRegistry");
    landRegistry = await SimpleLandRegistry.deploy();
    await landRegistry.deployed();
    
    // Add verifier
    await landRegistry.addVerifier(verifier.address);
  });

  it("Should register new land", async function () {
    await expect(
      landRegistry.connect(user1).registerLand(location, surveyData, documentURI)
    ).to.emit(landRegistry, "LandRegistered");
    
    // Token ID should be 1 (first token)
    expect(await landRegistry.ownerOf(1)).to.equal(user1.address);
    
    const landDetails = await landRegistry.getLandDetails(1);
    expect(landDetails.location).to.equal(location);
    expect(landDetails.verified).to.equal(false);
  });

  it("Should verify land", async function () {
    // Register land
    await landRegistry.connect(user1).registerLand(location, surveyData, documentURI);
    
    // Verify the land
    await expect(
      landRegistry.connect(verifier).verifyLand(1)
    ).to.emit(landRegistry, "LandVerified").withArgs(1);
    
    const landDetails = await landRegistry.getLandDetails(1);
    expect(landDetails.verified).to.equal(true);
  });

  it("Should transfer land and update mappings", async function () {
    // Register land
    await landRegistry.connect(user1).registerLand(location, surveyData, documentURI);
    
    // Transfer the land
    await landRegistry.connect(user1).transferLand(user2.address, 1);
    
    // Check ownership
    expect(await landRegistry.ownerOf(1)).to.equal(user2.address);
    
    // Check mappings
    const user1Lands = await landRegistry.getLandsByOwner(user1.address);
    expect(user1Lands.length).to.equal(0);
    
    const user2Lands = await landRegistry.getLandsByOwner(user2.address);
    expect(user2Lands.length).to.equal(1);
    expect(user2Lands[0]).to.equal(1);
  });

  it("Should add documents to land", async function () {
    // Register land
    await landRegistry.connect(user1).registerLand(location, surveyData, documentURI);
    
    // Add another document
    const newDocURI = "ipfs://QmNewDocumentHash";
    await landRegistry.connect(user1).addDocument(1, newDocURI);
    
    // Get documents
    const docs = await landRegistry.getLandDocuments(1);
    expect(docs.length).to.equal(2);
    expect(docs[0]).to.equal(documentURI);
    expect(docs[1]).to.equal(newDocURI);
  });
});