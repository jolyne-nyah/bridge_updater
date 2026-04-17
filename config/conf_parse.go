// Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
// This program comes with ABSOLUTELY NO WARRANTY.
// See <https://gnu.org> for details.

package config

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/xeipuuv/gojsonschema"
	"go.uber.org/zap"
	"golang.org/x/sync/errgroup"

	l "github.com/jolyne-nyah/bridge_updater/logger"
)

type Config = ConfigSchemaJson

func (c *Config) GetRepoFileFullPath(repo string, file string) string {
	return repo + "/" + file
}

func (c *Config) validateReposFilesRelPaths(logger *zap.Logger) error {

	logger.Debug(l.Bold("[section: repos]") + " validating relative paths started")

	errSlice := make([]error, 0)

	for repo, group := range c.Repos {

		if repo == "" {
			logger.Error(l.Bold("[section: repos]") + " repository path cannot be empty")
			errSlice = append(errSlice, fmt.Errorf("repository path cannot be empty"))
			continue
		}

		if repo[len(repo)-1] == '/' {
			logger.Error(l.Bold("[section: repos]")+" repository path cannot end with a slash", zap.String("repo", repo))
			errSlice = append(errSlice, fmt.Errorf("repository path cannot end with a slash: %s", repo))
		}

		for bridgeFile := range group {
			if strings.HasPrefix(bridgeFile, "/") {
				logger.Error(l.Bold("[section: repos]")+" file path in repo cannot be absolute", zap.String("repo", repo), zap.String("file", bridgeFile))
				errSlice = append(errSlice, fmt.Errorf("file path in repo cannot be absolute: %s in repo %s", bridgeFile, repo))
			}
		}
	}

	if len(errSlice) > 0 {
		return fmt.Errorf("repos relative paths validation failed with %d errors", len(errSlice))
	}

	logger.Debug(l.Bold("[section: repos]") + " validating repos relative paths in config completed successfully: OK")

	return nil
}

func (c *Config) validateFilesUniqueness(logger *zap.Logger) error {

	logger.Info("validating outputs uniqueness in config started")

	outputsSet := make(map[string]struct{})
	errSlice := make([]error, 0)

	process := func(file string, section string) {
		if _, exists := outputsSet[file]; exists {
			logger.Error(l.Bold("[section: "+section+"]")+" duplicate file found in config", zap.String("file", file))
			errSlice = append(errSlice, fmt.Errorf("duplicate file found in config: %s", file))
		}
		outputsSet[file] = struct{}{}
	}

	for repo, group := range c.Repos {
		for bridgeFile, outputFiles := range group {
			process(c.GetRepoFileFullPath(repo, bridgeFile), "repos")
			for _, file := range outputFiles {
				process(file, "repos")
			}
		}
	}

	for _, group := range c.Direct {
		process(group.Dest, "direct")

		for _, file := range group.Outputs {
			process(file, "direct")
		}
	}

	if len(errSlice) > 0 {
		return fmt.Errorf("files uniqueness validation failed with %d errors", len(errSlice))
	}

	logger.Info("validating files uniqueness in config completed successfully: OK")

	return nil
}

func (c *Config) validateReposSection(logger *zap.Logger) error {

	logger.Info(l.Bold("[section: repos]") + " validating repos section of config started")

	var g errgroup.Group

	for repo := range c.Repos {
		repo := repo
		g.Go(func() error {
			var err error

			cmd := exec.Command("git", "rev-parse", "--is-inside-work-tree")
			cmd.Dir = repo

			if err = cmd.Run(); err != nil {
				logger.Error(l.Bold("[section: repos]")+" Failed to validate repository", zap.String("repo", repo), zap.Error(err))
				return err
			}

			logger.Debug(l.Bold("[section: repos]")+" Repository is valid: OK", zap.String("repo", repo))

			return nil
		})
	}

	if err := g.Wait(); err != nil {
		logger.Error(l.Bold("[section: repos]") + " validating repos section of config failed")
		return err
	}

	if err := c.validateReposFilesRelPaths(logger); err != nil {
		logger.Error(l.Bold("[section: repos]") + " validating repos section of config failed")
		return err
	}

	logger.Info(l.Bold("[section: repos]") + " validating repos section of config completed successfully: OK")

	return nil
}

func (c *Config) Validate(logger *zap.Logger) error {

	var g errgroup.Group

	g.Go(func() error {
		return c.validateReposSection(logger)
	})

	g.Go(func() error {
		return c.validateFilesUniqueness(logger)
	})

	return g.Wait()
}

func LoadConfig(path string, logger *zap.Logger) (*Config, error) {

	logger.Info("loading configuration", zap.String("path", path))

	data, err := os.ReadFile(path)
	if err != nil {
		logger.Error("Failed to read configuration file", zap.String("path", path), zap.Error(err))
		return nil, err
	}

	schemaLoader := gojsonschema.NewStringLoader(schemaJSON)
	documentLoader := gojsonschema.NewBytesLoader(data)

	result, err := gojsonschema.Validate(schemaLoader, documentLoader)
	if err != nil {
		logger.Error("Failed to validate configuration schema", zap.String("path", path), zap.Error(err))
		return nil, err
	}

	if !result.Valid() {
		for _, desc := range result.Errors() {
			logger.Error("Configuration validation error", zap.String("error", desc.String()))
		}
		return nil, fmt.Errorf("configuration validation failed")
	}

	config := &Config{}
	err = json.Unmarshal(data, config)
	if err != nil {
		logger.Error("Failed to decode configuration file", zap.String("path", path), zap.Error(err))
		return nil, err
	}

	logger.Info("configuration loaded and validated successfully", zap.String("path", path))

	return config, nil
}
