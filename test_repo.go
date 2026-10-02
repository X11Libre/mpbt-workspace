package main

import (
	"fmt"
	"os"

	"github.com/metux/starfleetctl/internal/ghpr"
)
func main() {
	if err := ghpr.Repo(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	} else {
		fmt.Println("Repo:", ghpr.Repo())
	}
}
