package keeper

import (
	"context"
	"speculod/x/settlement/types"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
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

func (q queryServer) Params(goCtx context.Context, req *types.QueryParamsRequest) (*types.QueryParamsResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)
	params := q.k.GetParams(ctx)

	return &types.QueryParamsResponse{Params: params}, nil
}

// Commits queries all vote commits for a market.
func (q queryServer) Commits(goCtx context.Context, req *types.QueryCommitsRequest) (*types.QueryCommitsResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}
	ctx := sdk.UnwrapSDKContext(goCtx)

	commits := q.k.GetAllCommits(ctx, req.MarketId)
	return &types.QueryCommitsResponse{Commits: commits}, nil
}

// Reveals queries all vote reveals for a market.
func (q queryServer) Reveals(goCtx context.Context, req *types.QueryRevealsRequest) (*types.QueryRevealsResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}
	ctx := sdk.UnwrapSDKContext(goCtx)

	reveals := q.k.GetAllReveals(ctx, req.MarketId)
	return &types.QueryRevealsResponse{Reveals: reveals}, nil
}

// Outcome queries the final outcome for a market.
func (q queryServer) Outcome(goCtx context.Context, req *types.QueryOutcomeRequest) (*types.QueryOutcomeResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}
	ctx := sdk.UnwrapSDKContext(goCtx)

	outcome, found := q.k.GetOutcome(ctx, req.MarketId)
	if !found {
		return nil, status.Error(codes.NotFound, "outcome not found")
	}

	return &types.QueryOutcomeResponse{Outcome: outcome}, nil
}
