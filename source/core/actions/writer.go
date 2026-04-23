// Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
// This program comes with ABSOLUTELY NO WARRANTY.
// See <https://gnu.org> for details.

package actions

import (
	"bufio"
	"os"
	"strings"

	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"

	c "github.com/jolyne-nyah/bridge_updater/core/config"
	l "github.com/jolyne-nyah/bridge_updater/core/logger"
)

type Writer struct {
	conf *c.Config
}

func (w *Writer) writeFile(source string, output string, logger *zap.Logger, section string) (err error) {

	logger.Debug(l.Bold("[section: "+section+"]")+" writing to output file", zap.String("file", output))

	sourceFile, err := os.Open(source)
	if err != nil {
		logger.Error(l.Bold("[section: "+section+"]")+" Failed to open bridge file", zap.String("file", source), zap.Error(err))
		return err
	}

	defer func() { _ = sourceFile.Close() }()

	outputFile, err := os.OpenFile(output, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
	if err != nil {
		logger.Error(l.Bold("[section: "+section+"]")+" Failed to open output file", zap.String("file", output), zap.Error(err))
		return err
	}

	defer func() {
		closeErr := outputFile.Close()

		if err == nil {
			err = closeErr
		}
	}()

	scanner := bufio.NewScanner(sourceFile)

	for scanner.Scan() {
		line := scanner.Text()
		trimmed := strings.TrimSpace(line)

		if trimmed == "" || strings.HasPrefix(trimmed, "#") {
			continue
		}

		_, err = outputFile.WriteString("Bridge " + trimmed + "\n")
		if err != nil {
			logger.Error(l.Bold("[section: "+section+"]")+" Failed to write to output file", zap.String("file", output), zap.Error(err))
			return err
		}
	}

	err = scanner.Err()
	if err != nil {
		logger.Error(l.Bold("[section: "+section+"]")+" Error reading bridge file", zap.String("file", source), zap.Error(err))
		return err
	}

	return nil
}

func (w *Writer) writeForBridgeFile(bridgeFile string, outputs []string, logger *zap.Logger, section string) error {

	var g errgroup.Group

	for _, output := range outputs {
		output := output

		g.Go(func() error {
			err := w.writeFile(bridgeFile, output, logger, section)
			if err != nil {
				return err
			}

			return nil
		})
	}

	return g.Wait()
}

func (w *Writer) WriteSectionRepos(logger *zap.Logger) error {

	logger.Info(l.Bold("[section: repos]") + " writing to output files started")

	var g errgroup.Group

	for repo, group := range w.conf.Repos {

		for bridgeFile, outputs := range group {
			repo := repo
			bridgeFile := bridgeFile
			outputs := outputs
			g.Go(func() error {
				logger.Debug(l.Bold("[section: repos]")+" processing bridge file", zap.String("file", bridgeFile), zap.String("repo", repo))

				if err := w.writeForBridgeFile(w.conf.GetRepoFileFullPath(repo, bridgeFile), outputs, logger, "repos"); err != nil {
					return err
				}

				return nil
			})
		}
	}

	if err := g.Wait(); err != nil {
		return err
	}

	logger.Info(l.Bold("[section: repos]") + " writing to output files completed successfully")

	return nil
}

func (w *Writer) WriteSectionDirect(logger *zap.Logger) error {

	logger.Info(l.Bold("[section: direct]") + " writing to output files started")

	var g errgroup.Group

	for _, group := range w.conf.Direct {
		group := group
		g.Go(func() error {
			logger.Debug(l.Bold("[section: direct]")+" processing bridge file", zap.String("file", group.Dest))

			if err := w.writeForBridgeFile(group.Dest, group.Outputs, logger, "direct"); err != nil {
				return err
			}

			return nil
		})
	}

	if err := g.Wait(); err != nil {
		return err
	}

	logger.Info(l.Bold("[section: direct]") + " writing to output files completed successfully")

	return nil
}
