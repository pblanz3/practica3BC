import { ethers } from 'ethers';

export const getEthereumObject = () => {
  const { ethereum } = window;
  if (!ethereum) {
    console.error('MetaMask no está instalado!');
  }
  return ethereum;
};

export const connectWallet = async () => {
  try {
    const ethereum = getEthereumObject();
    if (!ethereum) return;

    // Solicita conexión a MetaMask
    const accounts = await ethereum.request({ method: 'eth_requestAccounts' });
    console.log("Conectado", accounts[0]);
    return accounts[0];
  } catch (error) {
    console.error("Error conectando MetaMask", error);
  }
};

export const getProvider = () => {
  const ethereum = getEthereumObject();
  return new ethers.providers.Web3Provider(ethereum);
};
