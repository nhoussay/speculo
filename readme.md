🧾 Project Summary – Speculo: Decentralized Prediction Market Blockchain

🔷 Overview

Speculo is a custom blockchain built using the Cosmos SDK, designed to host decentralized prediction markets where users can trade probabilistic positions on future outcomes and collectively determine market resolution via a Schelling-point-based settlement process. The platform emphasizes reputation-weighted consensus, modular on-chain governance, and non-custodial participation.

⸻

🎯 **UI Development Guide**

This section provides all the information needed to build user interfaces without accessing blockchain code.

## 📊 Data Structures & API Endpoints

### 🔗 REST API Base URL
```
https://api.specu.io/rest/speculod/
```

### 📋 Core Data Types

#### Prediction Market
```json
{
  "id": "123",
  "question": "Will Bitcoin reach $100k by end of 2024?",
  "outcomes": ["Yes", "No"],
  "groupId": "crypto-predictions",
  "deadline": "1704067200",
  "status": "ACTIVE", // ACTIVE, CLOSED, SETTLED
  "creator": "speculo1abc...",
  "totalVolume": "1000000",
  "participantCount": 150
}
```

#### Order
```json
{
  "id": "456",
  "marketId": "123",
  "outcomeIndex": 0,
  "side": "BUY", // BUY, SELL
  "price": "0.65",
  "quantity": "100",
  "filledQuantity": "50",
  "status": "PARTIAL", // PENDING, PARTIAL, FILLED, CANCELLED
  "creator": "speculo1abc...",
  "timestamp": "1703000000"
}
```

#### Reputation Score
```json
{
  "address": "speculo1abc...",
  "groupId": "crypto-predictions",
  "score": "85",
  "votingAccuracy": "0.78",
  "totalVotes": 45
}
```

#### Settlement Data
```json
{
  "marketId": "123",
  "commitPhase": {
    "startTime": "1704067200",
    "endTime": "1704153600",
    "totalCommits": 120
  },
  "revealPhase": {
    "startTime": "1704153600",
    "endTime": "1704240000",
    "totalReveals": 115,
    "revealRate": "0.958"
  },
  "finalOutcome": {
    "outcomeIndex": 0,
    "outcome": "Yes",
    "reputationWeightedVotes": "85.5",
    "resolvedAt": "1704240000"
  }
}
```

## 🎨 User Interface Flows

### 1. Market Creation Flow
```
1. User clicks "Create Market"
2. Form fields:
   - Question (text input)
   - Outcomes (array of strings, min 2, max 10)
   - Deadline (date picker, min 24h from now)
   - Group selection (dropdown)
3. Preview market details
4. Confirm creation (requires wallet signature)
5. Success: Market appears in active markets list
```

### 2. Trading Flow
```
1. User selects market from list
2. View market details and current prices
3. Choose outcome to trade
4. Select order type:
   - Market Order (immediate execution)
   - Limit Order (set price)
5. Enter quantity
6. Preview order details
7. Confirm trade (wallet signature)
8. Order appears in order book
9. Real-time updates on fills
```

### 3. Settlement Voting Flow
```
1. Market deadline passes
2. System shows "Voting Open" status
3. User clicks "Vote" on settled market
4. Commit Phase:
   - Select outcome
   - System generates nonce
   - User confirms commitment
5. Reveal Phase (after commit deadline):
   - User reveals their vote
   - System validates commitment
6. Finalization:
   - Anyone can trigger finalization
   - Results displayed with reputation weights
```

### 4. Reputation Display
```
1. User profile shows reputation per group
2. Reputation history chart
3. Voting accuracy percentage
4. Recent voting activity
5. Reputation impact from recent settlements
```

## 🔧 API Endpoints for UI

### Prediction Module

#### Get Markets
```
GET /speculod/prediction/v1/markets
Query Parameters:
- status: ACTIVE, CLOSED, SETTLED
- groupId: string
- creator: string
- limit: number (default 100)
- offset: number (default 0)

Response:
{
  "markets": [PredictionMarket],
  "pagination": {
    "nextKey": "string",
    "total": "number"
  }
}
```

#### Get Market Details
```
GET /speculod/prediction/v1/markets/{id}

Response: PredictionMarket
```

#### Get Order Book
```
GET /speculod/prediction/v1/markets/{marketId}/outcomes/{outcomeIndex}/orderbook

Response:
{
  "marketId": "string",
  "outcomeIndex": "number",
  "buyOrders": [Order],
  "sellOrders": [Order],
  "lastPrice": "string",
  "volume24h": "string"
}
```

#### Create Market
```
POST /speculod/prediction/v1/markets
Body: {
  "question": "string",
  "outcomes": ["string"],
  "groupId": "string",
  "deadline": "string"
}
```

#### Post Order
```
POST /speculod/prediction/v1/orders
Body: {
  "marketId": "string",
  "outcomeIndex": "number",
  "side": "BUY|SELL",
  "price": "string",
  "quantity": "string"
}
```

### Settlement Module

#### Get Settlement Status
```
GET /speculod/settlement/v1/markets/{marketId}/status

Response:
{
  "marketId": "string",
  "phase": "COMMIT|REVEAL|FINALIZED",
  "commitPhase": {
    "startTime": "string",
    "endTime": "string",
    "totalCommits": "number"
  },
  "revealPhase": {
    "startTime": "string",
    "endTime": "string",
    "totalReveals": "number"
  },
  "finalOutcome": {
    "outcomeIndex": "number",
    "outcome": "string",
    "reputationWeightedVotes": "string"
  }
}
```

#### Commit Vote
```
POST /speculod/settlement/v1/commits
Body: {
  "marketId": "string",
  "commitment": "string"
}
```

#### Reveal Vote
```
POST /speculod/settlement/v1/reveals
Body: {
  "marketId": "string",
  "outcomeIndex": "number",
  "nonce": "string"
}
```

#### Finalize Outcome
```
POST /speculod/settlement/v1/finalize
Body: {
  "marketId": "string"
}
```

### Reputation Module

#### Get User Reputation
```
GET /speculod/reputation/v1/scores/{address}/groups/{groupId}

Response: ReputationScore
```

#### Get User Reputations (All Groups)
```
GET /speculod/reputation/v1/scores/{address}

Response:
{
  "scores": [ReputationScore]
}
```

## 🎯 UI Components Needed

### 1. Market List Component
- Market cards with question, outcomes, deadline, volume
- Filter by status, group, creator
- Sort by deadline, volume, participant count
- Search functionality

### 2. Market Detail Component
- Full market information
- Order book visualization
- Trading interface
- Market history chart
- Settlement status (if applicable)

### 3. Trading Interface
- Order type selector (Market/Limit)
- Price input with validation
- Quantity input with balance check
- Order preview
- Order history

### 4. Settlement Interface
- Phase indicator (Commit/Reveal/Finalized)
- Voting interface with outcome selection
- Commitment generation
- Reveal interface
- Results display with reputation weights

### 5. User Profile
- Reputation scores by group
- Voting history
- Trading history
- Reputation charts

### 6. Group Management
- Group creation
- Member invitation
- Group reputation leaderboard

## 🔄 Real-time Updates

### WebSocket Events
```
ws://api.specu.io/websocket

Events:
- market.created
- order.posted
- order.filled
- order.cancelled
- vote.committed
- vote.revealed
- outcome.finalized
- reputation.adjusted
```

### Event Payloads
```json
{
  "type": "order.posted",
  "data": {
    "order": Order,
    "marketId": "string",
    "outcomeIndex": "number"
  }
}
```

## 🎨 Design Guidelines

### Color Scheme
- Primary: #6366f1 (Indigo)
- Secondary: #10b981 (Emerald)
- Warning: #f59e0b (Amber)
- Error: #ef4444 (Red)
- Success: #22c55e (Green)

### Typography
- Headers: Inter, sans-serif
- Body: Inter, sans-serif
- Monospace: JetBrains Mono (for addresses, hashes)

### Layout
- Mobile-first responsive design
- Card-based layout for markets
- Sidebar navigation for desktop
- Bottom navigation for mobile

### Icons
- Use Heroicons or similar icon set
- Consistent icon sizing (16px, 20px, 24px)
- Color-coded icons for different states

## 🔐 Wallet Integration

### Supported Wallets
- Keplr (primary)
- Cosmostation
- Leap Wallet
- WalletConnect (future)

### Connection Flow
```
1. User clicks "Connect Wallet"
2. Show supported wallet options
3. User selects wallet
4. Wallet prompts for connection
5. Get user address and balance
6. Display connected state
7. Enable trading features
```

### Transaction Handling
```
1. User initiates action (create market, trade, vote)
2. Show transaction preview
3. Request wallet signature
4. Show pending state
5. Poll for transaction confirmation
6. Show success/error state
7. Update UI accordingly
```

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
