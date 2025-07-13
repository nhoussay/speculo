package keeper

import (
	"context"
	"fmt"
	"speculod/x/prediction/types"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

var _ types.QueryServer = queryServer{}

// NewQueryServerImpl returns an implementation of the QueryServer interface
// for the provided Keeper.
func NewQueryServerImpl(k Keeper) types.QueryServer {
	return queryServer{k}
}

type queryServer struct {
	k Keeper
}

func (q queryServer) Markets(goCtx context.Context, req *types.QueryMarketsRequest) (*types.QueryMarketsResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)
	var markets []types.PredictionMarket
	iterator, err := q.k.Markets.Iterate(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer iterator.Close()
	for ; iterator.Valid(); iterator.Next() {
		market, err := iterator.Value()
		if err == nil {
			markets = append(markets, market)
		}
	}
	return &types.QueryMarketsResponse{
		Markets:    markets,
		Pagination: nil, // Add pagination if needed
	}, nil
}

func (q queryServer) Market(goCtx context.Context, req *types.QueryMarketRequest) (*types.QueryMarketResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)
	market, err := q.k.Markets.Get(ctx, req.MarketId)
	if err != nil {
		return nil, fmt.Errorf("market not found: %w", err)
	}
	return &types.QueryMarketResponse{Market: market}, nil
}

func (q queryServer) Order(goCtx context.Context, req *types.QueryOrderRequest) (*types.QueryOrderResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)
	order, found := q.k.GetOrder(ctx, req.OrderId)
	if !found {
		return nil, fmt.Errorf("order %d not found", req.OrderId)
	}
	return &types.QueryOrderResponse{Order: order}, nil
}

func (q queryServer) Orders(goCtx context.Context, req *types.QueryOrdersRequest) (*types.QueryOrdersResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)
	allOrders := q.k.GetOrdersByMarketAndOutcome(ctx, req.MarketId, req.OutcomeIndex)
	var filteredOrders []types.Order
	for _, order := range allOrders {
		if order.Status == types.ORDER_STATUS_OPEN || order.Status == types.ORDER_STATUS_PARTIALLY_FILLED {
			filteredOrders = append(filteredOrders, order)
		}
	}
	return &types.QueryOrdersResponse{
		Orders:     filteredOrders,
		Pagination: nil, // Add pagination if needed
	}, nil
}

func (q queryServer) OrderBook(goCtx context.Context, req *types.QueryOrderBookRequest) (*types.QueryOrderBookResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)
	orders := q.k.GetOrdersByMarketAndOutcome(ctx, req.MarketId, req.OutcomeIndex)
	var bids, asks []*types.Order
	for i := range orders {
		if orders[i].Status == types.ORDER_STATUS_OPEN || orders[i].Status == types.ORDER_STATUS_PARTIALLY_FILLED {
			if orders[i].Side == types.ORDER_SIDE_BUY {
				bids = append(bids, &orders[i])
			} else if orders[i].Side == types.ORDER_SIDE_SELL {
				asks = append(asks, &orders[i])
			}
		}
	}
	orderBook := types.OrderBook{
		MarketId:     req.MarketId,
		OutcomeIndex: req.OutcomeIndex,
		Bids:         bids,
		Asks:         asks,
	}
	return &types.QueryOrderBookResponse{OrderBook: orderBook}, nil
}

func (q queryServer) UserOrders(goCtx context.Context, req *types.QueryUserOrdersRequest) (*types.QueryUserOrdersResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)
	allOrders := q.k.GetAllOrders(ctx)
	var userOrders []types.Order
	for _, order := range allOrders {
		if order.Creator == req.User {
			userOrders = append(userOrders, order)
		}
	}
	return &types.QueryUserOrdersResponse{
		Orders:     userOrders,
		Pagination: nil, // Add pagination if needed
	}, nil
}
