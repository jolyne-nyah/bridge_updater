// Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
// This program comes with ABSOLUTELY NO WARRANTY.
// See <https://gnu.org> for details.

package actions

import (
	"os/exec"

	c "github.com/jolyne-nyah/bridge_updater/core/config"
	l "github.com/jolyne-nyah/bridge_updater/core/logger"
	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"
)

type Actions struct {
	Conf *c.Config

	Checker *Checker
	Fetcher *Fetcher
	Writer  *Writer
}

func NewActions(conf *c.Config) *Actions {
	return &Actions{
		Checker: NewChecker(),
		Fetcher: &Fetcher{
			conf: conf,
		},
		Writer: &Writer{
			conf: conf,
		},
		Conf: conf,
	}
}

func (a *Actions) ReloadTor(logger *zap.Logger) error {

	logger.Info(l.Bold("[section: tools]") + " reloading Tor service")

	cmd := exec.Command("systemctl", "reload", "tor")

	err := l.RunExternalCommand(logger, cmd)

	if err != nil {
		logger.Error(l.Bold("[section: tools]")+" failed to reload Tor service", zap.Error(err))
		return err
	}

	logger.Info(l.Bold("[section: tools]") + " Tor service reloaded successfully")

	return nil
}

func (a *Actions) FullProcessDirect(logger *zap.Logger) error {

	var g errgroup.Group

	logger.Info(l.Bold("[section: direct]") + " processing started")

	for link, group := range a.Conf.Direct {
		link := link
		group := group

		g.Go(func() error {
			if err := a.Fetcher.fetchSingleLink(link, group.Dest, logger); err != nil {
				return err
			}

			if err := a.Writer.writeForBridgeFile(group.Dest, group.Outputs, logger, "direct"); err != nil {
				return err
			}

			return nil
		})
	}

	if err := g.Wait(); err != nil {
		return err
	}

	logger.Info(l.Bold("[section: direct]") + " processing completed successfully")

	return nil
}

func (a *Actions) FullProcessRepos(logger *zap.Logger) error {

	var g errgroup.Group

	logger.Info(l.Bold("[section: repos]") + " processing started")

	for repo, group := range a.Conf.Repos {
		repo := repo
		group := group

		g.Go(func() error {
			if err := a.Fetcher.fetchSingleRepo(repo, logger); err != nil {
				return err
			}

			var innerG errgroup.Group

			for bridgeFile, outputs := range group {
				bridgeFile := bridgeFile
				outputs := outputs
				innerG.Go(func() error {
					logger.Debug(l.Bold("[section: repos]")+" processing bridge file", zap.String("file", bridgeFile), zap.String("repo", repo))

					if err := a.Writer.writeForBridgeFile(a.Conf.GetRepoFileFullPath(repo, bridgeFile), outputs, logger, "repos"); err != nil {
						return err
					}

					return nil
				})
			}

			return innerG.Wait()
		})
	}

	if err := g.Wait(); err != nil {
		return err
	}

	logger.Info(l.Bold("[section: repos]") + " processing completed successfully")

	return nil
}
