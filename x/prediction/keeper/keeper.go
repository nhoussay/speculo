package keeper

import (
	"fmt"
	"sort"

	"cosmossdk.io/math"

	"cosmossdk.io/collections"
	"cosmossdk.io/core/address"
	corestore "cosmossdk.io/core/store"
	"github.com/cosmos/cosmos-sdk/codec"

	"speculod/x/prediction/types"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// BankKeeper defines the expected bank keeper interface
type BankKeeper interface {
	SendCoinsFromAccountToModule(ctx sdk.Context, senderAddr sdk.AccAddress, recipientModule string, amt sdk.Coins) error
}

// PositionKeyTuple is a tuple key for position storage
var PositionKeyTuple = collections.NewPrefix("positions")

// Custom key type for positions
type PositionKey struct {
	MarketId     uint64
	Owner        string
	OutcomeIndex uint32
}

// Custom key codec for PositionKey
type PositionKeyCodec struct{}

func (PositionKeyCodec) Encode(b []byte, k PositionKey) ([]byte, error) {
	b = sdk.Uint64ToBigEndian(k.MarketId)
	b = append(b, []byte(k.Owner)...)
	b = append(b, sdk.Uint64ToBigEndian(uint64(k.OutcomeIndex))...)
	return b, nil
}
func (PositionKeyCodec) Decode(b []byte) (PositionKey, []byte, error) {
	if len(b) < 8 {
		return PositionKey{}, nil, fmt.Errorf("not enough bytes for market id")
	}
	marketId := sdk.BigEndianToUint64(b[:8])
	b = b[8:]
	// Owner is variable length, so we need a separator or fixed length. For now, assume 42 (bech32 address)
	if len(b) < 42+8 {
		return PositionKey{}, nil, fmt.Errorf("not enough bytes for owner+outcome")
	}
	owner := string(b[:42])
	b = b[42:]
	outcomeIndex := uint32(sdk.BigEndianToUint64(b[:8]))
	b = b[8:]
	return PositionKey{marketId, owner, outcomeIndex}, b, nil
}
func (PositionKeyCodec) Size(_ PositionKey) int { return 8 + 42 + 8 }

// Helper to build composite key for positions
func PositionCompositeKey(marketId uint64, owner string, outcomeIndex uint32) string {
	return fmt.Sprintf("%d/%s/%d", marketId, owner, outcomeIndex)
}

// Keeper struct (add fields for market storage)
type Keeper struct {
	storeService corestore.KVStoreService
	cdc          codec.Codec
	addressCodec address.Codec
	// Address capable of executing a MsgUpdateParams message.
	// Typically, this should be the x/gov module account.
	authority  []byte
	bankKeeper types.BankKeeper
	Schema     collections.Schema
	Params     collections.Item[types.Params]

	// Market storage
	MarketIDSeq collections.Sequence
	Markets     collections.Map[uint64, types.PredictionMarket]

	// Order storage
	OrderIDSeq collections.Sequence
	Orders     collections.Map[uint64, types.Order]

	// Position storage
	Positions collections.Map[string, types.Position]
}

func NewKeeper(
	storeService corestore.KVStoreService,
	cdc codec.Codec,
	addressCodec address.Codec,

	authority []byte,
	bk types.BankKeeper,

) Keeper {
	if _, err := addressCodec.BytesToString(authority); err != nil {
		panic(fmt.Sprintf("invalid authority address %s: %s", authority, err))
	}

	sb := collections.NewSchemaBuilder(storeService)

	k := Keeper{
		storeService: storeService,
		cdc:          cdc,
		addressCodec: addressCodec,
		authority:    authority,
		bankKeeper:   bk, // Can be nil for now
		Params:       collections.NewItem(sb, types.ParamsKey, "params", codec.CollValue[types.Params](cdc)),
		MarketIDSeq:  collections.NewSequence(sb, collections.NewPrefix("market_id"), "market_id_seq"),
		Markets:      collections.NewMap(sb, collections.NewPrefix("markets"), "markets", collections.Uint64Key, codec.CollValue[types.PredictionMarket](cdc)),
		OrderIDSeq:   collections.NewSequence(sb, collections.NewPrefix("order_id"), "order_id_seq"),
		Orders:       collections.NewMap(sb, collections.NewPrefix("orders"), "orders", collections.Uint64Key, codec.CollValue[types.Order](cdc)),
		Positions:    collections.NewMap(sb, PositionKeyTuple, "positions", collections.StringKey, codec.CollValue[types.Position](cdc)),
	}

	schema, err := sb.Build()
	if err != nil {
		panic(err)
	}
	k.Schema = schema

	return k
}

// GetAuthority returns the module's authority.
func (k Keeper) GetAuthority() []byte {
	return k.authority
}

// AppendMarket increments the market ID and returns it
func (k Keeper) AppendMarket(ctx sdk.Context, creator string) uint64 {
	id, err := k.MarketIDSeq.Next(ctx)
	if err != nil {
		panic(err)
	}
	return id
}

// SetPredictionMarket stores a market by ID
func (k Keeper) SetPredictionMarket(ctx sdk.Context, market types.PredictionMarket) {
	if err := k.Markets.Set(ctx, market.Id, market); err != nil {
		panic(err)
	}
}

// GetPredictionMarket fetches a market by ID
func (k Keeper) GetPredictionMarket(ctx sdk.Context, id uint64) (types.PredictionMarket, bool) {
	market, err := k.Markets.Get(ctx, id)
	if err != nil {
		return types.PredictionMarket{}, false
	}
	return market, true
}

// GetPosition fetches a position by market, owner, and outcome index
func (k Keeper) GetPosition(ctx sdk.Context, marketId uint64, owner string, outcomeIndex uint32) (types.Position, bool) {
	key := PositionCompositeKey(marketId, owner, outcomeIndex)
	pos, err := k.Positions.Get(ctx, key)
	if err != nil {
		return types.Position{}, false
	}
	return pos, true
}

// SetPosition stores a position
func (k Keeper) SetPosition(ctx sdk.Context, pos types.Position, outcomeIndex uint32) {
	key := PositionCompositeKey(pos.MarketId, pos.Owner, outcomeIndex)
	if err := k.Positions.Set(ctx, key, pos); err != nil {
		panic(err)
	}
}

// AddToPosition adds amount to a user's position (creates if not exists)
func (k Keeper) AddToPosition(ctx sdk.Context, marketId uint64, owner string, outcomeIndex uint32, amount *sdk.Coin) {
	pos, found := k.GetPosition(ctx, marketId, owner, outcomeIndex)
	if found {
		if pos.Amount == nil {
			c := sdk.NewCoin(amount.Denom, amount.Amount)
			pos.Amount = &c
		} else {
			added := pos.Amount.Add(*amount)
			pos.Amount = &added
		}
		k.SetPosition(ctx, pos, outcomeIndex)
	} else {
		pos = types.Position{
			MarketId: marketId,
			Owner:    owner,
			Amount:   amount,
			IsBuy:    true,
		}
		k.SetPosition(ctx, pos, outcomeIndex)
	}
}

// AppendOrder increments the order ID and returns it
func (k Keeper) AppendOrder(ctx sdk.Context) uint64 {
	id, err := k.OrderIDSeq.Next(ctx)
	if err != nil {
		panic(err)
	}
	return id
}

// SetOrder stores an order by ID
func (k Keeper) SetOrder(ctx sdk.Context, order types.Order) {
	if err := k.Orders.Set(ctx, order.Id, order); err != nil {
		panic(err)
	}
}

// GetOrder fetches an order by ID
func (k Keeper) GetOrder(ctx sdk.Context, id uint64) (types.Order, bool) {
	order, err := k.Orders.Get(ctx, id)
	if err != nil {
		return types.Order{}, false
	}
	return order, true
}

// GetAllOrders returns all orders
func (k Keeper) GetAllOrders(ctx sdk.Context) []types.Order {
	var orders []types.Order
	iterator, err := k.Orders.Iterate(ctx, nil)
	if err != nil {
		return orders
	}
	defer iterator.Close()
	for ; iterator.Valid(); iterator.Next() {
		order, err := iterator.Value()
		if err == nil {
			orders = append(orders, order)
		}
	}
	return orders
}

// GetOrdersByMarketAndOutcome returns all orders for a specific market and outcome
func (k Keeper) GetOrdersByMarketAndOutcome(ctx sdk.Context, marketId uint64, outcomeIndex uint32) []types.Order {
	var orders []types.Order
	iterator, err := k.Orders.Iterate(ctx, nil)
	if err != nil {
		return orders
	}
	defer iterator.Close()
	for ; iterator.Valid(); iterator.Next() {
		order, err := iterator.Value()
		if err == nil && order.MarketId == marketId && order.OutcomeIndex == outcomeIndex {
			orders = append(orders, order)
		}
	}
	return orders
}

func parsePrice(priceStr string) math.LegacyDec {
	dec, err := math.LegacyNewDecFromStr(priceStr)
	if err != nil {
		return math.LegacyZeroDec()
	}
	return dec
}

func (k Keeper) MatchOrder(ctx sdk.Context, newOrder types.Order) []types.Trade {
	var trades []types.Trade

	// Get all open opposite orders for this market/outcome
	allOrders := k.GetOrdersByMarketAndOutcome(ctx, newOrder.MarketId, newOrder.OutcomeIndex)
	var candidates []types.Order
	newOrderPrice := parsePrice(newOrder.Price)

	for _, o := range allOrders {
		if o.Status == types.ORDER_STATUS_OPEN && o.Side != newOrder.Side {
			oppPrice := parsePrice(o.Price)
			if (newOrder.Side == types.ORDER_SIDE_BUY && oppPrice.LTE(newOrderPrice)) ||
				(newOrder.Side == types.ORDER_SIDE_SELL && oppPrice.GTE(newOrderPrice)) {
				candidates = append(candidates, o)
			}
		}
	}

	// Sort candidates: best price first, then earliest created
	sort.SliceStable(candidates, func(i, j int) bool {
		pi := parsePrice(candidates[i].Price)
		pj := parsePrice(candidates[j].Price)
		if newOrder.Side == types.ORDER_SIDE_BUY {
			// Lowest ask first
			if !pi.Equal(pj) {
				return pi.LT(pj)
			}
		} else {
			// Highest bid first
			if !pi.Equal(pj) {
				return pi.GT(pj)
			}
		}
		return candidates[i].CreatedAt < candidates[j].CreatedAt
	})

	remaining := newOrder.Amount.Amount
	for _, opp := range candidates {
		if remaining.IsZero() {
			break
		}
		oppOrder, found := k.GetOrder(ctx, opp.Id)
		if !found || oppOrder.Status != types.ORDER_STATUS_OPEN {
			continue
		}
		available := oppOrder.Amount.Amount.Sub(oppOrder.FilledAmount.Amount)
		fill := math.MinInt(remaining, available)
		if fill.IsZero() {
			continue
		}

		// Create trade
		tradeID := k.AppendTrade(ctx)
		tradeCoin := sdk.NewCoin(newOrder.Amount.Denom, fill)
		trade := types.Trade{
			TradeId:      tradeID,
			MarketId:     newOrder.MarketId,
			OutcomeIndex: newOrder.OutcomeIndex,
			Buyer:        chooseBuyer(newOrder, oppOrder),
			Seller:       chooseSeller(newOrder, oppOrder),
			Price:        oppOrder.Price, // Use resting order's price
			Amount:       &tradeCoin,
			Timestamp:    ctx.BlockTime().Unix(),
		}
		trades = append(trades, trade)

		// Update resting order
		oppOrder.FilledAmount = &sdk.Coin{Denom: oppOrder.FilledAmount.Denom, Amount: oppOrder.FilledAmount.Amount.Add(fill)}
		if oppOrder.FilledAmount.Amount.Equal(oppOrder.Amount.Amount) {
			oppOrder.Status = types.ORDER_STATUS_FILLED
		} else {
			oppOrder.Status = types.ORDER_STATUS_PARTIALLY_FILLED
		}
		k.SetOrder(ctx, oppOrder)

		// Update new order
		if newOrder.FilledAmount == nil {
			newOrder.FilledAmount = &sdk.Coin{Denom: newOrder.Amount.Denom, Amount: fill}
		} else {
			newOrder.FilledAmount = &sdk.Coin{Denom: newOrder.FilledAmount.Denom, Amount: newOrder.FilledAmount.Amount.Add(fill)}
		}
		if newOrder.FilledAmount.Amount.Equal(newOrder.Amount.Amount) {
			newOrder.Status = types.ORDER_STATUS_FILLED
		} else {
			newOrder.Status = types.ORDER_STATUS_PARTIALLY_FILLED
		}

		remaining = remaining.Sub(fill)
	}

	// Store the (possibly partially filled) new order
	k.SetOrder(ctx, newOrder)
	return trades
}

// Helper to determine buyer/seller for trade
func chooseBuyer(newOrder, oppOrder types.Order) string {
	if newOrder.Side == types.ORDER_SIDE_BUY {
		return newOrder.Creator
	}
	return oppOrder.Creator
}
func chooseSeller(newOrder, oppOrder types.Order) string {
	if newOrder.Side == types.ORDER_SIDE_SELL {
		return newOrder.Creator
	}
	return oppOrder.Creator
}

// FillOrder executes a fill of an order
func (k Keeper) FillOrder(ctx sdk.Context, order types.Order, filler string, amount *sdk.Coin) []types.Trade {
	var trades []types.Trade

	// Calculate fill amount
	remainingAmount := order.Amount.Amount.Sub(order.FilledAmount.Amount)
	fillAmount := amount.Amount
	if amount.Amount.GT(remainingAmount) {
		fillAmount = remainingAmount
	}

	// Create trade
	tradeID := k.AppendTrade(ctx)
	tradeCoin := sdk.NewCoin(amount.Denom, fillAmount)
	trade := types.Trade{
		TradeId:      tradeID,
		MarketId:     order.MarketId,
		OutcomeIndex: order.OutcomeIndex,
		Buyer:        filler, // TODO: Determine buyer/seller based on order side
		Seller:       order.Creator,
		Price:        order.Price,
		Amount:       &tradeCoin,
		Timestamp:    ctx.BlockTime().Unix(),
	}
	trades = append(trades, trade)

	// Update order
	newFilledAmount := order.FilledAmount.Amount.Add(fillAmount)
	filledCoin := sdk.NewCoin(order.FilledAmount.Denom, newFilledAmount)
	order.FilledAmount = &filledCoin
	if order.FilledAmount.Amount.Equal(order.Amount.Amount) {
		order.Status = types.ORDER_STATUS_FILLED
	} else {
		order.Status = types.ORDER_STATUS_PARTIALLY_FILLED
	}
	k.SetOrder(ctx, order)

	return trades
}

// AppendTrade increments the trade ID and returns it
func (k Keeper) AppendTrade(ctx sdk.Context) uint64 {
	// For now, use a simple counter. In a real implementation, you'd have a trade sequence
	return uint64(ctx.BlockHeight())
}
