package main

import (
	"container/ring"
	"errors"
	"fmt"
	"io/ioutil"
	"math"
	"net/http"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/mux"
)

var (
	theSpinner *spinner
)

// throttled-or-not/main is an app which will spin and use 100% CPU across all
// cores and will report on how performant it is.
//
// Use the /spin endpoint to start consuming CPU, and the /unspin endpoint to
// stop spinning.
//
// Use /shortspin/<secs> to spin for number of seconds, then unspin.
//
// While spinning, the app calculates fibonacci numbers inefficiently and
// reports how many numbers it managed to calculate in 100ms.  These counts are
// stored in a ring buffer of length 10.
//
// Use the /lastavg endpoint to retrieve the mean of these last 10 counts, which
// is the running average for the previous second. /minavg and /maxavg will return
// the minimum and maximum 1 second averages since the app was last spun.
//
// When the app has access to lots of CPU, the /lastavg values will be
// consistently high. When the app is throttled, the /lastavg values will be
// consistently and noticeably lower.
//
// The /cpucgroup endpoint returns the CPU cgroup path.

func main() {
	theSpinner = NewSpinner()

	r := mux.NewRouter()
	r.HandleFunc("/spin", spinHandler)
	r.HandleFunc("/unspin", unspinHandler)
	r.HandleFunc("/shortspin/{duration}", shortspinHandler)
	r.HandleFunc("/lastavg", lastavgHandler)
	r.HandleFunc("/minavg", minavgHandler)
	r.HandleFunc("/maxavg", maxavgHandler)
	r.HandleFunc("/cpucgroup", cpuCgroupHandler)
	r.HandleFunc("/ping", pingHandler)
	if err := http.ListenAndServe(":8080", r); err != nil {
		panic(err)
	}
}

const historyLen = 10

type spinner struct {
	history     *ring.Ring
	minAverage  float64
	maxAverage  float64
	lastAverage float64
	isSpinning  bool
	spinMutex   sync.Mutex
	stopCh      chan struct{}
}

func NewSpinner() *spinner {
	s := &spinner{stopCh: make(chan struct{})}
	s.history = ring.New(historyLen)
	return s
}

func spinHandler(w http.ResponseWriter, r *http.Request) {
	if err := theSpinner.Spin(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func unspinHandler(w http.ResponseWriter, r *http.Request) {
	if err := theSpinner.Unspin(); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func shortspinHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	duration, err := strconv.Atoi(vars["duration"])
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := theSpinner.Shortspin(duration); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}
func lastavgHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "%f", theSpinner.lastAverage)
}

func minavgHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "%f", theSpinner.minAverage)
}

func maxavgHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "%f", theSpinner.maxAverage)
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprint(w, "pong")
}

func cpuCgroupHandler(w http.ResponseWriter, r *http.Request) {
	var contents []byte
	var err error
	if contents, err = ioutil.ReadFile("/proc/self/cgroup"); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	for _, line := range strings.Split(string(contents), "\n") {
		lineParts := strings.Split(line, ":")
		if len(lineParts) < 3 {
			http.Error(w, "can't parse cpu cgroup path", http.StatusInternalServerError)
			return
		}

		controllers := strings.Split(lineParts[1], ",")
		if contains(controllers, "cpu") {
			fmt.Fprint(w, lineParts[2])
			return
		}
	}

	http.Error(w, "No CPU cgroup found", http.StatusInternalServerError)
}

func contains(haystack []string, needle string) bool {
	for _, s := range haystack {
		if s == needle {
			return true
		}
	}
	return false
}

func (s *spinner) Spin() error {
	s.spinMutex.Lock()
	defer s.spinMutex.Unlock()

	if s.isSpinning {
		return errors.New("already spinning")
	}
	go s.spin()
	s.isSpinning = true

	return nil
}

func (s *spinner) Shortspin(duration int) error {
	s.spinMutex.Lock()
	defer s.spinMutex.Unlock()

	if s.isSpinning {
		return errors.New("already spinning")
	}
	go s.spin()
	s.isSpinning = true
	time.AfterFunc(time.Duration(duration)*time.Second, func() {
		s.Unspin()
	})
	return nil
}

func (s *spinner) Unspin() error {
	s.spinMutex.Lock()
	defer s.spinMutex.Unlock()

	if !s.isSpinning {
		return errors.New("not spinning")
	}

	s.stopCh <- struct{}{}
	s.isSpinning = false
	return nil
}

func (s *spinner) spin() {
	period := 100 * time.Millisecond
	s.maxAverage = 0
	s.minAverage = math.MaxFloat64
	for {
		select {
		case <-s.stopCh:
			return
		default:
			n := s.countIterations(period)
			s.history.Value = n
			s.history = s.history.Next()
			s.lastAverage = s.Average()
			if s.lastAverage > s.maxAverage {
				s.maxAverage = s.lastAverage
			}
			if s.lastAverage < s.minAverage {
				s.minAverage = s.lastAverage
			}
		}
	}
}

func (s *spinner) Average() float64 {
	total := 0
	count := 0
	s.history.Do(func(p interface{}) {
		if p != nil {
			total += p.(int)
			count++
		}
	})
	if count == 0 {
		return 0
	}
	return float64(total) / float64(count)
}

func (s *spinner) countIterations(period time.Duration) int {
	numGoRoutines := runtime.NumCPU()
	resultChan := make(chan int, numGoRoutines)
	var wg sync.WaitGroup

	wg.Add(numGoRoutines)

	for i := 0; i < numGoRoutines; i++ {
		count := 0

		go func() {
			defer wg.Done()
			timeOut := time.After(period)

			for {
				select {
				case <-timeOut:
					resultChan <- count
					return
				default:
					naive_fib(silly_fib_to_get)
					count++
				}
			}
		}()
	}

	wg.Wait()
	close(resultChan)

	var res int
	for r := range resultChan {
		res += r
	}
	return res
}

const silly_fib_to_get = 24

func naive_fib(n int) int {
	if n < 1 {
		panic(fmt.Sprintf("bad input: %d", n))
	}
	if n < 3 {
		return 1
	}
	return naive_fib(n-1) + naive_fib(n-2)
}
