package keeper_test

import (
	"context"
	"testing"

	"cosmossdk.io/core/address"
	storetypes "cosmossdk.io/store/types"
	addresscodec "github.com/cosmos/cosmos-sdk/codec/address"
	"github.com/cosmos/cosmos-sdk/runtime"
	"github.com/cosmos/cosmos-sdk/testutil"
	sdk "github.com/cosmos/cosmos-sdk/types"
	moduletestutil "github.com/cosmos/cosmos-sdk/types/module/testutil"
	authtypes "github.com/cosmos/cosmos-sdk/x/auth/types"

	"speculod/x/reputation/keeper"
	module "speculod/x/reputation/module"
	"speculod/x/reputation/types"
)

type fixture struct {
	ctx          context.Context
	keeper       keeper.Keeper
	addressCodec address.Codec
}

func initFixture(t *testing.T) *fixture {
	t.Helper()

	encCfg := moduletestutil.MakeTestEncodingConfig(module.AppModule{})
	addressCodec := addresscodec.NewBech32Codec(sdk.GetConfig().GetBech32AccountAddrPrefix())
	storeKey := storetypes.NewKVStoreKey(types.StoreKey)

	storeService := runtime.NewKVStoreService(storeKey)
	ctx := testutil.DefaultContextWithDB(t, storeKey, storetypes.NewTransientStoreKey("transient_test")).Ctx

	authority := authtypes.NewModuleAddress(types.GovModuleName)

	k := keeper.NewKeeper(
		storeService,
		encCfg.Codec,
		addressCodec,
		authority,
	)

	// Initialize params
	if err := k.Params.Set(ctx, types.DefaultParams()); err != nil {
		t.Fatalf("failed to set params: %v", err)
	}

	return &fixture{
		ctx:          ctx,
		keeper:       k,
		addressCodec: addressCodec,
	}
}

func TestMsgAdjustScore(t *testing.T) {
	f := initFixture(t)
	msgServer := keeper.NewMsgServerImpl(f.keeper)
	ctx := f.ctx

	userAddr := "cosmos1useraddress000000000000000000000000000000000000"
	groupId := "test-group"
	correctAuthority := f.keeper.GetAuthority()
	correctAuthorityStr, _ := f.addressCodec.BytesToString(correctAuthority)
	wrongAuthority := "cosmos1wronga00000000000000000000000000000000000"

	t.Run("adjust score with correct authority", func(t *testing.T) {
		msg := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    groupId,
			Adjustment: 5,
			Authority:  correctAuthorityStr,
		}
		_, err := msgServer.AdjustScore(ctx, msg)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}
		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		if !found || score != "5" {
			t.Errorf("expected score 5, got %v", score)
		}
	})

	t.Run("adjust score with wrong authority", func(t *testing.T) {
		msg := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    groupId,
			Adjustment: 3,
			Authority:  wrongAuthority,
		}
		_, err := msgServer.AdjustScore(ctx, msg)
		if err == nil {
			t.Fatalf("expected error for wrong authority, got nil")
		}
	})

	t.Run("negative adjustment does not go below zero", func(t *testing.T) {
		msg := &types.MsgAdjustScore{
			Address:    userAddr,
			GroupId:    groupId,
			Adjustment: -10,
			Authority:  correctAuthorityStr,
		}
		_, err := msgServer.AdjustScore(ctx, msg)
		if err != nil {
			t.Fatalf("expected no error, got %v", err)
		}
		score, found := f.keeper.GetReputationScore(ctx.(sdk.Context), userAddr, groupId)
		if !found || score != "0" {
			t.Errorf("expected score 0, got %v", score)
		}
	})
}
