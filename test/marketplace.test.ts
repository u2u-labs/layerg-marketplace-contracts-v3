// import { expect } from 'chai';
// import { ethers } from 'hardhat';
// import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
// import { 
//   Marketplace, 
//   AssetTransferAgent,
//   MockERC20,
//   MockERC721,
//   MockERC1155
// } from '../typechain-types';
// import { 
//   AssetType,
//   Asset,
//   Order,
//   OrderType,
//   createOrder,
//   signOrder,
//   generateMerkleProof,
//   generateMerkleRoot
// } from './helpers/orderHelpers';

// describe('Marketplace', () => {
//   let marketplace: Marketplace;
//   let assetTransferAgent: AssetTransferAgent;
//   let mockERC20: MockERC20;
//   let mockERC721: MockERC721;
//   let mockERC1155: MockERC1155;
//   let owner: SignerWithAddress;
//   let maker: SignerWithAddress;
//   let taker: SignerWithAddress;
//   let feeRecipient: SignerWithAddress;
//   let accounts: SignerWithAddress[];
  
//   const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
//   const feeBps = 250; // 2.5%
  
//   before(async () => {
//     accounts = await ethers.getSigners();
//     [owner, maker, taker, feeRecipient] = accounts;
//   });
  
//   beforeEach(async () => {
//     // Deploy mock tokens
//     const MockERC20Factory = await ethers.getContractFactory('MockERC20');
//     mockERC20 = await MockERC20Factory.deploy('TestToken', 'TT', 18);
//     await mockERC20.deployed();
    
//     const MockERC721Factory = await ethers.getContractFactory('MockERC721');
//     mockERC721 = await MockERC721Factory.deploy('TestNFT', 'TNFT');
//     await mockERC721.deployed();
    
//     const MockERC1155Factory = await ethers.getContractFactory('MockERC1155');
//     mockERC1155 = await MockERC1155Factory.deploy('https://test.uri/{id}');
//     await mockERC1155.deployed();
    
//     // Deploy asset transfer agent
//     const AssetTransferAgentFactory = await ethers.getContractFactory('AssetTransferAgent');
//     assetTransferAgent = await AssetTransferAgentFactory.deploy();
//     await assetTransferAgent.deployed();
    
//     // Deploy marketplace
//     const MarketplaceFactory = await ethers.getContractFactory('Marketplace');
//     marketplace = await MarketplaceFactory.deploy();
//     await marketplace.deployed();
    
//     // Setup contracts
//     await marketplace.setAssetTransferAgent(assetTransferAgent.address);
//     await marketplace.setFeeRecipient(feeRecipient.address);
//     await marketplace.setFeeBps(feeBps);
//     await assetTransferAgent.setMarketplace(marketplace.address);
    
//     // Mint some tokens for testing
//     await mockERC20.mint(maker.address, ethers.utils.parseEther('1000'));
//     await mockERC20.mint(taker.address, ethers.utils.parseEther('1000'));
    
//     await mockERC721.mint(maker.address, 1);
//     await mockERC721.mint(taker.address, 2);
    
//     await mockERC1155.mint(maker.address, 1, 100, '0x');
//     await mockERC1155.mint(taker.address, 2, 100, '0x');
    
//     // Approve marketplace (via asset transfer agent)
//     await mockERC20.connect(maker).approve(assetTransferAgent.address, ethers.constants.MaxUint256);
//     await mockERC20.connect(taker).approve(assetTransferAgent.address, ethers.constants.MaxUint256);
    
//     await mockERC721.connect(maker).setApprovalForAll(assetTransferAgent.address, true);
//     await mockERC721.connect(taker).setApprovalForAll(assetTransferAgent.address, true);
    
//     await mockERC1155.connect(maker).setApprovalForAll(assetTransferAgent.address, true);
//     await mockERC1155.connect(taker).setApprovalForAll(assetTransferAgent.address, true);
//   });
  
//   describe('Contract initialization', () => {
//     it('should correctly set owner', async () => {
//       expect(await marketplace.owner()).to.equal(owner.address);
//     });
    
//     it('should correctly set fee recipient', async () => {
//       expect(await marketplace.feeRecipient()).to.equal(feeRecipient.address);
//     });
    
//     it('should correctly set fee BPS', async () => {
//       expect(await marketplace.feeBps()).to.equal(feeBps);
//     });
    
//     it('should correctly set asset transfer agent', async () => {
//       expect(await marketplace.assetTransferAgent()).to.equal(assetTransferAgent.address);
//     });
//   });
  
//   describe('Admin functions', () => {
//     it('should allow owner to update fee recipient', async () => {
//       await marketplace.setFeeRecipient(accounts[5].address);
//       expect(await marketplace.feeRecipient()).to.equal(accounts[5].address);
//     });
    
//     it('should not allow non-owner to update fee recipient', async () => {
//       await expect(
//         marketplace.connect(accounts[5]).setFeeRecipient(accounts[6].address)
//       ).to.be.revertedWith('Ownable: caller is not the owner');
//     });
    
//     it('should allow owner to update fee BPS', async () => {
//       await marketplace.setFeeBps(300);
//       expect(await marketplace.feeBps()).to.equal(300);
//     });
    
//     it('should not allow fee BPS above 10000', async () => {
//       await expect(marketplace.setFeeBps(10001)).to.be.revertedWith('Fee exceeds 100%');
//     });
    
//     it('should allow owner to update asset transfer agent', async () => {
//       await marketplace.setAssetTransferAgent(accounts[5].address);
//       expect(await marketplace.assetTransferAgent()).to.equal(accounts[5].address);
//     });
//   });
  
//   describe('Order cancellation', () => {
//     it('should allow maker to cancel their order', async () => {
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: 1,
//         assetAmount: 1
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('10')
//       };
      
//       const order = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS,
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.ASK,
//         salt: 1,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedOrder = await signOrder(order, maker);
      
//       await marketplace.connect(maker).cancelOrder(signedOrder);
      
//       expect(await marketplace.isOrderCancelled(signedOrder)).to.be.true;
//     });
    
//     it('should not allow non-maker to cancel an order', async () => {
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: 1,
//         assetAmount: 1
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('10')
//       };
      
//       const order = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS,
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.ASK,
//         salt: 1,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedOrder = await signOrder(order, maker);
      
//       await expect(
//         marketplace.connect(taker).cancelOrder(signedOrder)
//       ).to.be.revertedWith('Only maker can cancel order');
//     });
//   });
  
//   describe('ERC20 - NFT order matching', () => {
//     it('should match a valid NFT listing order', async () => {
//       // Scenario: maker sells NFT for ERC20
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: 1,
//         assetAmount: 1
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('10')
//       };
      
//       // Maker creates sell order (ASK)
//       const makerOrder = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS, // Open to any taker
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.ASK,
//         salt: 1,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedMakerOrder = await signOrder(makerOrder, maker);
      
//       // Taker creates buy order (BID)
//       const takerOrder = await createOrder({
//         maker: taker.address,
//         taker: maker.address,
//         makeAsset: takeAsset,
//         takeAsset: makeAsset,
//         orderType: OrderType.BID,
//         salt: 2,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedTakerOrder = await signOrder(takerOrder, taker);

//       // Balance before
//       const makerERC20BalanceBefore = await mockERC20.balanceOf(maker.address);
//       const takerERC20BalanceBefore = await mockERC20.balanceOf(taker.address);
//       const makerNFTOwnerBefore = await mockERC721.ownerOf(1);
//       const feeRecipientBalanceBefore = await mockERC20.balanceOf(feeRecipient.address);
      
//       expect(makerNFTOwnerBefore).to.equal(maker.address);
      
//       // Match orders
//       await marketplace.connect(taker).matchOrders(signedMakerOrder, signedTakerOrder);
      
//       // Check balances after
//       const makerERC20BalanceAfter = await mockERC20.balanceOf(maker.address);
//       const takerERC20BalanceAfter = await mockERC20.balanceOf(taker.address);
//       const feeRecipientBalanceAfter = await mockERC20.balanceOf(feeRecipient.address);
//       const takerNFTOwnerAfter = await mockERC721.ownerOf(1);
      
//       // Check NFT transfer
//       expect(takerNFTOwnerAfter).to.equal(taker.address);
      
//       // Check ERC20 transfers with fee calculations
//       const expectedFee = takeAsset.assetAmount.mul(feeBps).div(10000);
//       const expectedMakerReceive = takeAsset.assetAmount.sub(expectedFee);
      
//       expect(makerERC20BalanceAfter.sub(makerERC20BalanceBefore)).to.equal(expectedMakerReceive);
//       expect(takerERC20BalanceBefore.sub(takerERC20BalanceAfter)).to.equal(takeAsset.assetAmount);
//       expect(feeRecipientBalanceAfter.sub(feeRecipientBalanceBefore)).to.equal(expectedFee);
//     });
    
//     it('should match a valid NFT bid order', async () => {
//       // Scenario: maker makes a bid on an NFT with ERC20
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('10')
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: 2,
//         assetAmount: 1
//       };
      
//       // Maker creates bid order
//       const bidOrder = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS, // Open for any taker
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.BID,
//         salt: 3,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedBidOrder = await signOrder(bidOrder, maker);
      
//       // Balance before
//       const makerERC20BalanceBefore = await mockERC20.balanceOf(maker.address);
//       const takerERC20BalanceBefore = await mockERC20.balanceOf(taker.address);
//       const takerNFTOwnerBefore = await mockERC721.ownerOf(2);
//       const feeRecipientBalanceBefore = await mockERC20.balanceOf(feeRecipient.address);
      
//       expect(takerNFTOwnerBefore).to.equal(taker.address);
      
//       // Accept bid
//       await marketplace.connect(taker).acceptBid(signedBidOrder, makeAsset.assetAmount);
      
//       // Check balances after
//       const makerERC20BalanceAfter = await mockERC20.balanceOf(maker.address);
//       const takerERC20BalanceAfter = await mockERC20.balanceOf(taker.address);
//       const feeRecipientBalanceAfter = await mockERC20.balanceOf(feeRecipient.address);
//       const makerNFTOwnerAfter = await mockERC721.ownerOf(2);
      
//       // Check NFT transfer
//       expect(makerNFTOwnerAfter).to.equal(maker.address);
      
//       // Check ERC20 transfers with fee calculations
//       const expectedFee = makeAsset.assetAmount.mul(feeBps).div(10000);
//       const expectedTakerReceive = makeAsset.assetAmount.sub(expectedFee);
      
//       expect(makerERC20BalanceBefore.sub(makerERC20BalanceAfter)).to.equal(makeAsset.assetAmount);
//       expect(takerERC20BalanceAfter.sub(takerERC20BalanceBefore)).to.equal(expectedTakerReceive);
//       expect(feeRecipientBalanceAfter.sub(feeRecipientBalanceBefore)).to.equal(expectedFee);
//     });
//   });
  
//   describe('ERC1155 trading', () => {
//     it('should match a valid ERC1155 sale', async () => {
//       const tokenAmount = 50;
      
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC1155,
//         contractAddress: mockERC1155.address,
//         assetId: 1,
//         assetAmount: tokenAmount
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('5')
//       };
      
//       // Maker creates sell order (ASK)
//       const makerOrder = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS,
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.ASK,
//         salt: 4,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedMakerOrder = await signOrder(makerOrder, maker);
      
//       // Taker creates buy order (BID)
//       const takerOrder = await createOrder({
//         maker: taker.address,
//         taker: maker.address,
//         makeAsset: takeAsset,
//         takeAsset: makeAsset,
//         orderType: OrderType.BID,
//         salt: 5,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedTakerOrder = await signOrder(takerOrder, taker);
      
//       // Balance before
//       const makerERC20BalanceBefore = await mockERC20.balanceOf(maker.address);
//       const takerERC20BalanceBefore = await mockERC20.balanceOf(taker.address);
//       const makerERC1155BalanceBefore = await mockERC1155.balanceOf(maker.address, 1);
//       const takerERC1155BalanceBefore = await mockERC1155.balanceOf(taker.address, 1);
//       const feeRecipientBalanceBefore = await mockERC20.balanceOf(feeRecipient.address);
      
//       // Match orders
//       await marketplace.connect(taker).matchOrders(signedMakerOrder, signedTakerOrder);
      
//       // Check balances after
//       const makerERC20BalanceAfter = await mockERC20.balanceOf(maker.address);
//       const takerERC20BalanceAfter = await mockERC20.balanceOf(taker.address);
//       const makerERC1155BalanceAfter = await mockERC1155.balanceOf(maker.address, 1);
//       const takerERC1155BalanceAfter = await mockERC1155.balanceOf(taker.address, 1);
//       const feeRecipientBalanceAfter = await mockERC20.balanceOf(feeRecipient.address);
      
//       // Check ERC1155 transfer
//       expect(makerERC1155BalanceBefore.sub(makerERC1155BalanceAfter)).to.equal(tokenAmount);
//       expect(takerERC1155BalanceAfter.sub(takerERC1155BalanceBefore)).to.equal(tokenAmount);
      
//       // Check ERC20 transfers with fee calculations
//       const expectedFee = takeAsset.assetAmount.mul(feeBps).div(10000);
//       const expectedMakerReceive = takeAsset.assetAmount.sub(expectedFee);
      
//       expect(makerERC20BalanceAfter.sub(makerERC20BalanceBefore)).to.equal(expectedMakerReceive);
//       expect(takerERC20BalanceBefore.sub(takerERC20BalanceAfter)).to.equal(takeAsset.assetAmount);
//       expect(feeRecipientBalanceAfter.sub(feeRecipientBalanceBefore)).to.equal(expectedFee);
//     });
//   });
  
//   describe('Merkle-based orders', () => {
//     it('should match a merkle-verified order', async () => {
//       // Create allowlist with merkle tree
//       const allowedAddresses = [taker.address, accounts[5].address, accounts[6].address];
//       const tokenId = 1;
      
//       // Generate merkle data for allowlist
//       const merkleLeaves = allowedAddresses.map(address => 
//         ethers.utils.solidityKeccak256(['address', 'uint256'], [address, tokenId])
//       );
      
//       const merkleRoot = generateMerkleRoot(merkleLeaves);
//       const merkleProof = generateMerkleProof(
//         merkleLeaves,
//         merkleLeaves[0] // Proof for taker
//       );
      
//       // Create maker order with merkle root
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: tokenId,
//         assetAmount: 1
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('10')
//       };
      
//       const makerOrder = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS, // Open for allowlisted addresses
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.ASK,
//         salt: 6,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot,
//         merkleProof: []
//       });
      
//       const signedMakerOrder = await signOrder(makerOrder, maker);
      
//       // Taker creates buy order with merkle proof
//       const takerOrder = await createOrder({
//         maker: taker.address,
//         taker: maker.address,
//         makeAsset: takeAsset,
//         takeAsset: makeAsset,
//         orderType: OrderType.BID,
//         salt: 7,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof
//       });
      
//       const signedTakerOrder = await signOrder(takerOrder, taker);
      
//       // Match orders
//       await marketplace.connect(taker).matchOrders(signedMakerOrder, signedTakerOrder);
      
//       // Verify NFT was transferred
//       expect(await mockERC721.ownerOf(tokenId)).to.equal(taker.address);
//     });
    
//     it('should reject order with invalid merkle proof', async () => {
//       // Create allowlist with merkle tree
//       const allowedAddresses = [accounts[5].address, accounts[6].address, accounts[7].address];
//       const tokenId = 1;
      
//       // Generate merkle data for allowlist (taker not included)
//       const merkleLeaves = allowedAddresses.map(address => 
//         ethers.utils.solidityKeccak256(['address', 'uint256'], [address, tokenId])
//       );
      
//       const merkleRoot = generateMerkleRoot(merkleLeaves);
      
//       // Create a fake proof
//       const fakeProof = [ethers.utils.randomBytes(32), ethers.utils.randomBytes(32)];
      
//       // Create maker order with merkle root
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: tokenId,
//         assetAmount: 1
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('10')
//       };
      
//       const makerOrder = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS,
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.ASK,
//         salt: 8,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot,
//         merkleProof: []
//       });
      
//       const signedMakerOrder = await signOrder(makerOrder, maker);
      
//       // Taker creates buy order with invalid merkle proof
//       const takerOrder = await createOrder({
//         maker: taker.address,
//         taker: maker.address,
//         makeAsset: takeAsset,
//         takeAsset: makeAsset,
//         orderType: OrderType.BID,
//         salt: 9,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: fakeProof.map(p => ethers.utils.hexlify(p))
//       });
      
//       const signedTakerOrder = await signOrder(takerOrder, taker);
      
//       // Attempt to match orders should fail
//       await expect(
//         marketplace.connect(taker).matchOrders(signedMakerOrder, signedTakerOrder)
//       ).to.be.revertedWith('Invalid Merkle proof');
//     });
//   });
  
//   describe('Order validation', () => {
//     it('should reject expired orders', async () => {
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: 1,
//         assetAmount: 1
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('10')
//       };
      
//       // Create expired maker order
//       const makerOrder = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS,
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.ASK,
//         salt: 10,
//         start: Math.floor(Date.now() / 1000) - 7200, // 2 hours ago
//         end: Math.floor(Date.now() / 1000) - 3600, // 1 hour ago (expired)
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedMakerOrder = await signOrder(makerOrder, maker);
      
//       // Create valid taker order
//       const takerOrder = await createOrder({
//         maker: taker.address,
//         taker: maker.address,
//         makeAsset: takeAsset,
//         takeAsset: makeAsset,
//         orderType: OrderType.BID,
//         salt: 11,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedTakerOrder = await signOrder(takerOrder, taker);
      
//       // Attempt to match orders should fail
//       await expect(
//         marketplace.connect(taker).matchOrders(signedMakerOrder, signedTakerOrder)
//       ).to.be.revertedWith('Maker order expired');
//     });
    
//     it('should reject orders with invalid signature', async () => {
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: 1,
//         assetAmount: 1
//       };
      
//       const takeAsset: Asset = {
//         assetType: AssetType.ERC20,
//         contractAddress: mockERC20.address,
//         assetId: 0,
//         assetAmount: ethers.utils.parseEther('10')
//       };
      
//       // Create maker order
//       const makerOrder = await createOrder({
//         maker: maker.address,
//         taker: ZERO_ADDRESS,
//         makeAsset,
//         takeAsset,
//         orderType: OrderType.ASK,
//         salt: 12,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       // Sign with wrong signer
//       const invalidSignedMakerOrder = await signOrder(makerOrder, taker); // Signed by taker instead of maker
      
//       // Create valid taker order
//       const takerOrder = await createOrder({
//         maker: taker.address,
//         taker: maker.address,
//         makeAsset: takeAsset,
//         takeAsset: makeAsset,
//         orderType: OrderType.BID,
//         salt: 13,
//         start: Math.floor(Date.now() / 1000),
//         end: Math.floor(Date.now() / 1000) + 3600,
//         signature: '0x',
//         merkleRoot: ethers.constants.HashZero,
//         merkleProof: []
//       });
      
//       const signedTakerOrder = await signOrder(takerOrder, taker);
      
//       // Attempt to match orders should fail
//       await expect(
//         marketplace.connect(taker).matchOrders(invalidSignedMakerOrder, signedTakerOrder)
//       ).to.be.revertedWith('Invalid signature');
//     });
    
//     it('should reject orders with asset type mismatch', async () => {
//       const makeAsset: Asset = {
//         assetType: AssetType.ERC721,
//         contractAddress: mockERC721.address,
//         assetId: 1,
//         as