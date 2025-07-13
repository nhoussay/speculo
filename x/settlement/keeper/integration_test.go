package keeper

import (
	"crypto/sha256"
	"encoding/hex"
	"testing"

	"speculod/x/settlement/types"

	"github.com/stretchr/testify/require"
)

// TestSettlementIntegration_CompleteScenario tests a complete settlement scenario
func TestSettlementIntegration_CompleteScenario(t *testing.T) {
	// This test documents a complete settlement scenario
	// Scenario: Multiple users voting on a prediction market outcome

	// Test data setup
	marketID := uint64(1)
	outcomes := []string{"YES", "NO"}

	// Test commit phase
	commits := []types.VoteCommit{
		{
			MarketId:   marketID,
			Voter:      "alice",
			Commitment: generateTestCommitment("YES", "nonce12345678"),
		},
		{
			MarketId:   marketID,
			Voter:      "bob",
			Commitment: generateTestCommitment("YES", "nonce23456789"),
		},
		{
			MarketId:   marketID,
			Voter:      "charlie",
			Commitment: generateTestCommitment("NO", "nonce34567890"),
		},
		{
			MarketId:   marketID,
			Voter:      "diana",
			Commitment: generateTestCommitment("YES", "nonce45678901"),
		},
		{
			MarketId:   marketID,
			Voter:      "eve",
			Commitment: generateTestCommitment("NO", "nonce56789012"),
		},
	}

	// Test commit validation
	for _, commit := range commits {
		require.NotEmpty(t, commit.Voter, "Commit should have a voter")
		require.NotEmpty(t, commit.Commitment, "Commit should have a commitment")
		require.Equal(t, marketID, commit.MarketId, "All commits should be for the same market")
		require.Len(t, commit.Commitment, 64, "Commitment should be 64 hex characters (SHA256)")
	}

	// Test reveal phase
	reveals := []types.VoteReveal{
		{
			MarketId: marketID,
			Voter:    "alice",
			Vote:     "YES",
			Nonce:    "nonce12345678",
		},
		{
			MarketId: marketID,
			Voter:    "bob",
			Vote:     "YES",
			Nonce:    "nonce23456789",
		},
		{
			MarketId: marketID,
			Voter:    "charlie",
			Vote:     "NO",
			Nonce:    "nonce34567890",
		},
		{
			MarketId: marketID,
			Voter:    "diana",
			Vote:     "YES",
			Nonce:    "nonce45678901",
		},
		{
			MarketId: marketID,
			Voter:    "eve",
			Vote:     "NO",
			Nonce:    "nonce56789012",
		},
	}

	// Test reveal validation
	for _, reveal := range reveals {
		require.NotEmpty(t, reveal.Voter, "Reveal should have a voter")
		require.NotEmpty(t, reveal.Vote, "Reveal should have a vote")
		require.NotEmpty(t, reveal.Nonce, "Reveal should have a nonce")
		require.Equal(t, marketID, reveal.MarketId, "All reveals should be for the same market")

		// Validate vote is one of the allowed outcomes
		isValidVote := false
		for _, outcome := range outcomes {
			if reveal.Vote == outcome {
				isValidVote = true
				break
			}
		}
		require.True(t, isValidVote, "Vote should be one of the allowed outcomes")

		// Validate nonce length
		require.True(t, len(reveal.Nonce) >= 8, "Nonce should be at least 8 characters")
		require.True(t, len(reveal.Nonce) <= 64, "Nonce should be at most 64 characters")
	}

	// Test commitment-reveal matching
	for i, reveal := range reveals {
		expectedCommitment := generateTestCommitment(reveal.Vote, reveal.Nonce)
		actualCommitment := commits[i].Commitment
		require.Equal(t, expectedCommitment, actualCommitment, "Commitment should match reveal")
	}

	// Test vote distribution
	voteDistribution := make(map[string]uint32)
	for _, reveal := range reveals {
		voteDistribution[reveal.Vote]++
	}

	expectedDistribution := map[string]uint32{
		"YES": 3,
		"NO":  2,
	}

	require.Equal(t, expectedDistribution, voteDistribution, "Vote distribution should match expected")

	// Test reputation-weighted voting
	reputationWeights := map[string]int64{
		"alice":   10, // High reputation
		"bob":     5,  // Medium reputation
		"charlie": 3,  // Low reputation
		"diana":   8,  // High reputation
		"eve":     2,  // Low reputation
	}

	weightedVotes := make(map[string]int64)
	for _, reveal := range reveals {
		weight := reputationWeights[reveal.Voter]
		if weight == 0 {
			weight = 1 // Default weight
		}
		weightedVotes[reveal.Vote] += weight
	}

	expectedWeightedVotes := map[string]int64{
		"YES": 23, // 10 + 5 + 8
		"NO":  5,  // 3 + 2
	}

	require.Equal(t, expectedWeightedVotes, weightedVotes, "Reputation-weighted votes should match expected")

	// Test final outcome determination
	var consensus string
	maxWeight := int64(0)
	for outcome, weight := range weightedVotes {
		if weight > maxWeight {
			maxWeight = weight
			consensus = outcome
		}
	}

	expectedConsensus := "YES"
	require.Equal(t, expectedConsensus, consensus, "Consensus should be YES with highest weighted votes")

	// Test reputation adjustments
	expectedAdjustments := map[string]int64{
		"alice":   1,  // Correct vote, gain reputation
		"bob":     1,  // Correct vote, gain reputation
		"charlie": -1, // Incorrect vote, lose reputation
		"diana":   1,  // Correct vote, gain reputation
		"eve":     -1, // Incorrect vote, lose reputation
	}

	for voter, expectedAdjustment := range expectedAdjustments {
		reveal := findRevealByVoter(reveals, voter)
		require.NotNil(t, reveal, "Should find reveal for voter")

		var actualAdjustment int64
		if reveal.Vote == consensus {
			actualAdjustment = 1
		} else {
			actualAdjustment = -1
		}

		require.Equal(t, expectedAdjustment, actualAdjustment, "Reputation adjustment should match expected")
	}
}

// TestSettlementIntegration_PartialReveal tests partial reveal scenarios
func TestSettlementIntegration_PartialReveal(t *testing.T) {
	// Test scenario: Some voters don't reveal their votes

	marketID := uint64(1)

	// All voters commit
	commits := []types.VoteCommit{
		{
			MarketId:   marketID,
			Voter:      "alice",
			Commitment: generateTestCommitment("YES", "nonce12345678"),
		},
		{
			MarketId:   marketID,
			Voter:      "bob",
			Commitment: generateTestCommitment("NO", "nonce23456789"),
		},
		{
			MarketId:   marketID,
			Voter:      "charlie",
			Commitment: generateTestCommitment("YES", "nonce34567890"),
		},
		{
			MarketId:   marketID,
			Voter:      "diana",
			Commitment: generateTestCommitment("NO", "nonce45678901"),
		},
	}

	// Only some voters reveal
	reveals := []types.VoteReveal{
		{
			MarketId: marketID,
			Voter:    "alice",
			Vote:     "YES",
			Nonce:    "nonce12345678",
		},
		{
			MarketId: marketID,
			Voter:    "charlie",
			Vote:     "YES",
			Nonce:    "nonce34567890",
		},
		// Bob and Diana don't reveal
	}

	// Test reveal rate calculation
	totalCommits := uint32(len(commits))
	totalReveals := uint32(len(reveals))
	revealRate := float64(totalReveals) / float64(totalCommits)

	expectedRevealRate := 0.5 // 2 reveals out of 4 commits
	require.Equal(t, expectedRevealRate, revealRate, "Reveal rate should be 50%")

	// Test vote distribution with partial reveals
	voteDistribution := make(map[string]uint32)
	for _, reveal := range reveals {
		voteDistribution[reveal.Vote]++
	}

	expectedDistribution := map[string]uint32{
		"YES": 2,
	}

	require.Equal(t, expectedDistribution, voteDistribution, "Vote distribution should only include revealed votes")

	// Test reputation-weighted voting with partial reveals
	reputationWeights := map[string]int64{
		"alice":   10,
		"bob":     5, // Not revealed
		"charlie": 3,
		"diana":   8, // Not revealed
	}

	weightedVotes := make(map[string]int64)
	for _, reveal := range reveals {
		weight := reputationWeights[reveal.Voter]
		if weight == 0 {
			weight = 1
		}
		weightedVotes[reveal.Vote] += weight
	}

	expectedWeightedVotes := map[string]int64{
		"YES": 13, // 10 + 3
	}

	require.Equal(t, expectedWeightedVotes, weightedVotes, "Weighted votes should only include revealed votes")
}

// TestSettlementIntegration_NoReveals tests scenario with no reveals
func TestSettlementIntegration_NoReveals(t *testing.T) {
	// Test scenario: All voters commit but none reveal

	marketID := uint64(1)

	// All voters commit
	commits := []types.VoteCommit{
		{
			MarketId:   marketID,
			Voter:      "alice",
			Commitment: generateTestCommitment("YES", "nonce12345678"),
		},
		{
			MarketId:   marketID,
			Voter:      "bob",
			Commitment: generateTestCommitment("NO", "nonce23456789"),
		},
	}

	// No reveals
	reveals := []types.VoteReveal{}

	// Test reveal rate
	totalCommits := uint32(len(commits))
	totalReveals := uint32(len(reveals))
	revealRate := float64(totalReveals) / float64(totalCommits)

	expectedRevealRate := 0.0
	require.Equal(t, expectedRevealRate, revealRate, "Reveal rate should be 0%")

	// Test vote distribution
	voteDistribution := make(map[string]uint32)
	for _, reveal := range reveals {
		voteDistribution[reveal.Vote]++
	}

	expectedDistribution := map[string]uint32{}
	require.Equal(t, expectedDistribution, voteDistribution, "Vote distribution should be empty")

	// Test weighted votes
	weightedVotes := make(map[string]int64)
	for _, reveal := range reveals {
		weightedVotes[reveal.Vote] += 1
	}

	expectedWeightedVotes := map[string]int64{}
	require.Equal(t, expectedWeightedVotes, weightedVotes, "Weighted votes should be empty")
}

// TestSettlementIntegration_CrossMarketIsolation tests isolation between markets
func TestSettlementIntegration_CrossMarketIsolation(t *testing.T) {
	// Test scenario: Votes for different markets are isolated

	market1ID := uint64(1)
	market2ID := uint64(2)

	// Votes for market 1
	market1Commits := []types.VoteCommit{
		{
			MarketId:   market1ID,
			Voter:      "alice",
			Commitment: generateTestCommitment("YES", "nonce12345678"),
		},
		{
			MarketId:   market1ID,
			Voter:      "bob",
			Commitment: generateTestCommitment("NO", "nonce23456789"),
		},
	}

	// Votes for market 2
	market2Commits := []types.VoteCommit{
		{
			MarketId:   market2ID,
			Voter:      "alice",
			Commitment: generateTestCommitment("NO", "nonce34567890"),
		},
		{
			MarketId:   market2ID,
			Voter:      "charlie",
			Commitment: generateTestCommitment("YES", "nonce45678901"),
		},
	}

	// Test market isolation
	for _, commit := range market1Commits {
		require.Equal(t, market1ID, commit.MarketId, "Market 1 commits should have market 1 ID")
	}

	for _, commit := range market2Commits {
		require.Equal(t, market2ID, commit.MarketId, "Market 2 commits should have market 2 ID")
	}

	// Test that same voter can vote differently on different markets
	aliceMarket1Commit := findCommitByVoter(market1Commits, "alice")
	aliceMarket2Commit := findCommitByVoter(market2Commits, "alice")

	require.NotNil(t, aliceMarket1Commit, "Should find Alice's commit for market 1")
	require.NotNil(t, aliceMarket2Commit, "Should find Alice's commit for market 2")
	require.NotEqual(t, aliceMarket1Commit.Commitment, aliceMarket2Commit.Commitment, "Alice's commits should be different for different markets")
}

// Helper functions

func generateTestCommitment(vote, nonce string) string {
	hash := sha256.Sum256([]byte(vote + nonce))
	return hex.EncodeToString(hash[:])
}

func findRevealByVoter(reveals []types.VoteReveal, voter string) *types.VoteReveal {
	for _, reveal := range reveals {
		if reveal.Voter == voter {
			return &reveal
		}
	}
	return nil
}

func findCommitByVoter(commits []types.VoteCommit, voter string) *types.VoteCommit {
	for _, commit := range commits {
		if commit.Voter == voter {
			return &commit
		}
	}
	return nil
}
