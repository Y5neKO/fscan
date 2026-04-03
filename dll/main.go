package main

import "C"

import (
	"fmt"
	"time"
	"unsafe"

	"gitfuk.com/fxck/fxckscan/Common"
	"gitfuk.com/fxck/fxckscan/Core"
)

//export Run
func Run(args *C.char) {
	runScan(C.GoString(args))
}

//export Start
func Start(args *C.char) {
	runScan(C.GoString(args))
}

//export Execute
func Execute(args *C.char) {
	runScan(C.GoString(args))
}

func runScan(argString string) {
	start := time.Now()

	Common.InitLogger()

	var Info Common.HostInfo

	if argString != "" {
		if err := Common.FlagFromRemote(&Info, argString); err != nil {
			Common.LogError(fmt.Sprintf("参数解析失败: %v", err))
			return
		}
	} else {
		Common.Flag(&Info)
	}

	Common.SetLanguage()

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

func init() {
	// DLL 加载时仅初始化日志，不执行扫描
	Common.InitLogger()
}

func main() {
	// 防止未使用的 import 警告
	_ = unsafe.Pointer(nil)
}
