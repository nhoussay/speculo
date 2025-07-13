package keeper

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"speculod/x/settlement/types"

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

// Params queries the parameters of the settlement module.
func (qs queryServer) Params(c context.Context, req *types.QueryParamsRequest) (*types.QueryParamsResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}
	ctx := sdk.UnwrapSDKContext(c)

	return &types.QueryParamsResponse{Params: qs.k.GetParams(ctx)}, nil
}

// Commits queries all vote commits for a market.
func (qs queryServer) Commits(c context.Context, req *types.QueryCommitsRequest) (*types.QueryCommitsResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}
	ctx := sdk.UnwrapSDKContext(c)

	var commits []types.VoteCommit
	iterator, err := qs.k.Commits.Iterate(ctx, nil)
	if err != nil {
		return nil, status.Error(codes.Internal, "failed to iterate commits")
	}
	defer iterator.Close()

	for ; iterator.Valid(); iterator.Next() {
		key, err := iterator.Key()
		if err != nil {
			continue
		}
		// Filter by market ID
		if len(key) > 0 && key[:len(sdk.Uint64ToBigEndian(req.MarketId))] == string(sdk.Uint64ToBigEndian(req.MarketId)) {
			commit, err := iterator.Value()
			if err == nil {
				commits = append(commits, commit)
			}
		}
	}

	return &types.QueryCommitsResponse{Commits: commits}, nil
}

// Reveals queries all vote reveals for a market.
func (qs queryServer) Reveals(c context.Context, req *types.QueryRevealsRequest) (*types.QueryRevealsResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}
	ctx := sdk.UnwrapSDKContext(c)

	reveals := qs.k.GetAllReveals(ctx, req.MarketId)

	return &types.QueryRevealsResponse{Reveals: reveals}, nil
}

// Outcome queries the final outcome for a market.
func (qs queryServer) Outcome(c context.Context, req *types.QueryOutcomeRequest) (*types.QueryOutcomeResponse, error) {
	if req == nil {
		return nil, status.Error(codes.InvalidArgument, "invalid request")
	}
	ctx := sdk.UnwrapSDKContext(c)

	outcome, found := qs.k.GetOutcome(ctx, req.MarketId)
	if !found {
		return nil, status.Error(codes.NotFound, "outcome not found")
	}

	return &types.QueryOutcomeResponse{Outcome: outcome}, nil
}
