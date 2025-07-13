package keeper

import (
	"context"
	"speculod/x/reputation/types"

	"cosmossdk.io/errors"
	sdk "github.com/cosmos/cosmos-sdk/types"
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

func (s msgServer) AdjustScore(goCtx context.Context, msg *types.MsgAdjustScore) (*types.MsgAdjustScoreResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Check if the signer is the authority
	authorityBytes, err := s.addressCodec.StringToBytes(msg.Authority)
	if err != nil {
		return nil, errors.Wrap(types.ErrInvalidSigner, "invalid authority address")
	}
	if string(authorityBytes) != string(s.GetAuthority()) {
		return nil, errors.Wrap(types.ErrInvalidSigner, "unauthorized: authority does not match")
	}

	err = s.AdjustReputationScore(ctx, msg.Address, msg.GroupId, msg.Adjustment)
	if err != nil {
		// TODO: Add more granular error handling for logic errors
		return nil, errors.Wrap(types.ErrInvalidSigner, err.Error())
	}

	return &types.MsgAdjustScoreResponse{}, nil
}
