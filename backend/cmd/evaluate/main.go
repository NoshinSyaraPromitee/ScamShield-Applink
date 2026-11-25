// Command evaluate measures precision/recall of the rules engine on a labelled
// CSV (columns: label,sender,message; label is "scam" or "legit").
// Usage: go run ./cmd/evaluate testdata/messages.csv
package main

import (
	"encoding/csv"
	"fmt"
	"os"

	"github.com/scamshield/backend/internal/detect"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: evaluate <labelled.csv>")
		os.Exit(2)
	}
	f, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	rows, err := csv.NewReader(f).ReadAll()
	if err != nil {
		panic(err)
	}
	var tp, fp, fn, tn int
	for i, r := range rows {
		if i == 0 || len(r) < 3 {
			continue // header
		}
		res := detect.Analyze(r[2], r[1])
		pred := res.Risk == detect.RiskHigh || res.Risk == detect.RiskMedium
		switch {
		case r[0] == "scam" && pred:
			tp++
		case r[0] == "scam":
			fn++
			fmt.Printf("MISSED: %s\n", r[2])
		case pred:
			fp++
			fmt.Printf("FALSE ALARM: %s\n", r[2])
		default:
			tn++
		}
	}
	div := func(a, b int) float64 {
		if b == 0 {
			return 0
		}
		return float64(a) / float64(b)
	}
	fmt.Printf("n=%d TP=%d FP=%d FN=%d TN=%d\nprecision=%.2f recall=%.2f\n",
		tp+fp+fn+tn, tp, fp, fn, tn, div(tp, tp+fp), div(tp, tp+fn))
}
