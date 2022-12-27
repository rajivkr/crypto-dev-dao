import { ethers } from 'hardhat';
import { CRYPTO_DEVS_NFT_CONTRACT_ADDRESS } from '../constants';

async function main() {
  // Deploying the fake NFT marketplace.
  const fakeNFTMarketPlaceContract = await ethers.getContractFactory(
    'FakeNFTMarketplace'
  );

  const deployedFakeNFTMPContract = await fakeNFTMarketPlaceContract.deploy();

  console.log('Fake NFT Contract Address:', deployedFakeNFTMPContract.address);

  // Address of the Crypto Devs NFT contract that you deployed in the previous module
  const cryptoDevsNFTContract = CRYPTO_DEVS_NFT_CONTRACT_ADDRESS;

  const cryptoDevDaoContract = await ethers.getContractFactory('CryptoDevsDAO');

  const deployedCryptoDevsTokenContract = await cryptoDevDaoContract.deploy(
    deployedFakeNFTMPContract.address,
    cryptoDevsNFTContract,
    {
      value: ethers.utils.parseEther('0.01'),
    }
  );

  console.log(
    'Crypto Devs DAO Contract Address:',
    deployedCryptoDevsTokenContract.address
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
