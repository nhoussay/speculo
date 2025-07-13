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

2. 🏛️ settlement Module (Schelling Point Consensus Engine)

This module manages decentralized resolution of prediction markets using a commit-reveal voting game.

✅ Message Types (tx.proto):
	•	MsgCommitVote
Commits a hashed vote on a market outcome:
	•	market_id, creator, commitment (hash of outcome + nonce).
	•	MsgRevealVote
Reveals the actual vote and nonce for validation.
	•	MsgFinalizeOutcome
Finalizes the outcome based on tally of revealed votes, weighted by user reputation. Automatically called after all reveals or deadline expiry.

🔐 Game Flow:
	1.	Commit Phase: Users lock in their outcome vote as a hash.
	2.	Reveal Phase: Users reveal their actual vote and nonce.
	3.	Finalize Phase: System tallies outcome with reputation-weighted scores.

🗃️ State:
	•	Commit: user, market_id, commitment.
	•	Reveal: user, market_id, outcome, nonce.
	•	Settlement: market_id, final_outcome, resolved_at.

⸻

3. 🌟 reputation Module (Truth Incentivization Engine)

This module adjusts users' reputation scores based on their voting alignment with final market outcomes.

✅ Message Types (tx.proto):
	•	MsgAdjustScore (internal; may be triggered via hook during FinalizeOutcome)
	•	Adjusts score for a user in a group, increasing or decreasing based on their voting accuracy.

📈 Logic:
	•	Users who consistently align with the final consensus gain reputation.
	•	Users who vote against the majority or fail to reveal lose reputation.
	•	Higher reputation = more weight in future market resolutions.
	•	Reputation is scoped per group (group_id), enabling isolated trust contexts.

🗃️ State:
	•	ReputationScore: address, group_id, score (int or decimal).

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
