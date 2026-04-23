// Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
// This program comes with ABSOLUTELY NO WARRANTY.
// See <https://gnu.org> for details.

package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"go.uber.org/zap"

	c "github.com/jolyne-nyah/bridge_updater/core/config"
	l "github.com/jolyne-nyah/bridge_updater/core/logger"
)

func processSpecificFlags(reposOnly bool, directOnly bool) (bool, bool, error) {
	if reposOnly && directOnly {
		return false, false, fmt.Errorf("cannot use --repos-only and --direct-only flags together")
	}

	if !reposOnly && !directOnly {
		return true, true, nil
	}

	return reposOnly, directOnly, nil
}

func main() {

	if os.Geteuid() != 0 {
		fmt.Println("This command must be run as root.")
		os.Exit(1)
	}

	var configPath string
	var logLevelStr string

	var rootCmd = &cobra.Command{Use: "bridge_updater"}

	rootCmd.PersistentFlags().StringVarP(&configPath, "config", "c", "config.json", "Path to the configuration file")
	rootCmd.PersistentFlags().StringVarP(&logLevelStr, "loglevel", "l", "info", "Log level (debug, info, error)")

	var reposOnly bool
	var directOnly bool
	var ignoreInternetReachabilityTests bool
	var doNotReloadTor bool

	rootCmd.PersistentFlags().BoolVarP(&reposOnly, "repos-only", "r", false, "Run only the repos fetching/writing")
	rootCmd.PersistentFlags().BoolVarP(&directOnly, "direct-only", "d", false, "Run only the direct fetching/writing")
	rootCmd.PersistentFlags().BoolVarP(&ignoreInternetReachabilityTests, "ignore-internet-reachability-tests", "i", false, "Ignore internet reachability tests")
	rootCmd.PersistentFlags().BoolVarP(&doNotReloadTor, "no-tor-reload", "t", false, "Do not reload Tor after updating the bridges")

	var logger *zap.Logger
	var config *c.Config
	var runner *Runner

	var runRepos bool
	var runDirect bool

	rootCmd.PersistentPreRunE = func(cmd *cobra.Command, args []string) error {

		var err error

		runRepos, runDirect, err = processSpecificFlags(reposOnly, directOnly)

		if err != nil {
			fmt.Printf("Error processing flags: %v\n", err)
			os.Exit(1)
		}

		logger, err = l.InitLogger(logLevelStr)

		if err != nil {
			fmt.Printf("Failed to initialize logger: %v\n", err)
			os.Exit(1)
		}

		config, err = c.LoadConfig(configPath, logger)

		if err != nil {
			logger.Error("Failed to load configuration", zap.String("path", configPath), zap.Error(err))
			os.Exit(1)
		}

		runner = NewRunner(runRepos, runDirect, ignoreInternetReachabilityTests, config)

		return nil
	}

	var fetchCmd = &cobra.Command{
		Use:   "fetch",
		Short: "Fetch the latest bridge information",
		Run: func(cmd *cobra.Command, args []string) {
			if doNotReloadTor {
				logger.Warn(" --no-tor-reload flag is set, but will be ignored while running one of the following commands: check, fetch")
			}

			if err := runner.Fetch(false, logger); err != nil {
				os.Exit(1)
			}
		},
	}

	var writeCmd = &cobra.Command{
		Use:   "write",
		Short: "Write the fetched information to the output file",
		Run: func(cmd *cobra.Command, args []string) {
			if err := runner.Write(false, doNotReloadTor, logger); err != nil {
				os.Exit(1)
			}
		},
	}

	updateCmd := &cobra.Command{
		Use:   "update",
		Short: "Fetch the latest bridge info and write it to file",
		Run: func(cmd *cobra.Command, args []string) {
			if err := runner.FullRun(doNotReloadTor, logger); err != nil {
				os.Exit(1)
			}
		},
	}

	checkCmd := &cobra.Command{
		Use:   "check",
		Short: "Check the configuration file for errors",
		Run: func(cmd *cobra.Command, args []string) {
			if doNotReloadTor {
				logger.Warn(" --no-tor-reload flag is set, but will be ignored while running one of the following commands: check, fetch")
			}

			if reposOnly || directOnly {
				logger.Warn(" --repos-only and --direct-only flags are ignored when running the check command")
			}

			if err := runner.CommonCheck(!runner.ignoreInternetReachabilityTests, logger); err != nil {
				os.Exit(1)
			}
		},
	}

	rootCmd.AddCommand(updateCmd, fetchCmd, writeCmd, checkCmd)

	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}

	if logger != nil {
		_ = logger.Sync()
	}
}
