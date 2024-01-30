// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20, IERC4626 } from "openzeppelin/token/ERC20/extensions/ERC4626.sol";

import { PrizePool } from "pt-v5-prize-pool/PrizePool.sol";

import { PrizeVault } from "./PrizeVault.sol";

/**
 * @title  PoolTogether V5 Prize Vault Factory
 * @author PoolTogether Inc. & G9 Software Inc.
 * @notice Factory contract for deploying new prize vaults using a standard underlying ERC4626 yield vault.
 */
contract PrizeVaultFactory {
    /* ============ Events ============ */

    /**
     * @notice Emitted when a new PrizeVault has been deployed by this factory.
     * @param vault The vault that was deployed
     * @param yieldVault The underlying yield vault
     * @param prizePool The prize pool the vault contributes to
     * @param name The name of the vault token
     * @param symbol The symbol for the vault token
     */
    event NewPrizeVault(
        PrizeVault indexed vault,
        IERC4626 indexed yieldVault,
        PrizePool indexed prizePool,
        string name,
        string symbol
    );

    /* ============ Variables ============ */

    /// @notice List of all vaults deployed by this factory.
    PrizeVault[] public allVaults;

    /// @notice Mapping to verify if a Vault has been deployed via this factory.
    mapping(address vault => bool deployedByFactory) public deployedVaults;

    /// @notice Mapping to store deployer nonces for CREATE2
    mapping(address deployer => uint256 nonce) public deployerNonces;

    /* ============ External Functions ============ */

    /**
     * @notice Deploy a new vault
     * @dev `claimer` can be set to address zero if none is available yet.
     * @param _name Name of the ERC20 share minted by the vault
     * @param _symbol Symbol of the ERC20 share minted by the vault
     * @param _yieldVault Address of the ERC4626 vault in which assets are deposited to generate yield
     * @param _prizePool Address of the PrizePool that computes prizes
     * @param _claimer Address of the claimer
     * @param _yieldFeeRecipient Address of the yield fee recipient
     * @param _yieldFeePercentage Yield fee percentage
     * @param _yieldBuffer Amount of yield to keep as a buffer
     * @param _owner Address that will gain ownership of this contract
     * @return PrizeVault The newly deployed PrizeVault
     */
    function deployVault(
      string memory _name,
      string memory _symbol,
      IERC4626 _yieldVault,
      PrizePool _prizePool,
      address _claimer,
      address _yieldFeeRecipient,
      uint32 _yieldFeePercentage,
      uint256 _yieldBuffer,
      address _owner
    ) external returns (PrizeVault) {
        PrizeVault _vault = new PrizeVault{
            salt: keccak256(abi.encode(msg.sender, deployerNonces[msg.sender]++))
        }(
            _name,
            _symbol,
            _yieldVault,
            _prizePool,
            _claimer,
            _yieldFeeRecipient,
            _yieldFeePercentage,
            _yieldBuffer,
            _owner
        );

        allVaults.push(_vault);
        deployedVaults[address(_vault)] = true;

        emit NewPrizeVault(
            _vault,
            _yieldVault,
            _prizePool,
            _name,
            _symbol
        );

        return _vault;
    }

    /**
     * @notice Total number of vaults deployed by this factory.
     * @return uint256 Number of vaults deployed by this factory.
     */
    function totalVaults() external view returns (uint256) {
        return allVaults.length;
    }
}
