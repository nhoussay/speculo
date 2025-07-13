package keeper

import (
	"context"
	"crypto/sha256"
	"encoding/hex"

	"speculod/x/settlement/types"

	sdkerrors "cosmossdk.io/errors"
	sdk "github.com/cosmos/cosmos-sdk/types"
)

type msgServer struct {
	Keeper
}

func NewMsgServerImpl(k Keeper) types.MsgServer {
	return &msgServer{Keeper: k}
}

func (k msgServer) CommitVote(goCtx context.Context, msg *types.MsgCommitVote) (*types.MsgCommitVoteResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Prevent double-commit
	_, found := k.GetCommit(ctx, msg.MarketId, msg.Creator)
	if found {
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "user already committed a vote")
	}

	commit := types.VoteCommit{
		MarketId:   msg.MarketId,
		Voter:      msg.Creator,
		Commitment: msg.Commitment,
	}
	k.SetCommit(ctx, commit)
	return &types.MsgCommitVoteResponse{}, nil
}

func (k msgServer) RevealVote(goCtx context.Context, msg *types.MsgRevealVote) (*types.MsgRevealVoteResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	commit, found := k.GetCommit(ctx, msg.MarketId, msg.Creator)
	if !found {
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "no commitment found for this user")
	}
	expected := generateCommitment(msg.Vote, msg.Nonce)
	if commit.Commitment != expected {
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "commitment does not match reveal")
	}
	_, alreadyRevealed := k.GetReveal(ctx, msg.MarketId, msg.Creator)
	if alreadyRevealed {
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "user already revealed their vote")
	}
	reveal := types.VoteReveal{
		MarketId: msg.MarketId,
		Voter:    msg.Creator,
		Vote:     msg.Vote,
		Nonce:    msg.Nonce,
	}
	k.SetReveal(ctx, reveal)
	return &types.MsgRevealVoteResponse{}, nil
}

func (k msgServer) FinalizeOutcome(goCtx context.Context, msg *types.MsgFinalizeOutcome) (*types.MsgFinalizeOutcomeResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Prevent double-finalization
	_, found := k.GetOutcome(ctx, msg.MarketId)
	if found {
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "outcome already finalized")
	}

	reveals := k.GetAllReveals(ctx, msg.MarketId)
	if len(reveals) == 0 {
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "no reveals found for this market")
	}

	// Tally votes
	voteCounts := make(map[string]int)
	for _, r := range reveals {
		voteCounts[r.Vote]++
	}
	var consensus string
	maxVotes := 0
	for vote, count := range voteCounts {
		if count > maxVotes {
			maxVotes = count
			consensus = vote
		}
	}
	k.SetOutcome(ctx, msg.MarketId, consensus)
	return &types.MsgFinalizeOutcomeResponse{}, nil
}

// Helper to generate commitment hash
func generateCommitment(vote, nonce string) string {
	data := vote + nonce
	hash := sha256.Sum256([]byte(data))
	return hex.EncodeToString(hash[:])
}

func (k msgServer) UpdateParams(goCtx context.Context, msg *types.MsgUpdateParams) (*types.MsgUpdateParamsResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Check if the signer is the authority
	authorityBytes, err := k.addressCodec.StringToBytes(msg.Authority)
	if err != nil {
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "invalid authority address")
	}
	if string(authorityBytes) != string(k.GetAuthority()) {
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "unauthorized")
	}

	// Set the new params
	k.SetParams(ctx, msg.Params)

	return &types.MsgUpdateParamsResponse{}, nil
}
