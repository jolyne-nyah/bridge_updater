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

	c "github.com/jolyne-nyah/bridge_updater/config"
	l "github.com/jolyne-nyah/bridge_updater/logger"
)

type Writer struct {
	conf *c.Config
}

func (w *Writer) writeLine(line *string, outputFile *string, logger *zap.Logger, section string) error {
	trimmed := strings.TrimSpace(*line)

	if trimmed == "" || strings.HasPrefix(trimmed, "#") {
		return nil
	}

	file, err := os.OpenFile(*outputFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)

	if err != nil {
		logger.Error(l.Bold("[section: "+section+"]")+" Failed to open output file", zap.String("file", *outputFile), zap.Error(err))
		return err
	}

	defer file.Close()

	_, err = file.WriteString("Bridge " + trimmed + "\n")

	if err != nil {
		logger.Error(l.Bold("[section: "+section+"]")+" Failed to write to output file", zap.String("file", *outputFile), zap.Error(err))
		return err
	}

	return nil
}

func (w *Writer) writeFile(source string, output string, logger *zap.Logger, section string) error {

	logger.Debug(l.Bold("[section: "+section+"]")+" writing to output file", zap.String("file", output))

	file, err := os.Open(source)

	if err != nil {
		logger.Error(l.Bold("[section: "+section+"]")+" Failed to open bridge file", zap.String("file", source), zap.Error(err))
		return err
	}

	scanner := bufio.NewScanner(file)

	for scanner.Scan() {
		line := scanner.Text()
		err := w.writeLine(&line, &output, logger, section)

		if err != nil {
			file.Close()
			logger.Error(l.Bold("[section: "+section+"]")+" Failed to write line", zap.String("file", source), zap.Error(err))
			return err
		}
	}

	if err := scanner.Err(); err != nil {
		file.Close()
		logger.Error(l.Bold("[section: "+section+"]")+" Error reading bridge file", zap.String("file", source), zap.Error(err))
		return err
	}

	file.Close()

	return nil
}

func (w *Writer) clearFile(output string, logger *zap.Logger, section string) error {

	logger.Debug(l.Bold("[section: "+section+"]")+" clearing output file", zap.String("file", output))

	err := os.Remove(output)

	if err != nil && !os.IsNotExist(err) {
		logger.Error(l.Bold("[section: "+section+"]")+" Failed to remove output file", zap.String("file", output), zap.Error(err))
		return err
	}

	return nil
}

func (w *Writer) writeForBridgeFile(bridgeFile string, outputs []string, logger *zap.Logger, section string) error {

	var g errgroup.Group

	for _, output := range outputs {
		output := output

		g.Go(func() error {
			var err error

			err = w.clearFile(output, logger, section)
			if err != nil {
				return err
			}

			err = w.writeFile(bridgeFile, output, logger, section)
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
