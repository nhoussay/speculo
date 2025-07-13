package keeper_test

import (
	"testing"

	"speculod/x/settlement/types"

	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/stretchr/testify/require"
)

func TestGenesis(t *testing.T) {
	genesisState := types.GenesisState{
		Params: types.DefaultParams(),
	}

	f := initFixture(t)
	ctx := sdk.UnwrapSDKContext(f.ctx)
	err := f.keeper.InitGenesis(ctx, genesisState)
	require.NoError(t, err)
	got, err := f.keeper.ExportGenesis(ctx)
	require.NoError(t, err)
	require.NotNil(t, got)

	require.EqualExportedValues(t, genesisState.Params, got.Params)
}
