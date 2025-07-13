🧾 Project Summary – Speculo: Decentralized Prediction Market Blockchain

🔷 Overview

Speculo is a custom blockchain built using the Cosmos SDK, designed to host decentralized prediction markets where users can trade probabilistic positions on future outcomes and collectively determine market resolution via a Schelling-point-based settlement process. The platform emphasizes reputation-weighted consensus, modular on-chain governance, and non-custodial participation.

⸻

📦 Core Modules

1. 🧠 prediction Module (Probabilistic Market Engine)

This module powers the creation and exchange of outcome positions through an automated order book system:

✅ Message Types (tx.proto):
	•	MsgCreateMarket
Creates a new prediction market with:
	•	question: the prediction statement.
	•	outcomes: a list of discrete outcome labels.
	•	deadline: timestamp for trading to close.
	•	group_id: identifier linking to a community group.
	•	MsgPostOrder
Posts a buy or sell order to the order book:
	•	market_id: the prediction market identifier.
	•	outcome_index: which outcome to trade.
	•	side: "BUY" or "SELL" order type.
	•	price: price per share in base tokens.
	•	quantity: number of shares to trade.
	•	creator: the order poster's address.

🧮 Market Logic:
	•	Order Book System: All trades go through a centralized order book per market-outcome pair.
	•	Automatic Matching: New orders are automatically matched against existing opposite-side orders.
	•	Partial Fills: Orders can be partially filled, with remaining quantity staying in the order book.
	•	Price-Time Priority: Orders are matched by price first, then by timestamp.
	•	No central oracle resolves the market. Instead, settlement is crowdsourced via the settlement module.
	•	Token flows and accounting are enforced with Cosmos' BankKeeper.

🗃️ State:
	•	PredictionMarket: ID, question, outcomes, creator, status, deadline.
	•	Order: market_id, outcome_index, side, price, quantity, filled_quantity, status, creator, timestamp.
	•	OrderBook: market_id, outcome_index, buy_orders, sell_orders (maintained by keeper).

🔍 Query Methods:
	•	GetOrder: Retrieve a specific order by ID.
	•	GetOrderBook: Get all orders for a market-outcome pair, separated by side.
	•	ListOrders: List all orders with optional filtering.

⚡ Order Matching Algorithm:
	1. New order is posted to the order book.
	2. System searches for matching opposite-side orders at the same or better price.
	3. Orders are matched in price-time priority order.
	4. Partial fills are processed, updating both orders' filled quantities.
	5. Completely filled orders are removed from the order book.
	6. Partially filled orders remain with updated quantities.

⸻

2. 🏛️ settlement Module (Decentralized Market Resolution Engine)

This module manages the decentralized resolution of prediction markets created in the prediction module, using a commit-reveal voting game with reputation-weighted consensus. It determines the final outcome of each prediction market after its deadline, based on the collective input of participants.

✅ Message Types (tx.proto):
	• MsgCommitVote
	  - Commits a hashed vote on a market outcome:
	    - market_id: the prediction market identifier (must exist in the prediction module)
	    - creator: the voter's address
	    - commitment: hash of (outcome + nonce)
	• MsgRevealVote
	  - Reveals the actual vote and nonce for validation:
	    - market_id, creator, vote, nonce
	• MsgFinalizeOutcome
	  - Finalizes the outcome for a market after the reveal phase or deadline expiry:
	    - market_id, creator
	  - Tallies revealed votes, weighted by user reputation (from the reputation module), and determines the consensus outcome.

🔗 **Cross-Module Integration:**
- The settlement module references and resolves markets created in the prediction module (by market_id).
- It queries the prediction module for market data (outcomes, deadline, group_id) and the reputation module for user reputation scores.
- After finalization, it can trigger reputation adjustments in the reputation module based on voting accuracy.

🔐 Game Flow:
	1. **Commit Phase:**
	   - Users submit a hash of their vote and a secret nonce (commitment) for a specific market.
	   - Commitments are stored on-chain and cannot be changed or revealed until the next phase.
	2. **Reveal Phase:**
	   - After the market deadline, users reveal their vote and nonce.
	   - The system checks that the hash of (vote + nonce) matches the original commitment.
	   - Only valid reveals are counted.
	3. **Finalize Phase:**
	   - Once all reveals are in, or after a timeout, anyone can trigger finalization.
	   - The module tallies all revealed votes, weighting each by the voter's reputation (from the reputation module, scoped to the market's group_id).
	   - The outcome with the highest total reputation-weighted votes is selected as the final outcome.
	   - Reputation scores are adjusted: users who voted with the consensus gain reputation, those who did not lose reputation, and non-revealers may be penalized.

🗃️ State:
	• Commit: user, market_id, commitment (hash)
	• Reveal: user, market_id, outcome, nonce
	• Outcome: market_id, final_outcome, resolved_at

🔍 Query Methods:
	• GetCommit: Retrieve a user's commit for a market
	• GetReveal: Retrieve a user's reveal for a market
	• GetOutcome: Retrieve the final outcome for a market
	• GetSettlementStats: Get stats on commits, reveals, and reveal rate for a market
	• GetReputationWeightedVotes: Get the reputation-weighted vote tally for a market

⚡ **State Transitions & Logic:**
- **Market Expiry:** The settlement module only allows voting on markets whose deadline (from the prediction module) has passed.
- **Validation:** All votes are validated against the set of possible outcomes for the market (from the prediction module).
- **Reputation Integration:** All vote tallies and reputation adjustments use the group_id from the market to scope reputation scores.
- **Finalization:** Once finalized, the outcome is immutable and can be used by the prediction module for payouts/settlement.

🧩 **Summary:**
- The settlement module is the decentralized oracle for prediction markets, using a transparent, on-chain, reputation-weighted commit-reveal process to resolve outcomes after market expiry.
- It is tightly integrated with both the prediction and reputation modules, ensuring trustless, community-driven market resolution and ongoing incentive alignment.

⸻

3. 🌟 reputation Module (Truth Incentivization Engine)

This module adjusts users' reputation scores based on their voting alignment with final market outcomes, creating a robust incentive system for accurate prediction market participation.

✅ Message Types (tx.proto):
	•	MsgAdjustScore
	  - Adjusts score for a user in a group, increasing or decreasing based on their voting accuracy:
	    - address: the user whose reputation is being adjusted
	    - group_id: the group context for the reputation adjustment
	    - adjustment: the amount to adjust (positive or negative integer)
	    - authority: the authorized module or governance making the adjustment
	•	MsgUpdateParams
	  - Updates module parameters (governance operation)

📈 Business Logic:
	•	**Permissioned Access:** Only authorized modules (settlement) or governance can adjust reputation scores
	•	**Group Scoping:** Reputation is isolated per group_id, enabling isolated trust contexts
	•	**Score Validation:** Minimum score enforcement (no negative scores)
	•	**Consensus Alignment:** Users who vote with the final consensus gain reputation (+1)
	•	**Penalty System:** Users who vote against consensus lose reputation (-1)
	•	**Weighted Voting:** Higher reputation = more weight in future market resolutions
	•	**On-Chain Logic:** All reputation adjustments are blockchain-native and transparent

🔧 Keeper Methods:
	•	GetReputationScore(ctx, address, groupId): Retrieves a user's reputation score for a group
	•	SetReputationScore(ctx, address, groupId, score): Stores a reputation score
	•	AdjustReputationScore(ctx, address, groupId, adjustment): Adjusts a score with validation
	•	GetAuthority(): Returns the module's authority for permission checks

🔐 Authorization System:
	•	**Authority Validation:** All reputation adjustments require proper authority verification
	•	**Module Integration:** Settlement module can trigger reputation adjustments during outcome finalization
	•	**Governance Control:** Governance can adjust reputation scores for system maintenance
	•	**Error Handling:** Comprehensive error handling for invalid adjustments and unauthorized access

🗃️ State:
	•	ReputationScore: address, group_id, score (stored as string for precision)
	•	Params: Module parameters for governance control
	•	Schema: Collections-based storage with proper indexing

🔍 Query Methods:
	•	GetReputationScore: Retrieve a user's reputation score for a group
	•	Params: Query module parameters
	•	Genesis: Export/import reputation state

⚡ **Integration Points:**
- **Settlement Module:** Queries reputation scores for vote weighting and triggers adjustments after outcome finalization
- **Prediction Module:** Can use reputation scores for market access control or fee structures
- **Governance:** Can adjust reputation parameters and scores for system maintenance

🧪 **Testing Coverage:**
- **Message Handler Tests:** Authority validation, score adjustment, error handling
- **Keeper Tests:** Score storage, retrieval, and adjustment logic
- **Integration Tests:** Cross-module reputation integration with settlement
- **Edge Cases:** Negative score protection, unauthorized access prevention

🧩 **Summary:**
- The reputation module provides the "Truth Incentivization Engine" for the prediction market ecosystem
- Users who consistently align with consensus gain reputation, creating positive feedback loops
- Users who vote against consensus lose reputation, discouraging manipulation
- Reputation scores are scoped by group, enabling isolated trust contexts for different communities
- All logic is on-chain, transparent, and permissioned for security and trust

⸻

🏗️ Technical Setup

🛠 Initial Setup Commands

cd ~
rm -rf speculod
starport scaffold chain speculod
cd speculod

# Core modules
starport scaffold module prediction
starport scaffold module settlement
starport scaffold module reputation

# State types
starport scaffold type PredictionMarket id:uint question:string outcomes:string groupId:string deadline:int64 status:string creator:string --module prediction
starport scaffold type Position marketId:uint outcomeIndex:uint amount:string user:string --module prediction
starport scaffold type Order marketId:uint outcomeIndex:uint side:string price:string quantity:string filledQuantity:string status:string creator:string --module prediction

starport scaffold type Commit marketId:uint user:string commitment:string --module settlement
starport scaffold type Reveal marketId:uint user:string outcomeIndex:uint nonce:string --module settlement
starport scaffold type Settlement marketId:uint finalOutcomeIndex:uint resolvedAt:int64 --module settlement

starport scaffold type ReputationScore address:string score:string groupId:string --module reputation

# Generate all proto types
starport generate proto-go


⸻

🔐 Design Principles
	•	✅ On-chain logic only: All admin features, market resolution, and updates are blockchain-native.
	•	✅ Email-based group onboarding: Groups are organized via email invites; token allocations occur on sign-up.
	•	✅ No fiat: Entirely token-based economy — no real money or cash equivalents.
	•	✅ Non-custodial wallet by default: Optionally extensible with custodial solutions for Web2 onboarding.
	•	✅ Minimal-tech branding: Project name is Speculo (domain: specu.io); logo is minimalistic and tech-focused.
	•	✅ Public audience: Whitepaper and documentation are intended for a broad, non-technical public audience.

⸻

📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
