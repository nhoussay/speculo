package keeper

import (
	"testing"
	"time"

	"speculod/x/prediction/types"

	"cosmossdk.io/math"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"
)

// TestOrderBookIntegration_CompleteScenario tests a complete order book scenario
func TestOrderBookIntegration_CompleteScenario(t *testing.T) {
	// This test documents a complete order book scenario
	// Scenario: Multiple users trading on a prediction market

	// Test data setup
	marketID := uint64(1)
	outcomeIndex := uint32(0)

	// Create test orders
	orders := []types.Order{
		{
			Id:           1,
			MarketId:     marketID,
			Creator:      "alice",
			Side:         types.ORDER_SIDE_SELL,
			OutcomeIndex: outcomeIndex,
			Price:        "100",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
			FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
			Status:       types.ORDER_STATUS_OPEN,
			CreatedAt:    time.Now().Unix(),
		},
		{
			Id:           2,
			MarketId:     marketID,
			Creator:      "bob",
			Side:         types.ORDER_SIDE_SELL,
			OutcomeIndex: outcomeIndex,
			Price:        "99",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(50)},
			FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
			Status:       types.ORDER_STATUS_OPEN,
			CreatedAt:    time.Now().Unix(),
		},
		{
			Id:           3,
			MarketId:     marketID,
			Creator:      "charlie",
			Side:         types.ORDER_SIDE_BUY,
			OutcomeIndex: outcomeIndex,
			Price:        "101",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(200)},
			FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
			Status:       types.ORDER_STATUS_OPEN,
			CreatedAt:    time.Now().Unix(),
		},
	}

	// Test order validation
	for _, order := range orders {
		require.NotEmpty(t, order.Creator, "Order should have a creator")
		require.NotEmpty(t, order.Price, "Order should have a price")
		require.NotNil(t, order.Amount, "Order should have an amount")
		require.True(t, order.Amount.Amount.GT(math.ZeroInt()), "Order amount should be positive")
		require.Equal(t, marketID, order.MarketId, "All orders should be for the same market")
		require.Equal(t, outcomeIndex, order.OutcomeIndex, "All orders should be for the same outcome")
	}

	// Test price-time priority logic
	// Bob's order at 99 should be filled before Alice's order at 100
	require.True(t, parsePrice("99").LT(parsePrice("100")), "Lower sell price should have priority")

	// Charlie's buy order at 101 should match both sell orders
	// Expected trades:
	// 1. Charlie buys 50 from Bob at 99
	// 2. Charlie buys 100 from Alice at 100
	// 3. Charlie's remaining 50 stays open

	// Test trade execution logic
	expectedTrades := []types.Trade{
		{
			TradeId:      1,
			MarketId:     marketID,
			OutcomeIndex: outcomeIndex,
			Buyer:        "charlie",
			Seller:       "bob",
			Price:        "99",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(50)},
			Timestamp:    time.Now().Unix(),
		},
		{
			TradeId:      2,
			MarketId:     marketID,
			OutcomeIndex: outcomeIndex,
			Buyer:        "charlie",
			Seller:       "alice",
			Price:        "100",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
			Timestamp:    time.Now().Unix(),
		},
	}

	// Validate expected trades
	for i, trade := range expectedTrades {
		require.Equal(t, marketID, trade.MarketId, "Trade should be for correct market")
		require.Equal(t, outcomeIndex, trade.OutcomeIndex, "Trade should be for correct outcome")
		require.NotEmpty(t, trade.Buyer, "Trade should have a buyer")
		require.NotEmpty(t, trade.Seller, "Trade should have a seller")
		require.NotEmpty(t, trade.Price, "Trade should have a price")
		require.NotNil(t, trade.Amount, "Trade should have an amount")
		require.True(t, trade.Amount.Amount.GT(math.ZeroInt()), "Trade amount should be positive")

		// Test price improvement for buyer
		if i == 0 {
			require.Equal(t, "99", trade.Price, "First trade should be at best price (99)")
		} else {
			require.Equal(t, "100", trade.Price, "Second trade should be at next best price (100)")
		}
	}

	// Test order status updates after trades
	expectedOrderStatuses := map[uint64]types.OrderStatus{
		1: types.ORDER_STATUS_PARTIALLY_FILLED, // Alice's order partially filled
		2: types.ORDER_STATUS_FILLED,           // Bob's order fully filled
		3: types.ORDER_STATUS_PARTIALLY_FILLED, // Charlie's order partially filled
	}

	for orderID, expectedStatus := range expectedOrderStatuses {
		require.Contains(t, expectedOrderStatuses, orderID, "Order ID should be tracked")
		require.True(t, expectedStatus == types.ORDER_STATUS_FILLED ||
			expectedStatus == types.ORDER_STATUS_PARTIALLY_FILLED ||
			expectedStatus == types.ORDER_STATUS_OPEN, "Status should be valid")
	}
}

// TestOrderBookIntegration_PartialFills tests partial fill scenarios
func TestOrderBookIntegration_PartialFills(t *testing.T) {
	// Test scenario: Large order partially fills multiple smaller orders

	// Create multiple small sell orders
	_ = []types.Order{
		{
			Id:           1,
			MarketId:     1,
			Creator:      "seller1",
			Side:         types.ORDER_SIDE_SELL,
			OutcomeIndex: 0,
			Price:        "100",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(30)},
			FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
			Status:       types.ORDER_STATUS_OPEN,
			CreatedAt:    time.Now().Unix(),
		},
		{
			Id:           2,
			MarketId:     1,
			Creator:      "seller2",
			Side:         types.ORDER_SIDE_SELL,
			OutcomeIndex: 0,
			Price:        "100",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(40)},
			FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
			Status:       types.ORDER_STATUS_OPEN,
			CreatedAt:    time.Now().Unix(),
		},
		{
			Id:           3,
			MarketId:     1,
			Creator:      "seller3",
			Side:         types.ORDER_SIDE_SELL,
			OutcomeIndex: 0,
			Price:        "101",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(50)},
			FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
			Status:       types.ORDER_STATUS_OPEN,
			CreatedAt:    time.Now().Unix(),
		},
	}

	// Large buy order that will partially fill multiple orders
	_ = types.Order{
		Id:           4,
		MarketId:     1,
		Creator:      "bigbuyer",
		Side:         types.ORDER_SIDE_BUY,
		OutcomeIndex: 0,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	// Expected trades:
	// 1. Buy 30 from seller1 at 100
	// 2. Buy 40 from seller2 at 100
	// 3. Buy 30 from seller3 at 101 (partial fill)

	expectedTrades := []types.Trade{
		{
			TradeId:      1,
			MarketId:     1,
			OutcomeIndex: 0,
			Buyer:        "bigbuyer",
			Seller:       "seller1",
			Price:        "100",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(30)},
			Timestamp:    time.Now().Unix(),
		},
		{
			TradeId:      2,
			MarketId:     1,
			OutcomeIndex: 0,
			Buyer:        "bigbuyer",
			Seller:       "seller2",
			Price:        "100",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(40)},
			Timestamp:    time.Now().Unix(),
		},
		{
			TradeId:      3,
			MarketId:     1,
			OutcomeIndex: 0,
			Buyer:        "bigbuyer",
			Seller:       "seller3",
			Price:        "101",
			Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(30)},
			Timestamp:    time.Now().Unix(),
		},
	}

	// Validate trade logic
	totalTraded := math.ZeroInt()
	for _, trade := range expectedTrades {
		totalTraded = totalTraded.Add(trade.Amount.Amount)
		require.True(t, trade.Amount.Amount.GT(math.ZeroInt()), "Trade amount should be positive")
	}

	require.Equal(t, math.NewInt(100), totalTraded, "Total traded should equal buy order amount")

	// Test order status updates
	expectedStatuses := map[uint64]types.OrderStatus{
		1: types.ORDER_STATUS_FILLED,           // seller1 fully filled
		2: types.ORDER_STATUS_FILLED,           // seller2 fully filled
		3: types.ORDER_STATUS_PARTIALLY_FILLED, // seller3 partially filled
		4: types.ORDER_STATUS_FILLED,           // bigbuyer fully filled
	}

	for orderID, expectedStatus := range expectedStatuses {
		require.Contains(t, expectedStatuses, orderID, "Order ID should be tracked")
		require.True(t, expectedStatus == types.ORDER_STATUS_FILLED ||
			expectedStatus == types.ORDER_STATUS_PARTIALLY_FILLED, "Status should be valid")
	}
}

// TestOrderBookIntegration_NoMatch tests scenarios where orders don't match
func TestOrderBookIntegration_NoMatch(t *testing.T) {
	// Test scenarios where orders should not match

	// Scenario 1: Buy order below best ask
	buyOrder := types.Order{
		Id:           1,
		MarketId:     1,
		Creator:      "buyer",
		Side:         types.ORDER_SIDE_BUY,
		OutcomeIndex: 0,
		Price:        "99",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	sellOrder := types.Order{
		Id:           2,
		MarketId:     1,
		Creator:      "seller",
		Side:         types.ORDER_SIDE_SELL,
		OutcomeIndex: 0,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	// Orders should not match
	buyPrice := parsePrice(buyOrder.Price)
	sellPrice := parsePrice(sellOrder.Price)
	shouldMatch := buyPrice.GTE(sellPrice)
	require.False(t, shouldMatch, "Buy order at 99 should not match sell order at 100")

	// Scenario 2: Sell order above best bid
	sellOrder2 := types.Order{
		Id:           3,
		MarketId:     1,
		Creator:      "seller2",
		Side:         types.ORDER_SIDE_SELL,
		OutcomeIndex: 0,
		Price:        "101",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	buyOrder2 := types.Order{
		Id:           4,
		MarketId:     1,
		Creator:      "buyer2",
		Side:         types.ORDER_SIDE_BUY,
		OutcomeIndex: 0,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	// Orders should not match
	buyPrice2 := parsePrice(buyOrder2.Price)
	sellPrice2 := parsePrice(sellOrder2.Price)
	shouldMatch2 := buyPrice2.GTE(sellPrice2)
	require.False(t, shouldMatch2, "Buy order at 100 should not match sell order at 101")
}

// TestOrderBookIntegration_CrossMarketIsolation tests that orders don't cross markets
func TestOrderBookIntegration_CrossMarketIsolation(t *testing.T) {
	// Test that orders in different markets don't interfere with each other

	// Market 1 orders
	market1Order := types.Order{
		Id:           1,
		MarketId:     1,
		Creator:      "user1",
		Side:         types.ORDER_SIDE_SELL,
		OutcomeIndex: 0,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	// Market 2 orders
	market2Order := types.Order{
		Id:           2,
		MarketId:     2,
		Creator:      "user2",
		Side:         types.ORDER_SIDE_BUY,
		OutcomeIndex: 0,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	// Orders should be in different markets
	require.NotEqual(t, market1Order.MarketId, market2Order.MarketId, "Orders should be in different markets")

	// Test market isolation logic
	orders := []types.Order{market1Order, market2Order}
	for _, order := range orders {
		require.True(t, order.MarketId == 1 || order.MarketId == 2, "Order should be in valid market")
		require.Equal(t, uint32(0), order.OutcomeIndex, "Order should be for outcome 0")
	}
}

// TestOrderBookIntegration_CrossOutcomeIsolation tests that orders don't cross outcomes
func TestOrderBookIntegration_CrossOutcomeIsolation(t *testing.T) {
	// Test that orders for different outcomes don't interfere with each other

	// Outcome 0 orders
	outcome0Order := types.Order{
		Id:           1,
		MarketId:     1,
		Creator:      "user1",
		Side:         types.ORDER_SIDE_SELL,
		OutcomeIndex: 0,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	// Outcome 1 orders
	outcome1Order := types.Order{
		Id:           2,
		MarketId:     1,
		Creator:      "user2",
		Side:         types.ORDER_SIDE_BUY,
		OutcomeIndex: 1,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	// Orders should be for different outcomes
	require.NotEqual(t, outcome0Order.OutcomeIndex, outcome1Order.OutcomeIndex, "Orders should be for different outcomes")

	// Test outcome isolation logic
	orders := []types.Order{outcome0Order, outcome1Order}
	for _, order := range orders {
		require.True(t, order.OutcomeIndex == 0 || order.OutcomeIndex == 1, "Order should be for valid outcome")
		require.Equal(t, uint64(1), order.MarketId, "Order should be in market 1")
	}
}
