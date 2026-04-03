package main

import "C"

import (
	"fmt"
	"time"

	"gitfuk.com/fxck/fxckscan/Common"
	"gitfuk.com/fxck/fxckscan/Core"
)

//export Run
func Run() {}

//export Start
func Start() {}

//export Execute
func Execute() {}

func init() {
	start := time.Now()

	Common.InitLogger()

	var Info Common.HostInfo
	Common.Flag(&Info)

	if err := Common.Parse(&Info); err != nil {
		return
	}

	if err := Common.InitOutput(); err != nil {
		Common.LogError(fmt.Sprintf("初始化输出系统失败: %v", err))
		return
	}
	defer Common.CloseOutput()

	Core.Scan(Info)

	t := time.Since(start)
	fmt.Printf("[*] 扫描结束,耗时: %s\n", t)
}

func main() {}
