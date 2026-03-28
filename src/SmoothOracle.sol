// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SmoothOracle is EIP712, Ownable {
    using ECDSA for bytes32;

    struct Attestation {
        bool eligible;
        uint256 expiresAt;
    }

    // Whitelisted wallets for testing
    mapping(address => bool) public whitelistedWallets;

    // Attestation cache: wallet => jurisdiction => Attestation
    mapping(address => mapping(string => Attestation)) public attestationCache;

    event WalletWhitelisted(address indexed wallet);
    event WalletRemoved(address indexed wallet);
    event AttestationIssued(address indexed wallet, string jurisdiction, bool eligible, uint256 expiresAt);

    bytes32 private constant ATTESTATION_TYPEHASH =
        keccak256("Attestation(address wallet,string jurisdiction,bool eligible,uint256 issuedAt,uint256 expiresAt)");

    constructor() EIP712("SmoothOracle", "1.0") Ownable(msg.sender) {}

    /**
     * @dev Whitelist a wallet for testing (bypasses compliance check)
     */
    function whitelistWallet(address wallet) external onlyOwner {
        whitelistedWallets[wallet] = true;
        emit WalletWhitelisted(wallet);
    }

    /**
     * @dev Remove wallet from whitelist
     */
    function removeWallet(address wallet) external onlyOwner {
        whitelistedWallets[wallet] = false;
        emit WalletRemoved(wallet);
    }

    /**
     * @dev Check if wallet is eligible (mock oracle implementation)
     * Returns true if wallet is whitelisted, false otherwise
     */
    function isEligible(address wallet, string memory jurisdiction) external returns (bool) {
        // Check cache first
        Attestation storage cached = attestationCache[wallet][jurisdiction];
        if (cached.expiresAt > block.timestamp) {
            return cached.eligible;
        }

        // Perform eligibility check (whitelisted = eligible)
        bool eligible = whitelistedWallets[wallet];

        // Cache result for 24 hours
        uint256 ttl = 24 hours;
        uint256 expiresAt = block.timestamp + ttl;
        attestationCache[wallet][jurisdiction] = Attestation(eligible, expiresAt);

        emit AttestationIssued(wallet, jurisdiction, eligible, expiresAt);

        return eligible;
    }

    /**
     * @dev Generate EIP-712 attestation hash
     */
    function getAttestationHash(
        address wallet,
        string memory jurisdiction,
        bool eligible,
        uint256 issuedAt,
        uint256 expiresAt
    ) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    ATTESTATION_TYPEHASH,
                    wallet,
                    keccak256(abi.encodePacked(jurisdiction)),
                    eligible,
                    issuedAt,
                    expiresAt
                )
            )
        );
    }

    /**
     * @dev Verify an EIP-712 signed attestation
     */
    function verifyAttestation(
        address wallet,
        string memory jurisdiction,
        bool eligible,
        uint256 issuedAt,
        uint256 expiresAt,
        bytes memory signature
    ) public view returns (bool) {
        bytes32 attestationHash = getAttestationHash(wallet, jurisdiction, eligible, issuedAt, expiresAt);
        address signer = attestationHash.recover(signature);
        return signer == owner();
    }
}
