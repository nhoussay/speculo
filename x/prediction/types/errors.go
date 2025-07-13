package types

// DONTCOVER

import (
	"cosmossdk.io/errors"
)

// x/prediction module sentinel errors
var (
	ErrInvalidSigner        = errors.Register(ModuleName, 1100, "expected gov account as only signer for proposal message")
	ErrMarketNotFound       = errors.Register(ModuleName, 1101, "market not found")
	ErrInvalidOutcome       = errors.Register(ModuleName, 1102, "invalid outcome index")
	ErrInvalidAmount        = errors.Register(ModuleName, 1103, "invalid amount")
	ErrInsufficientFunds    = errors.Register(ModuleName, 1104, "insufficient funds")
	ErrInsufficientPosition = errors.Register(ModuleName, 1105, "insufficient position to sell")
	ErrTransferFailed       = errors.Register(ModuleName, 1106, "transfer failed")
	ErrPositionUpdateFailed = errors.Register(ModuleName, 1107, "position update failed")
)
