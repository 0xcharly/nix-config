package theme

import (
	"fmt"
	"strconv"
	"strings"
)

// Expression grammar:
//
//	expr    := IDENT | HEX | call
//	call    := FNAME '(' arg (',' arg)* ')'
//	arg     := expr [ '/' ALPHA ]     -- alpha suffix valid only on blend's 1st arg
//	         | PERCENT
//	HEX     := '#' [0-9a-fA-F]{6}
//	IDENT   := [A-Za-z][A-Za-z0-9_-]*
//	PERCENT := number '%'             -- '%' required for amount args
//	ALPHA   := number ['%']           -- bare number = percent (Tailwind: amber-300/15)

type node interface{ isNode() }

type identNode struct{ name string }

type hexNode struct{ rgb [3]uint8 }

type callNode struct {
	fn   string
	args []argNode
}

// argNode is one call argument: either an expression (optionally with an
// alpha suffix) or a bare percentage.
type argNode struct {
	expr    node     // nil for percent-only args
	alpha   *float64 // 0-1; set by "/N" suffix
	percent *float64 // 0-1; set by "N%"
}

func (identNode) isNode() {}
func (hexNode) isNode()   {}
func (callNode) isNode()  {}

type parser struct {
	input string
	pos   int
}

func parseExpr(input string) (node, error) {
	p := &parser{input: input}
	n, err := p.expr()
	if err != nil {
		return nil, err
	}
	p.skipSpace()
	if p.pos != len(p.input) {
		return nil, fmt.Errorf("unexpected trailing input at %q", p.input[p.pos:])
	}
	return n, nil
}

func (p *parser) skipSpace() {
	for p.pos < len(p.input) && (p.input[p.pos] == ' ' || p.input[p.pos] == '\t') {
		p.pos++
	}
}

func (p *parser) peek() byte {
	if p.pos < len(p.input) {
		return p.input[p.pos]
	}
	return 0
}

func (p *parser) expr() (node, error) {
	p.skipSpace()
	c := p.peek()
	switch {
	case c == '#':
		return p.hex()
	case isAlpha(c):
		name := p.ident()
		p.skipSpace()
		if p.peek() == '(' {
			return p.call(name)
		}
		return identNode{name: name}, nil
	default:
		return nil, fmt.Errorf("expected identifier, '#rrggbb', or function call at %q", p.input[p.pos:])
	}
}

func (p *parser) hex() (node, error) {
	p.pos++ // consume '#'
	start := p.pos
	for p.pos < len(p.input) && isHexDigit(p.input[p.pos]) {
		p.pos++
	}
	digits := p.input[start:p.pos]
	if len(digits) != 6 {
		return nil, fmt.Errorf("hex literal #%s must have exactly 6 digits", digits)
	}
	var rgb [3]uint8
	for i := range 3 {
		v, err := strconv.ParseUint(digits[2*i:2*i+2], 16, 8)
		if err != nil {
			return nil, fmt.Errorf("invalid hex literal #%s", digits)
		}
		rgb[i] = uint8(v)
	}
	return hexNode{rgb: rgb}, nil
}

func (p *parser) ident() string {
	start := p.pos
	p.pos++ // first char validated by caller
	for p.pos < len(p.input) && isIdentChar(p.input[p.pos]) {
		p.pos++
	}
	return p.input[start:p.pos]
}

func (p *parser) call(fn string) (node, error) {
	p.pos++ // consume '('
	var args []argNode
	for {
		arg, err := p.arg()
		if err != nil {
			return nil, err
		}
		args = append(args, arg)
		p.skipSpace()
		switch p.peek() {
		case ',':
			p.pos++
		case ')':
			p.pos++
			return callNode{fn: fn, args: args}, nil
		default:
			return nil, fmt.Errorf("expected ',' or ')' in %s(...) at %q", fn, p.input[p.pos:])
		}
	}
}

func (p *parser) arg() (argNode, error) {
	p.skipSpace()
	if isDigit(p.peek()) || p.peek() == '.' {
		// PERCENT argument: number must be followed by '%'.
		v, err := p.number()
		if err != nil {
			return argNode{}, err
		}
		if p.peek() != '%' {
			return argNode{}, fmt.Errorf("amount argument must end in '%%' at %q", p.input[p.pos:])
		}
		p.pos++
		if v < 0 || v > 100 {
			return argNode{}, fmt.Errorf("percentage %v%% outside [0, 100]", v)
		}
		pct := v / 100
		return argNode{percent: &pct}, nil
	}
	n, err := p.expr()
	if err != nil {
		return argNode{}, err
	}
	a := argNode{expr: n}
	p.skipSpace()
	if p.peek() == '/' {
		p.pos++
		p.skipSpace()
		v, err := p.number()
		if err != nil {
			return argNode{}, err
		}
		if p.peek() == '%' {
			p.pos++
		}
		if v < 0 || v > 100 {
			return argNode{}, fmt.Errorf("alpha %v outside [0, 100]", v)
		}
		alpha := v / 100
		a.alpha = &alpha
	}
	return a, nil
}

func (p *parser) number() (float64, error) {
	start := p.pos
	for p.pos < len(p.input) && (isDigit(p.input[p.pos]) || p.input[p.pos] == '.') {
		p.pos++
	}
	v, err := strconv.ParseFloat(p.input[start:p.pos], 64)
	if err != nil {
		return 0, fmt.Errorf("invalid number %q", p.input[start:p.pos])
	}
	return v, nil
}

func isAlpha(c byte) bool { return c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' }

func isDigit(c byte) bool { return c >= '0' && c <= '9' }

func isHexDigit(c byte) bool { return isDigit(c) || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F' }

func isIdentChar(c byte) bool { return isAlpha(c) || isDigit(c) || c == '_' || c == '-' }

// exprIdents collects every identifier referenced by n (for diagnostics).
func exprString(n node) string {
	switch n := n.(type) {
	case identNode:
		return n.name
	case hexNode:
		return fmt.Sprintf("#%02x%02x%02x", n.rgb[0], n.rgb[1], n.rgb[2])
	case callNode:
		var args []string
		for _, a := range n.args {
			args = append(args, argString(a))
		}
		return n.fn + "(" + strings.Join(args, ", ") + ")"
	}
	return "?"
}

func argString(a argNode) string {
	if a.percent != nil {
		return strconv.FormatFloat(*a.percent*100, 'f', -1, 64) + "%"
	}
	s := exprString(a.expr)
	if a.alpha != nil {
		s += "/" + strconv.FormatFloat(*a.alpha*100, 'f', -1, 64)
	}
	return s
}
