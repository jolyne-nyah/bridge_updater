// Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
// This program comes with ABSOLUTELY NO WARRANTY.
// See <https://gnu.org> for details.

package actions

import (
	"context"
	"errors"
	"net"
	"os/exec"
	"time"

	l "github.com/jolyne-nyah/bridge_updater/logger"
	"go.uber.org/zap"
)

type Checker struct {
	checkInternetReachabilityTargets []string
}

func NewChecker() *Checker {
	return &Checker{
		checkInternetReachabilityTargets: []string{
			"9.9.9.9:53",
			"8.8.8.8:53",
			"1.1.1.1:53",
			"github.com:443",
			"google.com:443",
			"208.67.222.222:53",
		},
	}
}

func (c *Checker) CheckGit(logger *zap.Logger) error {
	logger.Info(l.Bold("[section: tools]") + " checking for git installation")

	_, err := exec.LookPath("git")

	if err != nil {
		logger.Error(l.Bold("[section: tools]")+" git is not installed or not in PATH", zap.Error(err))
		return err
	}

	logger.Info(l.Bold("[section: tools]") + " git is installed and in PATH: OK")

	return nil
}

func (c *Checker) CheckCurl(logger *zap.Logger) error {
	logger.Info(l.Bold("[section: tools]") + " checking for curl installation")

	_, err := exec.LookPath("curl")

	if err != nil {
		logger.Error(l.Bold("[section: tools]")+" curl is not installed or not in PATH", zap.Error(err))
		return err
	}

	logger.Info(l.Bold("[section: tools]") + " curl is installed and in PATH: OK")

	return nil
}

func (c *Checker) checkInternetReachabilityOneshot(logger *zap.Logger) bool {
	ctx, cancel := context.WithTimeout(context.Background(), 4*time.Second)
	defer cancel()

	success := make(chan struct{}, 1)

	for _, target := range c.checkInternetReachabilityTargets {
		go func(t string) {

			logger.Debug(l.Bold("[section: internet]")+" checking internet reachability by connecting to target", zap.String("target", t))

			d := net.Dialer{Timeout: 3 * time.Second}
			conn, err := d.DialContext(ctx, "tcp", t)

			if err != nil {
				if !errors.Is(err, context.Canceled) {
					logger.Debug(l.Bold("[section: internet]")+" connection to target failed", zap.String("target", t), zap.Error(err))
				}
				return
			}

			conn.Close()
			logger.Debug(l.Bold("[section: internet]")+" connection to target is successful", zap.String("target", t))

			select {
			case success <- struct{}{}:
			default:
			}

		}(target)
	}

	select {
	case <-success:
		return true
	case <-ctx.Done():
		return false
	}
}

func (c *Checker) CheckInternetReachability(attempts int, minutesDelay int, logger *zap.Logger) bool {

	for i := 0; i < attempts; i++ {
		if c.checkInternetReachabilityOneshot(logger) {
			logger.Info(l.Bold("[section: internet]") + " internet is reachable")
			return true
		}

		if i < attempts-1 {
			logger.Warn(l.Bold("[section: internet]")+" internet is not reachable now", zap.Int("retry_in_minutes", minutesDelay))
		}

		time.Sleep(time.Duration(minutesDelay) * time.Minute)
	}

	logger.Error(l.Bold("[section: internet]")+" internet is not reachable. failed after ", zap.Int("attempts", attempts))
	return false
}
