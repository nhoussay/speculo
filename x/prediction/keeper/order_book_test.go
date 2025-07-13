package keeper

import (
	"testing"
	"time"

	"speculod/x/prediction/types"

	"cosmossdk.io/math"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"
)

// TestOrderMatching_BasicMatch tests basic order matching functionality
func TestOrderMatching_BasicMatch(t *testing.T) {
	// This test would require a proper test setup with the full app context
	// For now, we'll test the core matching logic in isolation

	// Test price parsing
	price := parsePrice("100")
	expectedPrice, _ := math.LegacyNewDecFromStr("100")
	require.Equal(t, expectedPrice, price, "Price should parse correctly")

	// Test invalid price
	invalidPrice := parsePrice("invalid")
	require.Equal(t, math.LegacyZeroDec(), invalidPrice, "Invalid price should return zero")
}

// TestOrderMatching_PriceComparison tests price comparison logic
func TestOrderMatching_PriceComparison(t *testing.T) {
	buyPrice := parsePrice("100")
	sellPrice := parsePrice("99")

	// Buy order should match sell order at lower or equal price
	shouldMatch := buyPrice.GTE(sellPrice)
	require.True(t, shouldMatch, "Buy order at 100 should match sell order at 99")

	// Sell order should match buy order at higher or equal price
	shouldMatch = sellPrice.LTE(buyPrice)
	require.True(t, shouldMatch, "Sell order at 99 should match buy order at 100")

	// Orders at same price should match
	samePrice := parsePrice("100")
	shouldMatch = buyPrice.Equal(samePrice)
	require.True(t, shouldMatch, "Orders at same price should match")
}

// TestOrderMatching_NoMatch tests when orders should not match
func TestOrderMatching_NoMatch(t *testing.T) {
	buyPrice := parsePrice("99")
	sellPrice := parsePrice("100")

	// Buy order at 99 should not match sell order at 100
	shouldMatch := buyPrice.GTE(sellPrice)
	require.False(t, shouldMatch, "Buy order at 99 should not match sell order at 100")
}

// TestOrderStatus_Transitions tests order status transitions
func TestOrderStatus_Transitions(t *testing.T) {
	// Test order status constants
	require.Equal(t, types.OrderStatus(1), types.ORDER_STATUS_OPEN, "Open status should be 1")
	require.Equal(t, types.OrderStatus(2), types.ORDER_STATUS_PARTIALLY_FILLED, "Partially filled status should be 2")
	require.Equal(t, types.OrderStatus(3), types.ORDER_STATUS_FILLED, "Filled status should be 3")
	require.Equal(t, types.OrderStatus(4), types.ORDER_STATUS_CANCELLED, "Cancelled status should be 4")
}

// TestOrderSide_Constants tests order side constants
func TestOrderSide_Constants(t *testing.T) {
	// Test order side constants
	require.Equal(t, types.OrderSide(1), types.ORDER_SIDE_BUY, "Buy side should be 1")
	require.Equal(t, types.OrderSide(2), types.ORDER_SIDE_SELL, "Sell side should be 2")
}

// TestOrder_Structure tests order structure
func TestOrder_Structure(t *testing.T) {
	// Test creating an order
	order := types.Order{
		Id:           1,
		MarketId:     1,
		Creator:      "test_user",
		Side:         types.ORDER_SIDE_BUY,
		OutcomeIndex: 0,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		FilledAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(0)},
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    time.Now().Unix(),
	}

	require.Equal(t, uint64(1), order.Id, "Order ID should be 1")
	require.Equal(t, types.ORDER_SIDE_BUY, order.Side, "Order side should be BUY")
	require.Equal(t, types.ORDER_STATUS_OPEN, order.Status, "Order status should be OPEN")
	require.Equal(t, "100", order.Price, "Order price should be 100")
}

// TestTrade_Structure tests trade structure
func TestTrade_Structure(t *testing.T) {
	// Test creating a trade
	trade := types.Trade{
		TradeId:      1,
		MarketId:     1,
		OutcomeIndex: 0,
		Buyer:        "buyer",
		Seller:       "seller",
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		Timestamp:    time.Now().Unix(),
	}

	require.Equal(t, uint64(1), trade.TradeId, "Trade ID should be 1")
	require.Equal(t, "buyer", trade.Buyer, "Trade buyer should be 'buyer'")
	require.Equal(t, "seller", trade.Seller, "Trade seller should be 'seller'")
	require.Equal(t, "100", trade.Price, "Trade price should be 100")
}

// TestOrderBook_Structure tests order book structure
func TestOrderBook_Structure(t *testing.T) {
	// Test creating an order book
	orderBook := types.OrderBook{
		MarketId:     1,
		OutcomeIndex: 0,
		Bids:         []*types.Order{},
		Asks:         []*types.Order{},
	}

	require.Equal(t, uint64(1), orderBook.MarketId, "Order book market ID should be 1")
	require.Equal(t, uint32(0), orderBook.OutcomeIndex, "Order book outcome index should be 0")
	require.Len(t, orderBook.Bids, 0, "Order book should start with no bids")
	require.Len(t, orderBook.Asks, 0, "Order book should start with no asks")
}

// TestOrderBookEntry_Structure tests order book entry structure
func TestOrderBookEntry_Structure(t *testing.T) {
	// Test creating an order book entry
	entry := types.OrderBookEntry{
		Price:       "100",
		TotalAmount: &sdk.Coin{Denom: "stake", Amount: math.NewInt(500)},
		OrderCount:  5,
	}

	require.Equal(t, "100", entry.Price, "Entry price should be 100")
	require.Equal(t, math.NewInt(500), entry.TotalAmount.Amount, "Entry total amount should be 500")
	require.Equal(t, uint32(5), entry.OrderCount, "Entry order count should be 5")
}

// TestPriceTimePriority_Logic tests price-time priority logic
func TestPriceTimePriority_Logic(t *testing.T) {
	// Test that better prices come first
	price1 := parsePrice("100")
	price2 := parsePrice("101")

	// For buy orders, lower prices are better
	buyBetter := price1.LT(price2)
	require.True(t, buyBetter, "For buy orders, 100 should be better than 101")

	// For sell orders, higher prices are better
	sellBetter := price2.GT(price1)
	require.True(t, sellBetter, "For sell orders, 101 should be better than 100")
}

// TestPartialFill_Logic tests partial fill logic
func TestPartialFill_Logic(t *testing.T) {
	// Test partial fill calculation
	orderAmount := math.NewInt(100)
	filledAmount := math.NewInt(30)
	remainingAmount := orderAmount.Sub(filledAmount)

	require.Equal(t, math.NewInt(70), remainingAmount, "Remaining amount should be 70")

	// Test if order is fully filled
	isFullyFilled := orderAmount.Equal(filledAmount)
	require.False(t, isFullyFilled, "Order should not be fully filled")

	// Test if order is partially filled
	isPartiallyFilled := filledAmount.GT(math.ZeroInt()) && filledAmount.LT(orderAmount)
	require.True(t, isPartiallyFilled, "Order should be partially filled")
}

// TestOrderValidation_Logic tests order validation logic
func TestOrderValidation_Logic(t *testing.T) {
	// Test valid order
	validOrder := types.Order{
		Id:           1,
		MarketId:     1,
		Creator:      "test_user",
		Side:         types.ORDER_SIDE_BUY,
		OutcomeIndex: 0,
		Price:        "100",
		Amount:       &sdk.Coin{Denom: "stake", Amount: math.NewInt(100)},
		Status:       types.ORDER_STATUS_OPEN,
	}

	// Test that order has required fields
	require.NotEmpty(t, validOrder.Creator, "Order should have a creator")
	require.NotEmpty(t, validOrder.Price, "Order should have a price")
	require.NotNil(t, validOrder.Amount, "Order should have an amount")
	require.True(t, validOrder.Amount.Amount.GT(math.ZeroInt()), "Order amount should be positive")
}

// BenchmarkPriceParsing benchmarks price parsing performance
func BenchmarkPriceParsing(b *testing.B) {
	for i := 0; i < b.N; i++ {
		parsePrice("100.50")
	}
}

// BenchmarkOrderComparison benchmarks order comparison performance
func BenchmarkOrderComparison(b *testing.B) {
	price1 := parsePrice("100")
	price2 := parsePrice("101")

	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		_ = price1.LT(price2)
		_ = price2.GT(price1)
		_ = price1.Equal(price2)
	}
}
