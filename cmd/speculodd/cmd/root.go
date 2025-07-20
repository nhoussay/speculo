package cmd

import (
	"os"

	"speculod/app"

	"cosmossdk.io/client/v2/autocli"
	"cosmossdk.io/depinject"
	"cosmossdk.io/log"
	txsigning "cosmossdk.io/x/tx/signing"
	"github.com/cosmos/cosmos-sdk/client"
	clientconfig "github.com/cosmos/cosmos-sdk/client/config"
	"github.com/cosmos/cosmos-sdk/codec"
	addresscodec "github.com/cosmos/cosmos-sdk/codec/address"
	codectypes "github.com/cosmos/cosmos-sdk/codec/types"
	"github.com/cosmos/cosmos-sdk/server"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/module"
	"github.com/cosmos/cosmos-sdk/x/auth/tx"
	authtxconfig "github.com/cosmos/cosmos-sdk/x/auth/tx/config"
	"github.com/cosmos/cosmos-sdk/x/auth/types"
	"github.com/cosmos/cosmos-sdk/x/genutil/client/cli"
	genutiltypes "github.com/cosmos/cosmos-sdk/x/genutil/types"
	"github.com/spf13/cobra"
)

// NewRootCmd creates a new root command for speculodd. It is called once in the main function.
func NewRootCmd() *cobra.Command {
	// Set the Bech32 address prefix globally.
	// This must be done before any commands are created.
	sdkConfig := sdk.GetConfig()
	sdkConfig.SetBech32PrefixForAccount("speculo", "speculopub")
	sdkConfig.SetBech32PrefixForValidator("speculovaloper", "speculovaloperpub")
	sdkConfig.SetBech32PrefixForConsensusNode("speculovalcons", "speculovalconspub")
	sdkConfig.Seal()

	var (
		autoCliOpts        autocli.AppOptions
		moduleBasicManager module.BasicManager
		clientCtx          client.Context
	)

	if err := depinject.Inject(
		depinject.Configs(app.AppConfig(),
			depinject.Supply(log.NewNopLogger()),
			depinject.Provide(
				ProvideClientContext,
			),
		),
		&autoCliOpts,
		&moduleBasicManager,
		&clientCtx,
	); err != nil {
		panic(err)
	}

	rootCmd := &cobra.Command{
		Use:           app.Name + "d",
		Short:         "speculod node",
		SilenceErrors: true,
		PersistentPreRunE: func(cmd *cobra.Command, _ []string) error {
			// set the default command outputs
			cmd.SetOut(cmd.OutOrStdout())
			cmd.SetErr(cmd.OutOrStderr())

			clientCtx = clientCtx.WithCmdContext(cmd.Context()).WithViper(app.Name)
			clientCtx, err := client.ReadPersistentCommandFlags(clientCtx, cmd.Flags())
			if err != nil {
				return err
			}

			// Use the aliased import here
			clientCtx, err = clientconfig.ReadFromClientConfig(clientCtx)
			if err != nil {
				return err
			}

			if err := client.SetCmdClientContextHandler(clientCtx, cmd); err != nil {
				return err
			}

			customAppTemplate, customAppConfig := initAppConfig()
			customCMTConfig := initCometBFTConfig()

			return server.InterceptConfigsPreRunHandler(cmd, customAppTemplate, customAppConfig, customCMTConfig)
		},
	}

	// Register IBC modules if needed
	ibcModules := app.RegisterIBC(clientCtx.Codec)
	for name, mod := range ibcModules {
		moduleBasicManager[name] = module.CoreAppModuleBasicAdaptor(name, mod)
		autoCliOpts.Modules[name] = mod
	}

	initRootCmd(rootCmd, clientCtx.TxConfig, moduleBasicManager)

	// --- Register legacy genesis commands ---
	// The genesis commands now require passing the address codec explicitly with the correct prefix.
	addrCodec := addresscodec.NewBech32Codec("speculo")
	valCodec := addresscodec.NewBech32Codec("speculovaloper")
	rootCmd.AddCommand(
		cli.InitCmd(moduleBasicManager, app.DefaultNodeHome),
		cli.CollectGenTxsCmd(app.GenesisBalancesIterator{}, app.DefaultNodeHome, genutiltypes.DefaultMessageValidator, addrCodec),
		cli.GenTxCmd(
			moduleBasicManager,
			clientCtx.TxConfig,
			app.GenesisBalancesIterator{},
			app.DefaultNodeHome,
			valCodec,
		),
		cli.ValidateGenesisCmd(moduleBasicManager),
		cli.AddGenesisAccountCmd(app.DefaultNodeHome, addrCodec),
	)

	if err := autoCliOpts.EnhanceRootCommand(rootCmd); err != nil {
		panic(err)
	}

	return rootCmd
}

// ProvideClientContext creates and provides a fully initialized client.Context,
// allowing it to be used for dependency injection and CLI operations.
func ProvideClientContext(
	appCodec codec.Codec,
	interfaceRegistry codectypes.InterfaceRegistry,
	txConfigOpts tx.ConfigOptions,
	legacyAmino *codec.LegacyAmino,
) client.Context {
	// Explicitly set the signing options to use the correct prefixes
	if txConfigOpts.SigningOptions == nil {
		txConfigOpts.SigningOptions = &txsigning.Options{
			FileResolver:          interfaceRegistry,
			AddressCodec:          addresscodec.NewBech32Codec("speculo"),
			ValidatorAddressCodec: addresscodec.NewBech32Codec("speculovaloper"),
		}
	}

	clientCtx := client.Context{}.
		WithCodec(appCodec).
		WithInterfaceRegistry(interfaceRegistry).
		WithLegacyAmino(legacyAmino).
		WithInput(os.Stdin).
		WithAccountRetriever(types.AccountRetriever{}).
		WithHomeDir(app.DefaultNodeHome).
		WithViper(app.Name) // env variable prefix

	// Read the config again to overwrite the default values with the values from the config file
	clientCtx, _ = clientconfig.ReadFromClientConfig(clientCtx)

	// textual is enabled by default, we need to re-create the tx config grpc instead of bank keeper.
	txConfigOpts.TextualCoinMetadataQueryFn = authtxconfig.NewGRPCCoinMetadataQueryFn(clientCtx)
	txConfig, err := tx.NewTxConfigWithOptions(clientCtx.Codec, txConfigOpts)
	if err != nil {
		panic(err)
	}
	clientCtx = clientCtx.WithTxConfig(txConfig)

	return clientCtx
}
