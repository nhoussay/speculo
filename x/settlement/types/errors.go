package types

// DONTCOVER

import (
	errorsmod "cosmossdk.io/errors"
)

var (
	ErrInvalidRequest             = errorsmod.Register(ModuleName, 1, "invalid request")
	ErrMarketNotFound             = errorsmod.Register(ModuleName, 2, "market not found")
	ErrMarketNotReady             = errorsmod.Register(ModuleName, 3, "market not ready for settlement")
	ErrInvalidVote                = errorsmod.Register(ModuleName, 4, "invalid vote for market outcomes")
	ErrCommitmentMismatch         = errorsmod.Register(ModuleName, 5, "commitment does not match reveal")
	ErrAlreadyCommitted           = errorsmod.Register(ModuleName, 6, "user already committed a vote")
	ErrAlreadyRevealed            = errorsmod.Register(ModuleName, 7, "user already revealed their vote")
	ErrNoCommitmentFound          = errorsmod.Register(ModuleName, 8, "no commitment found for this user")
	ErrOutcomeAlreadyFinalized    = errorsmod.Register(ModuleName, 9, "outcome already finalized")
	ErrNoRevealsFound             = errorsmod.Register(ModuleName, 10, "no reveals found for this market")
	ErrInvalidNonce               = errorsmod.Register(ModuleName, 11, "invalid nonce")
	ErrReputationAdjustmentFailed = errorsmod.Register(ModuleName, 12, "reputation adjustment failed")
)
