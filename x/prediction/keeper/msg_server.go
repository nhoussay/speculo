package keeper

import (
	"context"
	"fmt"
	"speculod/x/prediction/types"

	"cosmossdk.io/math"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/pkg/errors"
)

type msgServer struct {
	Keeper
}

// NewMsgServerImpl returns an implementation of the MsgServer interface
// for the provided Keeper.
func NewMsgServerImpl(keeper Keeper) types.MsgServer {
	return &msgServer{Keeper: keeper}
}

var _ types.MsgServer = msgServer{}

func (k msgServer) CreateMarket(goCtx context.Context, msg *types.MsgCreateMarket) (*types.MsgCreateMarketResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Validation
	if len(msg.Outcomes) < 2 {
		return nil, errors.Wrap(types.ErrInvalidRequest, "at least two outcomes required")
	}
	if msg.Question == "" {
		return nil, errors.Wrap(types.ErrInvalidRequest, "question cannot be empty")
	}
	if msg.Deadline <= ctx.BlockTime().Unix() {
		return nil, errors.Wrap(types.ErrInvalidRequest, "deadline must be in the future")
	}
	// Check for unique, non-empty outcomes
	outcomeSet := make(map[string]struct{})
	for _, o := range msg.Outcomes {
		if o == "" {
			return nil, errors.Wrap(types.ErrInvalidRequest, "outcome cannot be empty")
		}
		if _, exists := outcomeSet[o]; exists {
			return nil, errors.Wrap(types.ErrInvalidRequest, "duplicate outcome")
		}
		outcomeSet[o] = struct{}{}
	}

	// Assign ID and store
	marketID := k.Keeper.AppendMarket(ctx, msg.Creator)
	market := types.PredictionMarket{
		Id:        marketID,
		Question:  msg.Question,
		Outcomes:  msg.Outcomes,
		GroupId:   msg.GroupId,
		Deadline:  msg.Deadline,
		Status:    "open",
		Creator:   msg.Creator,
		CreatedAt: ctx.BlockTime().Unix(),
	}
	k.Keeper.SetPredictionMarket(ctx, market)

	return &types.MsgCreateMarketResponse{
		MarketId: marketID,
		Status:   "open",
	}, nil
}

// PostOrder handles posting a new order to the order book
func (k msgServer) PostOrder(goCtx context.Context, msg *types.MsgPostOrder) (*types.MsgPostOrderResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Validate market exists
	market, found := k.Keeper.GetPredictionMarket(ctx, msg.MarketId)
	if !found {
		return nil, errors.Wrapf(types.ErrMarketNotFound, "market %d not found", msg.MarketId)
	}

	// Validate outcome index
	if msg.OutcomeIndex >= uint32(len(market.Outcomes)) {
		return nil, errors.Wrapf(types.ErrInvalidOutcome, "outcome index %d out of range", msg.OutcomeIndex)
	}

	// Validate side
	if msg.Side != "BUY" && msg.Side != "SELL" {
		return nil, errors.Wrap(types.ErrInvalidRequest, "side must be BUY or SELL")
	}

	// Validate price
	if msg.Price == "" {
		return nil, errors.Wrap(types.ErrInvalidRequest, "price cannot be empty")
	}

	// Validate amount
	if msg.Amount == nil || msg.Amount.Amount.IsZero() {
		return nil, errors.Wrap(types.ErrInvalidAmount, "amount cannot be zero")
	}

	// Create order
	orderID := k.Keeper.AppendOrder(ctx)
	zeroCoin := sdk.NewCoin(msg.Amount.Denom, math.NewInt(0))

	// Convert side string to enum
	var side types.OrderSide
	if msg.Side == "BUY" {
		side = types.ORDER_SIDE_BUY
	} else if msg.Side == "SELL" {
		side = types.ORDER_SIDE_SELL
	} else {
		return nil, errors.Wrap(types.ErrInvalidRequest, "side must be BUY or SELL")
	}

	order := types.Order{
		Id:           orderID,
		MarketId:     msg.MarketId,
		Creator:      msg.Creator,
		Side:         side,
		OutcomeIndex: msg.OutcomeIndex,
		Price:        msg.Price,
		Amount:       msg.Amount,
		FilledAmount: &zeroCoin,
		Status:       types.ORDER_STATUS_OPEN,
		CreatedAt:    ctx.BlockTime().Unix(),
	}

	// Store the order and attempt automatic matching
	k.Keeper.SetOrder(ctx, order)
	trades := k.Keeper.MatchOrder(ctx, order)

	// Convert trades to pointers for response
	var tradePtrs []*types.Trade
	for i := range trades {
		tradePtrs = append(tradePtrs, &trades[i])
	}

	return &types.MsgPostOrderResponse{
		OrderId: orderID,
		Status:  "posted",
		Trades:  tradePtrs,
	}, nil
}

// CancelOrder handles canceling an existing order
func (k msgServer) CancelOrder(goCtx context.Context, msg *types.MsgCancelOrder) (*types.MsgCancelOrderResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Get the order
	order, found := k.Keeper.GetOrder(ctx, msg.OrderId)
	if !found {
		return nil, fmt.Errorf("order %d not found", msg.OrderId)
	}

	// Check if the creator is the one canceling
	if order.Creator != msg.Creator {
		return nil, fmt.Errorf("only order creator can cancel")
	}

	// Check if order can be canceled
	if order.Status == types.ORDER_STATUS_FILLED || order.Status == types.ORDER_STATUS_CANCELLED {
		return nil, fmt.Errorf("order cannot be canceled")
	}

	// Cancel the order
	order.Status = types.ORDER_STATUS_CANCELLED
	k.Keeper.SetOrder(ctx, order)

	// Refund unfilled amount if any
	if order.FilledAmount.Amount.LT(order.Amount.Amount) {
		// TODO: Implement refund logic
		_ = order.Amount.Sub(*order.FilledAmount)
	}

	return &types.MsgCancelOrderResponse{
		Status: "cancelled",
	}, nil
}

// FillOrder handles filling an existing order
func (k msgServer) FillOrder(goCtx context.Context, msg *types.MsgFillOrder) (*types.MsgFillOrderResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Get the order
	order, found := k.Keeper.GetOrder(ctx, msg.OrderId)
	if !found {
		return nil, fmt.Errorf("order %d not found", msg.OrderId)
	}

	// Check if order is fillable
	if order.Status != types.ORDER_STATUS_OPEN && order.Status != types.ORDER_STATUS_PARTIALLY_FILLED {
		return nil, fmt.Errorf("order cannot be filled")
	}

	// Validate fill amount
	if msg.Amount == nil || msg.Amount.Amount.IsZero() {
		return nil, fmt.Errorf("amount cannot be zero")
	}

	// Check if fill amount is valid
	remainingAmount := order.Amount.Sub(*order.FilledAmount)
	if msg.Amount.Amount.GT(remainingAmount.Amount) {
		return nil, fmt.Errorf("fill amount exceeds remaining amount")
	}

	// Execute the fill
	_ = k.Keeper.FillOrder(ctx, order, msg.Filler, msg.Amount)

	return &types.MsgFillOrderResponse{
		Status: "filled",
		Trades: []*types.Trade{}, // Empty slice for now
	}, nil
}
