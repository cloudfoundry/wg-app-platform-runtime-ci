package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

type VCAPApplicationEnv struct {
	InstanceIndex int `json:"instance_index"`
}

var listenAddr = flag.String(
	"listenAddr",
	":8080",
	"address to listen on",
)

var name = flag.String(
	"name",
	"",
	"name to report at the name endpoint",
)

func main() {
	flag.Parse()
	time.Sleep(time.Second)

	var env VCAPApplicationEnv
	err := json.Unmarshal([]byte(os.Getenv("VCAP_APPLICATION")), &env)
	if err != nil {
		panic("Invalid $VCAP_APPLICATION: " + err.Error())
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// used to report instance index to tests
		fmt.Fprintf(w, "%d", env.InstanceIndex)
	})

	http.HandleFunc("/name", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "%s", *name)
	})

	http.HandleFunc("/env", func(w http.ResponseWriter, r *http.Request) {
		// used to report env vars to tests
		env_vars := make(map[string]string)
		for _, e := range os.Environ() {
			pair := strings.Split(e, "=")
			env_vars[pair[0]] = pair[1]
		}
		env_json, err := json.Marshal(env_vars)
		if err != nil {
			panic("Invalid env_vars: " + err.Error())
		}
		fmt.Fprintf(w, "%s", env_json)
	})

	addr := *listenAddr
	if os.Getenv("PORT") != "" {
		addr = ":" + os.Getenv("PORT")
	}

	// used to synchronize with tests
	fmt.Printf("Hello World from index '%d'\n", env.InstanceIndex)

	err = http.ListenAndServe(addr, nil)
	if err != nil {
		panic("ListenAndServe: " + err.Error())
	}
}
