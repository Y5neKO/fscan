package Common

import (
	"encoding/base64"
	"strings"
)

// 64个单词，一一对应标准Base64字母表: A-Z a-z 0-9 + /
var wordTable = [64]string{
	"ace", "bay", "cap", "den", "elm", "fin", "gap", "hen",
	"ink", "jar", "kit", "log", "mop", "net", "orb", "pod",
	"quo", "rim", "sap", "tap", "urn", "van", "web", "yak",
	"zap", "age", "bid", "cop", "dam", "ego", "fan", "gum",
	"hub", "ice", "jog", "ken", "lap", "mud", "nod", "opt",
	"pen", "rag", "sue", "tag", "usb", "via", "war", "zoo",
	"ant", "bee", "cow", "dog", "egg", "fig", "gem", "hat",
	"jug", "key", "lip", "map", "nap", "owl", "pig", "rat",
}

// wordIndex 用于解码时快速查找
var wordIndex map[string]byte

func init() {
	wordIndex = make(map[string]byte, 64)
	for i, w := range wordTable {
		wordIndex[w] = byte(i)
	}
}

// WordEncode 将原始数据用单词Base64编码
func WordEncode(data []byte) string {
	b64 := base64.StdEncoding.EncodeToString(data)
	var buf strings.Builder
	for i := 0; i < len(b64); i++ {
		if i > 0 {
			buf.WriteByte(' ')
		}
		ch := b64[i]
		if ch >= 'A' && ch <= 'Z' {
			buf.WriteString(wordTable[ch-'A'])
		} else if ch >= 'a' && ch <= 'z' {
			buf.WriteString(wordTable[ch-'a'+26])
		} else if ch >= '0' && ch <= '9' {
			buf.WriteString(wordTable[ch-'0'+52])
		} else if ch == '+' {
			buf.WriteString(wordTable[62])
		} else if ch == '/' {
			buf.WriteString(wordTable[63])
		} else {
			// '=' padding 直接保留
			buf.WriteByte(ch)
		}
	}
	return buf.String()
}

// WordDecode 将单词Base64编码还原为原始数据
func WordDecode(encoded string) ([]byte, error) {
	b64 := new(strings.Builder)
	for _, w := range strings.Split(encoded, " ") {
		if w == "" {
			continue
		}
		if w == "=" {
			b64.WriteByte('=')
			continue
		}
		idx, ok := wordIndex[w]
		if !ok {
			// 非法单词，跳过
			continue
		}
		if idx < 26 {
			b64.WriteByte('A' + idx)
		} else if idx < 52 {
			b64.WriteByte('a' + idx - 26)
		} else if idx < 62 {
			b64.WriteByte('0' + idx - 52)
		} else if idx == 62 {
			b64.WriteByte('+')
		} else {
			b64.WriteByte('/')
		}
	}
	return base64.StdEncoding.DecodeString(b64.String())
}
