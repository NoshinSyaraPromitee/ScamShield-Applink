// Command evaluate measures precision/recall of the rules engine on a labelled
// CSV. Required columns (by header name): label ("scam"|"legit"), message.
// Optional: sender, lang. "Flagged" means risk is medium or high.
// Usage: go run ./cmd/evaluate testdata/dev_set.csv
package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"sort"

	"github.com/scamshield/backend/internal/detect"
)

type counts struct{ tp, fp, fn, tn int }

func (c *counts) add(scam, flagged bool) {
	switch {
	case scam && flagged:
		c.tp++
	case scam:
		c.fn++
	case flagged:
		c.fp++
	default:
		c.tn++
	}
}

func div(a, b int) float64 {
	if b == 0 {
		return 0
	}
	return float64(a) / float64(b)
}

func (c counts) String() string {
	return fmt.Sprintf("n=%-3d TP=%-3d FP=%-3d FN=%-3d TN=%-3d precision=%.2f recall=%.2f",
		c.tp+c.fp+c.fn+c.tn, c.tp, c.fp, c.fn, c.tn, div(c.tp, c.tp+c.fp), div(c.tp, c.tp+c.fn))
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: evaluate <labelled.csv>")
		os.Exit(2)
	}
	f, err := os.Open(os.Args[1])
	if err != nil {
		panic(err)
	}
	defer f.Close()
	rows, err := csv.NewReader(f).ReadAll()
	if err != nil || len(rows) < 2 {
		panic("cannot read csv")
	}
	col := map[string]int{}
	for i, h := range rows[0] {
		col[h] = i
	}
	get := func(r []string, name string) string {
		if i, ok := col[name]; ok && i < len(r) {
			return r[i]
		}
		return ""
	}

	var total counts
	byLang := map[string]*counts{}
	for _, r := range rows[1:] {
		scam := get(r, "label") == "scam"
		res := detect.Analyze(get(r, "message"), get(r, "sender"))
		flagged := res.Risk == detect.RiskHigh || res.Risk == detect.RiskMedium
		total.add(scam, flagged)
		if l := get(r, "lang"); l != "" {
			if byLang[l] == nil {
				byLang[l] = &counts{}
			}
			byLang[l].add(scam, flagged)
		}
		if scam && !flagged {
			fmt.Printf("MISSED      [%s] %s\n", res.Risk, get(r, "message"))
		} else if !scam && flagged {
			fmt.Printf("FALSE ALARM [%s] %s\n", res.Risk, get(r, "message"))
		}
	}
	fmt.Println("\nOverall:", total)
	langs := make([]string, 0, len(byLang))
	for l := range byLang {
		langs = append(langs, l)
	}
	sort.Strings(langs)
	for _, l := range langs {
		fmt.Printf("%-9s %s\n", l+":", *byLang[l])
	}
}
