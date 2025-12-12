# StacksLend - P2P Lending on Stacks

[![Stacks](https://img.shields.io/badge/Stacks-Clarity%204-5546FF)](https://www.stacks.co/)
[![License](https://img.shields.io/badge/license-ISC-blue.svg)](LICENSE)

## About The Project

**StacksLend** is a decentralized P2P lending platform built on the Stacks blockchain using Clarity 4. This platform enables trustless peer-to-peer lending secured by Bitcoin through Stacks' Proof of Transfer mechanism, governed by a Decentralized Autonomous Organization (DAO).

### Key Features

- **DAO Governance**: Token holders vote on platform fee changes and membership
- **Trust Token (STT)**: SIP-010 fungible token for platform governance
- **Initial Coin Offering**: Fair token distribution based on STX contributions
- **P2P Lending**: Create and fund lending requests with customizable terms
- **Smart Contract Security**: Built with Clarity 4's enhanced security features

### Clarity 4 Features Used

- **`contract-hash?`**: Verify lending request contracts before interaction
- **`restrict-assets?`**: Safe asset transfers with automatic rollback
- **`stacks-block-time`**: Time-based lending expiration and schedules
- **`to-ascii?`**: Human-readable contract messages

## Project Structure

```
stackslend/
├── contracts/              # Clarity smart contracts
│   ├── trust-token.clar           # SIP-010 token with ICO
│   ├── proposal-management.clar    # DAO governance
│   ├── proposal-factory.clar       # Create proposals
│   ├── member-proposal.clar        # Member voting
│   ├── contract-fee-proposal.clar  # Fee voting
│   ├── request-management.clar     # Lending request registry
│   ├── request-factory.clar        # Create lending requests
│   └── lending-request.clar        # Individual loan logic
├── tests/                  # Clarity unit tests
├── frontend/              # Vue.js frontend (to be migrated)
├── Clarinet.toml          # Clarinet configuration
└── README.md
```

## Getting Started

### Prerequisites

- **Clarinet**: Stacks smart contract development tool

  ```bash
  # Install Clarinet
  curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz -o clarinet.tar.gz
  tar -xzf clarinet.tar.gz
  sudo mv clarinet /usr/local/bin/
  ```

- **Node.js 18+**: For frontend development

  ```bash
  node --version  # Should be 18.x or higher
  ```

- **Hiro Wallet** or **Leather Wallet**: For interacting with the dApp

### Installation & Development

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/stackslend.git
   cd stackslend
   ```

2. **Check contracts**

   ```bash
   clarinet check
   ```

3. **Run tests**

   ```bash
   clarinet test
   ```

4. **Start Clarinet console**

   ```bash
   clarinet console
   ```

5. **Deploy to devnet**
   ```bash
   clarinet integrate
   ```

### Frontend Setup (Coming Soon)

The frontend is currently being migrated from Web3.js to Stacks.js.

```bash
cd frontend
npm install
npm run dev
```

## Smart Contract Overview

### Trust Token (STT)

SIP-010 compliant fungible token with ICO functionality:

- Participate in ICO with STX
- Automatic token distribution when goal reached
- Transfer, approve, and transferFrom functions
- Governance rights for token holders

### Proposal Management

DAO governance system:

- Create contract fee proposals (board members)
- Create member add/remove proposals (token holders)
- Vote on proposals with majority rules
- Automatic execution after vote threshold

### Request Management

P2P lending system:

- Create lending requests with custom terms
- Lend STX to fulfill requests
- Withdraw loans and payback with interest
- Contract fee collection

## Usage Examples

### Participate in ICO

```clarity
(contract-call? .trust-token participate u10000000) ;; 10 STX
```

### Create Lending Request

```clarity
(contract-call? .request-management ask
  u5000000    ;; 5 STX requested
  u6000000    ;; 6 STX payback
  u"Business expansion"
)
```

### Vote on Proposal

```clarity
(contract-call? .proposal-management vote
  true  ;; Vote yes
  'ST1PROPOSAL_CONTRACT
)
```

## Testing

Run the full test suite:

```bash
clarinet test
```

Run specific tests:

```bash
clarinet test tests/trust-token_test.clar
```

## Deployment

### Testnet Deployment

1. Configure your deployment settings in `settings/Testnet.toml`
2. Deploy contracts:
   ```bash
   clarinet deployment generate --testnet
   clarinet deployment apply --testnet
   ```

### Mainnet Deployment

1. Configure `settings/Mainnet.toml`
2. **Audit contracts thoroughly**
3. Deploy:
   ```bash
   clarinet deployment generate --mainnet
   clarinet deployment apply --mainnet
   ```

## Roadmap

- [x] Core smart contracts in Clarity 4
- [ ] Comprehensive test suite
- [ ] Frontend migration to Stacks.js
- [ ] Testnet deployment
- [ ] Security audit
- [ ] Mainnet deployment
- [ ] Mobile app support

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Security

This project is in active development. **Do not use with real funds without a professional security audit.**

To report security issues, please email: security@stackslend.example

## License

This project is licensed under the ISC License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original Ethereum P2P Lending concept by [adorsys](https://github.com/adorsys/p2p-lending)
- Built on [Stacks](https://www.stacks.co/) blockchain
- Powered by [Clarity 4](https://docs.stacks.co/whats-new/clarity-4-is-now-live)

## Contact

Project Link: [https://github.com/yourusername/stackslend](https://github.com/yourusername/stackslend)

---

**Built with ❤️ on Bitcoin via Stacks**
