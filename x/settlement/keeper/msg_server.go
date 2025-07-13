package keeper

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"strconv"

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

	// Validate market exists and is ready for settlement
	market, found := k.predictionKeeper.GetPredictionMarket(ctx, msg.MarketId)
	if !found {
		return nil, sdkerrors.Wrap(types.ErrMarketNotFound, "market not found")
	}

	// Check if market is ready for settlement (past deadline)
	deadline := market.Deadline

	if deadline > 0 && ctx.BlockTime().Unix() < deadline {
		return nil, sdkerrors.Wrap(types.ErrMarketNotReady, "market not ready for settlement")
	}

	// Prevent double-commit
	_, found = k.GetCommit(ctx, msg.MarketId, msg.Creator)
	if found {
		return nil, sdkerrors.Wrap(types.ErrAlreadyCommitted, "user already committed a vote")
	}

	// Validate commitment format (should be a valid hex string)
	if len(msg.Commitment) != 64 { // SHA256 hash is 64 hex characters
		return nil, sdkerrors.Wrap(types.ErrInvalidRequest, "invalid commitment format")
	}

	commit := types.VoteCommit{
		MarketId:   msg.MarketId,
		Voter:      msg.Creator,
		Commitment: msg.Commitment,
	}
	k.SetCommit(ctx, commit)

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			"vote_committed",
			sdk.NewAttribute("market_id", strconv.FormatUint(msg.MarketId, 10)),
			sdk.NewAttribute("voter", msg.Creator),
		),
	)

	return &types.MsgCommitVoteResponse{}, nil
}

func (k msgServer) RevealVote(goCtx context.Context, msg *types.MsgRevealVote) (*types.MsgRevealVoteResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Check if user has committed
	commit, found := k.GetCommit(ctx, msg.MarketId, msg.Creator)
	if !found {
		return nil, sdkerrors.Wrap(types.ErrNoCommitmentFound, "no commitment found for this user")
	}

	// Validate commitment matches reveal
	expectedCommitment := generateCommitment(msg.Vote, msg.Nonce)
	if commit.Commitment != expectedCommitment {
		return nil, sdkerrors.Wrap(types.ErrCommitmentMismatch, "commitment does not match reveal")
	}

	// Check if already revealed
	_, alreadyRevealed := k.GetReveal(ctx, msg.MarketId, msg.Creator)
	if alreadyRevealed {
		return nil, sdkerrors.Wrap(types.ErrAlreadyRevealed, "user already revealed their vote")
	}

	// Validate vote against market outcomes
	market, found := k.predictionKeeper.GetPredictionMarket(ctx, msg.MarketId)
	if !found {
		return nil, sdkerrors.Wrap(types.ErrMarketNotFound, "market not found")
	}

	// Get market outcomes for validation
	outcomes := market.Outcomes

	if len(outcomes) > 0 {
		if err := k.predictionKeeper.ValidateOutcome(outcomes, msg.Vote); err != nil {
			return nil, sdkerrors.Wrap(types.ErrInvalidVote, "invalid vote for market outcomes")
		}
	}

	// Validate nonce (should be a reasonable length)
	if len(msg.Nonce) < 8 || len(msg.Nonce) > 64 {
		return nil, sdkerrors.Wrap(types.ErrInvalidNonce, "invalid nonce length")
	}

	reveal := types.VoteReveal{
		MarketId: msg.MarketId,
		Voter:    msg.Creator,
		Vote:     msg.Vote,
		Nonce:    msg.Nonce,
	}
	k.SetReveal(ctx, reveal)

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			"vote_revealed",
			sdk.NewAttribute("market_id", strconv.FormatUint(msg.MarketId, 10)),
			sdk.NewAttribute("voter", msg.Creator),
			sdk.NewAttribute("vote", msg.Vote),
		),
	)

	return &types.MsgRevealVoteResponse{}, nil
}

func (k msgServer) FinalizeOutcome(goCtx context.Context, msg *types.MsgFinalizeOutcome) (*types.MsgFinalizeOutcomeResponse, error) {
	ctx := sdk.UnwrapSDKContext(goCtx)

	// Prevent double-finalization
	_, found := k.GetOutcome(ctx, msg.MarketId)
	if found {
		return nil, sdkerrors.Wrap(types.ErrOutcomeAlreadyFinalized, "outcome already finalized")
	}

	// Validate market exists
	market, found := k.predictionKeeper.GetPredictionMarket(ctx, msg.MarketId)
	if !found {
		return nil, sdkerrors.Wrap(types.ErrMarketNotFound, "market not found")
	}

	// Get market data for group ID
	groupId := market.GroupId

	// Get all reveals for this market
	reveals := k.GetAllReveals(ctx, msg.MarketId)
	if len(reveals) == 0 {
		return nil, sdkerrors.Wrap(types.ErrNoRevealsFound, "no reveals found for this market")
	}

	// Calculate reputation-weighted votes
	voteWeights := k.GetReputationWeightedVotes(ctx, msg.MarketId, groupId)

	// Find the outcome with the highest weighted votes
	var consensus string
	maxWeight := int64(0)
	for outcome, weight := range voteWeights {
		if weight > maxWeight {
			maxWeight = weight
			consensus = outcome
		}
	}

	// Set the final outcome
	k.SetOutcome(ctx, msg.MarketId, consensus)

	// Update reputation scores based on voting accuracy
	k.updateReputationScores(ctx, msg.MarketId, groupId, consensus, reveals)

	// Emit event
	ctx.EventManager().EmitEvent(
		sdk.NewEvent(
			"outcome_finalized",
			sdk.NewAttribute("market_id", strconv.FormatUint(msg.MarketId, 10)),
			sdk.NewAttribute("final_outcome", consensus),
			sdk.NewAttribute("total_votes", strconv.Itoa(len(reveals))),
		),
	)

	return &types.MsgFinalizeOutcomeResponse{}, nil
}

// updateReputationScores adjusts reputation scores based on voting accuracy
func (k msgServer) updateReputationScores(ctx sdk.Context, marketId uint64, groupId string, finalOutcome string, reveals []types.VoteReveal) {
	for _, reveal := range reveals {
		var adjustment int64

		if reveal.Vote == finalOutcome {
			// Correct vote - increase reputation
			adjustment = 1
		} else {
			// Incorrect vote - decrease reputation
			adjustment = -1
		}

		// Apply reputation adjustment
		if err := k.reputationKeeper.AdjustReputationScore(ctx, reveal.Voter, groupId, adjustment); err != nil {
			// Log error but don't fail the transaction
			ctx.Logger().Error("failed to adjust reputation score", "error", err.Error())
		}
	}
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
