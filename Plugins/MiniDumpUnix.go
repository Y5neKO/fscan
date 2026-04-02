//go:build !windows

package Plugins

import "gitfuk.com/fxck/fxckscan/Common"

func MiniDump(info *Common.HostInfo) (err error) {
	return nil
}
