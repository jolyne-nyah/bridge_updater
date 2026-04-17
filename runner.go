// Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
// This program comes with ABSOLUTELY NO WARRANTY.
// See <https://gnu.org> for details.

package main

import (
	"fmt"

	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"

	a "github.com/jolyne-nyah/bridge_updater/actions"
	c "github.com/jolyne-nyah/bridge_updater/config"
)

const (
	attempts        = 4
	durationMinutes = 5
)

type Runner struct {
	actions *a.Actions

	runRepos  bool
	runDirect bool

	ignoreInternetReachabilityTests bool
}

func NewRunner(runRepos bool, runDirects bool, ignoreInternetReachabilityTests bool, conf *c.Config) *Runner {
	return &Runner{
		actions:                         a.NewActions(conf),
		runRepos:                        runRepos,
		runDirect:                       runDirects,
		ignoreInternetReachabilityTests: ignoreInternetReachabilityTests,
	}
}

func (r *Runner) CommonCheck(checkInternet bool, logger *zap.Logger) error {

	var g errgroup.Group

	g.Go(func() error {
		return r.actions.Checker.CheckGit(logger)
	})

	g.Go(func() error {
		return r.actions.Checker.CheckCurl(logger)
	})

	g.Go(func() error {
		return r.actions.Conf.Validate(logger)
	})

	if err := g.Wait(); err != nil {
		return err
	}

	if checkInternet {
		if !r.actions.Checker.CheckInternetReachability(attempts, durationMinutes, logger) {
			return fmt.Errorf("internet reachability tests failed, aborting process")
		}
	}

	return nil

}

func (r *Runner) Fetch(alreadyCheckedCommon bool, logger *zap.Logger) error {

	if !alreadyCheckedCommon {
		if err := r.CommonCheck(!r.ignoreInternetReachabilityTests, logger); err != nil {
			return err
		}
	}

	var g errgroup.Group

	if r.runRepos {
		g.Go(func() error {
			return r.actions.Fetcher.FetchRepos(logger)
		})
	}

	if r.runDirect {
		g.Go(func() error {
			return r.actions.Fetcher.FetchDirects(logger)
		})
	}

	return g.Wait()
}

func (r *Runner) Write(alreadyChecked bool, logger *zap.Logger) error {
	if !alreadyChecked {
		if err := r.CommonCheck(false, logger); err != nil {
			return err
		}
	}

	var g errgroup.Group

	if r.runRepos {
		g.Go(func() error {
			return r.actions.Writer.WriteSectionRepos(logger)
		})
	}

	if r.runDirect {
		g.Go(func() error {
			return r.actions.Writer.WriteSectionDirect(logger)
		})
	}

	if err := g.Wait(); err != nil {
		return err
	}

	return r.actions.ReloadTor(logger)
}

func (r *Runner) FullRun(logger *zap.Logger) error {

	if err := r.CommonCheck(!r.ignoreInternetReachabilityTests, logger); err != nil {
		return err
	}

	var g errgroup.Group

	if r.runRepos {
		g.Go(func() error {
			if err := r.actions.FullProcessRepos(logger); err != nil {
				return err
			}

			return nil
		})
	}

	if r.runDirect {
		g.Go(func() error {

			if err := r.actions.FullProcessDirect(logger); err != nil {
				return err
			}

			return nil
		})
	}

	if err := g.Wait(); err != nil {
		return err
	}

	return r.actions.ReloadTor(logger)
}
