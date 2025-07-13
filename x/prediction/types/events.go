package types

// Event types for the prediction module
const (
	EventTypeCreateMarket = "create_market"
	EventTypeBuyPosition  = "buy_position"
	EventTypeSellPosition = "sell_position"
)

// Event attribute keys
const (
	AttributeKeyMarketId     = "market_id"
	AttributeKeyCreator      = "creator"
	AttributeKeyBuyer        = "buyer"
	AttributeKeySeller       = "seller"
	AttributeKeyOutcomeIndex = "outcome_index"
	AttributeKeyAmount       = "amount"
	AttributeKeyQuestion     = "question"
	AttributeKeyOutcomes     = "outcomes"
)
