// Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
// This program comes with ABSOLUTELY NO WARRANTY.
// See <https://gnu.org> for details.

package actions

import (
	"os/exec"

	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"

	c "github.com/jolyne-nyah/bridge_updater/config"
	l "github.com/jolyne-nyah/bridge_updater/logger"
)

type Fetcher struct {
	conf *c.Config
}

func (f *Fetcher) fetchSingleRepo(repo string, logger *zap.Logger) error {

	logger.Debug(l.Bold("[section: repos]")+" fetching from repository", zap.String("repo", repo))

	cmd := exec.Command("git", "pull")
	cmd.Dir = repo

	err := cmd.Run()

	if err != nil {
		logger.Error(l.Bold("[section: repos]")+" failed to fetch from repository", zap.String("repo", repo), zap.Error(err))
		return err
	}

	return nil
}

func (f *Fetcher) FetchRepos(logger *zap.Logger) error {

	logger.Info(l.Bold("[section: repos]") + " fetching started")

	var g errgroup.Group

	for repo := range f.conf.Repos {
		repo := repo
		g.Go(func() error {
			return f.fetchSingleRepo(repo, logger)
		})
	}

	if err := g.Wait(); err != nil {
		logger.Error(l.Bold("[section: repos]")+" fetching failed", zap.Error(err))
		return err
	}

	logger.Info(l.Bold("[section: repos]") + " fetching completed successfully")

	return nil
}

func (f *Fetcher) fetchSingleLink(link string, dest string, logger *zap.Logger) error {

	logger.Debug(l.Bold("[section: direct]")+" fetching from link", zap.String("link", link), zap.String("dest", dest))

	cmd := exec.Command("curl", "-s", "-f", link, "-o", dest)

	err := cmd.Run()

	if err != nil {
		logger.Error(l.Bold("[section: direct]")+" failed to fetch direct link", zap.String("link", link), zap.String("dest", dest), zap.Error(err))
		return err
	}

	return nil
}

func (f *Fetcher) FetchDirects(logger *zap.Logger) error {

	logger.Info(l.Bold("[section: direct]") + " fetching started")

	var g errgroup.Group

	for link, group := range f.conf.Direct {
		link := link
		dest := group.Dest

		logger.Debug(l.Bold("[section: direct]")+" fetching from link", zap.String("link", link))

		g.Go(func() error {
			return f.fetchSingleLink(link, dest, logger)
		})
	}

	if err := g.Wait(); err != nil {
		logger.Error(l.Bold("[section: direct]")+" fetching failed", zap.Error(err))
		return err
	}

	logger.Info(l.Bold("[section: direct]") + " fetching completed successfully")

	return nil
}
