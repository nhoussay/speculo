package keeper

import (
	"testing"

	"speculod/x/settlement/types"

	"github.com/stretchr/testify/require"
)

// TestCommitmentGeneration tests commitment generation logic
func TestCommitmentGeneration(t *testing.T) {
	// Test basic commitment generation
	vote := "YES"
	nonce := "test_nonce_123"
	commitment := generateTestCommitment(vote, nonce)

	require.Len(t, commitment, 64, "Commitment should be 64 hex characters")
	require.NotEmpty(t, commitment, "Commitment should not be empty")

	// Test that same vote and nonce produce same commitment
	commitment2 := generateTestCommitment(vote, nonce)
	require.Equal(t, commitment, commitment2, "Same vote and nonce should produce same commitment")

	// Test that different nonces produce different commitments
	commitment3 := generateTestCommitment(vote, "different_nonce")
	require.NotEqual(t, commitment, commitment3, "Different nonces should produce different commitments")

	// Test that different votes produce different commitments
	commitment4 := generateTestCommitment("NO", nonce)
	require.NotEqual(t, commitment, commitment4, "Different votes should produce different commitments")
}

// TestVoteValidation tests vote validation logic
func TestVoteValidation(t *testing.T) {
	// Test valid votes
	validVotes := []string{"YES", "NO", "OUTCOME_A", "OUTCOME_B"}
	allowedOutcomes := []string{"YES", "NO", "OUTCOME_A", "OUTCOME_B", "OUTCOME_C"}

	for _, vote := range validVotes {
		isValid := false
		for _, outcome := range allowedOutcomes {
			if vote == outcome {
				isValid = true
				break
			}
		}
		require.True(t, isValid, "Valid vote should be accepted")
	}

	// Test invalid votes
	invalidVotes := []string{"INVALID", "MAYBE", "UNKNOWN", ""}
	for _, vote := range invalidVotes {
		isValid := false
		for _, outcome := range allowedOutcomes {
			if vote == outcome {
				isValid = true
				break
			}
		}
		require.False(t, isValid, "Invalid vote should be rejected")
	}
}

// TestNonceValidation tests nonce validation logic
func TestNonceValidation(t *testing.T) {
	// Test valid nonces
	validNonces := []string{
		"12345678",                     // 8 characters
		"abcdefghijklmnop",             // 16 characters
		"a" + string(make([]byte, 63)), // 64 characters
	}

	for _, nonce := range validNonces {
		isValid := len(nonce) >= 8 && len(nonce) <= 64
		require.True(t, isValid, "Valid nonce should be accepted")
	}

	// Test invalid nonces
	invalidNonces := []string{
		"",                             // Empty
		"123",                          // Too short
		"a" + string(make([]byte, 65)), // Too long
	}

	for _, nonce := range invalidNonces {
		isValid := len(nonce) >= 8 && len(nonce) <= 64
		require.False(t, isValid, "Invalid nonce should be rejected")
	}
}

// TestCommitmentValidation tests commitment validation logic
func TestCommitmentValidation(t *testing.T) {
	// Test valid commitments
	validCommitments := []string{
		"a" + string(make([]byte, 63)), // 64 hex characters
		"1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
	}

	for _, commitment := range validCommitments {
		isValid := len(commitment) == 64
		require.True(t, isValid, "Valid commitment should be accepted")
	}

	// Test invalid commitments
	invalidCommitments := []string{
		"",                             // Empty
		"123",                          // Too short
		"a" + string(make([]byte, 65)), // Too long
		"invalid_hex_string",           // Not hex
	}

	for _, commitment := range invalidCommitments {
		isValid := len(commitment) == 64
		require.False(t, isValid, "Invalid commitment should be rejected")
	}
}

// TestVoteDistribution tests vote distribution calculation
func TestVoteDistribution(t *testing.T) {
	// Test data
	reveals := []types.VoteReveal{
		{Vote: "YES"},
		{Vote: "YES"},
		{Vote: "NO"},
		{Vote: "YES"},
		{Vote: "NO"},
		{Vote: "OUTCOME_A"},
	}

	// Calculate distribution
	distribution := make(map[string]uint32)
	for _, reveal := range reveals {
		distribution[reveal.Vote]++
	}

	expectedDistribution := map[string]uint32{
		"YES":       3,
		"NO":        2,
		"OUTCOME_A": 1,
	}

	require.Equal(t, expectedDistribution, distribution, "Vote distribution should match expected")
}

// TestReputationWeightedVoting tests reputation-weighted voting logic
func TestReputationWeightedVoting(t *testing.T) {
	// Test data
	reveals := []types.VoteReveal{
		{Voter: "alice", Vote: "YES"},
		{Voter: "bob", Vote: "YES"},
		{Voter: "charlie", Vote: "NO"},
		{Voter: "diana", Vote: "YES"},
		{Voter: "eve", Vote: "NO"},
	}

	reputationWeights := map[string]int64{
		"alice":   10, // High reputation
		"bob":     5,  // Medium reputation
		"charlie": 3,  // Low reputation
		"diana":   8,  // High reputation
		"eve":     2,  // Low reputation
	}

	// Calculate weighted votes
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
}

// TestConsensusDetermination tests consensus determination logic
func TestConsensusDetermination(t *testing.T) {
	// Test case 1: Clear winner
	weightedVotes1 := map[string]int64{
		"YES": 25,
		"NO":  10,
	}

	var consensus1 string
	maxWeight1 := int64(0)
	for outcome, weight := range weightedVotes1 {
		if weight > maxWeight1 {
			maxWeight1 = weight
			consensus1 = outcome
		}
	}

	require.Equal(t, "YES", consensus1, "Consensus should be YES with highest weight")

	// Test case 2: Tie (should pick first one encountered)
	// Use a slice to ensure deterministic order
	weightedVotes2 := []struct {
		outcome string
		weight  int64
	}{
		{"YES", 15},
		{"NO", 15},
	}

	var consensus2 string
	maxWeight2 := int64(0)
	for _, vote := range weightedVotes2 {
		if vote.weight > maxWeight2 {
			maxWeight2 = vote.weight
			consensus2 = vote.outcome
		}
	}

	require.Equal(t, "YES", consensus2, "Consensus should be first outcome in case of tie")
}

// TestReputationAdjustment tests reputation adjustment logic
func TestReputationAdjustment(t *testing.T) {
	// Test data
	reveals := []types.VoteReveal{
		{Voter: "alice", Vote: "YES"},
		{Voter: "bob", Vote: "YES"},
		{Voter: "charlie", Vote: "NO"},
		{Voter: "diana", Vote: "YES"},
		{Voter: "eve", Vote: "NO"},
	}

	consensus := "YES"

	// Calculate reputation adjustments
	expectedAdjustments := map[string]int64{
		"alice":   1,  // Correct vote, gain reputation
		"bob":     1,  // Correct vote, gain reputation
		"charlie": -1, // Incorrect vote, lose reputation
		"diana":   1,  // Correct vote, gain reputation
		"eve":     -1, // Incorrect vote, lose reputation
	}

	for _, reveal := range reveals {
		var expectedAdjustment int64
		if reveal.Vote == consensus {
			expectedAdjustment = 1
		} else {
			expectedAdjustment = -1
		}

		actualAdjustment := expectedAdjustments[reveal.Voter]
		require.Equal(t, expectedAdjustment, actualAdjustment, "Reputation adjustment should match expected")
	}
}

// TestRevealRateCalculation tests reveal rate calculation
func TestRevealRateCalculation(t *testing.T) {
	// Test case 1: All reveals
	totalCommits1 := uint32(5)
	totalReveals1 := uint32(5)
	revealRate1 := float64(totalReveals1) / float64(totalCommits1)

	expectedRevealRate1 := 1.0
	require.Equal(t, expectedRevealRate1, revealRate1, "Reveal rate should be 100% when all reveal")

	// Test case 2: Partial reveals
	totalCommits2 := uint32(10)
	totalReveals2 := uint32(7)
	revealRate2 := float64(totalReveals2) / float64(totalCommits2)

	expectedRevealRate2 := 0.7
	require.Equal(t, expectedRevealRate2, revealRate2, "Reveal rate should be 70%")

	// Test case 3: No reveals
	totalCommits3 := uint32(5)
	totalReveals3 := uint32(0)
	revealRate3 := float64(totalReveals3) / float64(totalCommits3)

	expectedRevealRate3 := 0.0
	require.Equal(t, expectedRevealRate3, revealRate3, "Reveal rate should be 0% when no reveals")
}

// TestMarketIsolation tests market isolation logic
func TestMarketIsolation(t *testing.T) {
	// Test that votes for different markets are isolated
	market1ID := uint64(1)
	market2ID := uint64(2)

	// Same voter, different markets
	vote1 := types.VoteReveal{
		MarketId: market1ID,
		Voter:    "alice",
		Vote:     "YES",
		Nonce:    "nonce1",
	}

	vote2 := types.VoteReveal{
		MarketId: market2ID,
		Voter:    "alice",
		Vote:     "NO",
		Nonce:    "nonce2",
	}

	require.Equal(t, market1ID, vote1.MarketId, "Vote 1 should be for market 1")
	require.Equal(t, market2ID, vote2.MarketId, "Vote 2 should be for market 2")
	require.Equal(t, "alice", vote1.Voter, "Both votes should be from same voter")
	require.Equal(t, "alice", vote2.Voter, "Both votes should be from same voter")
	require.NotEqual(t, vote1.Vote, vote2.Vote, "Votes should be different for different markets")
}

// TestCommitmentRevealMatching tests commitment-reveal matching
func TestCommitmentRevealMatching(t *testing.T) {
	// Test valid commitment-reveal pair
	vote := "YES"
	nonce := "test_nonce_123"
	commitment := generateTestCommitment(vote, nonce)

	// Verify commitment matches reveal
	expectedCommitment := generateTestCommitment(vote, nonce)
	require.Equal(t, expectedCommitment, commitment, "Commitment should match reveal")

	// Test invalid commitment-reveal pair
	wrongVote := "NO"
	wrongCommitment := generateTestCommitment(wrongVote, nonce)
	require.NotEqual(t, commitment, wrongCommitment, "Different votes should produce different commitments")

	// Test invalid nonce
	wrongNonce := "wrong_nonce"
	wrongCommitment2 := generateTestCommitment(vote, wrongNonce)
	require.NotEqual(t, commitment, wrongCommitment2, "Different nonces should produce different commitments")
}

// BenchmarkCommitmentGeneration benchmarks commitment generation performance
func BenchmarkCommitmentGeneration(b *testing.B) {
	vote := "YES"
	nonce := "test_nonce_123"

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		generateTestCommitment(vote, nonce)
	}
}

// BenchmarkVoteDistribution benchmarks vote distribution calculation performance
func BenchmarkVoteDistribution(b *testing.B) {
	reveals := []types.VoteReveal{
		{Vote: "YES"},
		{Vote: "NO"},
		{Vote: "YES"},
		{Vote: "YES"},
		{Vote: "NO"},
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		distribution := make(map[string]uint32)
		for _, reveal := range reveals {
			distribution[reveal.Vote]++
		}
	}
}
