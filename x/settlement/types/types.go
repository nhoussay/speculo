// File: x/settlement/types/types.go
package types

import (
	"fmt"
)

type Commit struct {
	Voter      string `json:"voter" yaml:"voter"`
	MarketId   uint64 `json:"market_id" yaml:"market_id"`
	Commitment string `json:"commitment" yaml:"commitment"`
}

type Reveal struct {
	Voter    string `json:"voter" yaml:"voter"`
	MarketId uint64 `json:"market_id" yaml:"market_id"`
	Vote     string `json:"vote" yaml:"vote"`
	Nonce    string `json:"nonce" yaml:"nonce"`
}

type FinalOutcome struct {
	MarketId uint64 `json:"market_id" yaml:"market_id"`
	Outcome  string `json:"outcome" yaml:"outcome"`
}

// SettlementStats contains statistics about the settlement process
type SettlementStats struct {
	MarketId     uint64  `json:"market_id" yaml:"market_id"`
	TotalCommits uint32  `json:"total_commits" yaml:"total_commits"`
	TotalReveals uint32  `json:"total_reveals" yaml:"total_reveals"`
	RevealRate   float64 `json:"reveal_rate" yaml:"reveal_rate"`
	UniqueVoters uint32  `json:"unique_voters" yaml:"unique_voters"`
}

func (c Commit) Key() []byte {
	return []byte(fmt.Sprintf("commit:%d:%s", c.MarketId, c.Voter))
}

func (r Reveal) Key() []byte {
	return []byte(fmt.Sprintf("reveal:%d:%s", r.MarketId, r.Voter))
}

func (f FinalOutcome) Key() []byte {
	return []byte(fmt.Sprintf("final:%d", f.MarketId))
}
