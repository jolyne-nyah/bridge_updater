// Copyright (C) 2026 jolyne-nyah. Licensed under GNU GPL v3.
// This program comes with ABSOLUTELY NO WARRANTY.
// See <https://gnu.org> for details.

package logger

import (
	"bytes"
	"fmt"
	"os/exec"
	"strings"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

func InitLogger(levelStr string) (*zap.Logger, error) {
	var logLevel zapcore.Level

	switch levelStr {

	case "debug":
		logLevel = zapcore.DebugLevel

	case "info":
		logLevel = zapcore.InfoLevel

	case "warn":
		logLevel = zapcore.WarnLevel

	case "error":
		logLevel = zapcore.ErrorLevel

	default:
		return nil, fmt.Errorf("invalid log level: %s", levelStr)
	}

	enc := zapcore.EncoderConfig{
		TimeKey:      "time",
		LevelKey:     "level",
		MessageKey:   "msg",
		LineEnding:   zapcore.DefaultLineEnding,
		EncodeTime:   zapcore.ISO8601TimeEncoder,
		EncodeCaller: zapcore.ShortCallerEncoder,

		EncodeLevel: func(level zapcore.Level, enc zapcore.PrimitiveArrayEncoder) {
			switch level {
			case zapcore.InfoLevel:
				enc.AppendString("\033[1;32mINFO\033[0m")
			case zapcore.DebugLevel:
				enc.AppendString("\033[1;36mDEBUG\033[0m")
			case zapcore.ErrorLevel:
				enc.AppendString("\033[1;31mERROR\033[0m")
			case zapcore.WarnLevel:
				enc.AppendString("\033[1;33mWARN\033[0m")
			//case zapcore.FatalLevel:
			//	enc.AppendString("\033[1;35mFATAL\033[0m")
			default:
				enc.AppendString(level.CapitalString())
			}
		},
	}

	config := zap.Config{
		Encoding:         "console",
		Level:            zap.NewAtomicLevelAt(logLevel),
		OutputPaths:      []string{"stdout"},
		ErrorOutputPaths: []string{"stderr"},
		DisableCaller:    true,
		EncoderConfig:    enc,
	}

	logger, err := config.Build()
	if err != nil {
		return nil, err
	}

	return logger, nil
}

func Bold(text string) string {
	return "\033[1m" + text + "\033[0m"
}

func RunExternalCommand(logger *zap.Logger, cmd *exec.Cmd) error {
	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	err := cmd.Run()
	if err != nil {
		output := strings.TrimSpace(stderr.String())
		return fmt.Errorf("%s: %s", err, output)
	}
	return nil
}
