package advmobileinfo

import (
	"encoding/json"
	"log"
	"net/http"
	"os/exec"
	"strconv"
	"strings"
)

func Run() {
	http.HandleFunc("/", handleRequest)
	log.Fatal(http.ListenAndServe(":50500", nil))
}

func getStatus() ([]byte, error) {
	// Execute the command and capture the output
	output, err := exec.Command("status", "-v", "mobile", "1").Output()
	if err != nil {
		log.Fatal(err)
	}

	// Parse the output and create a map to store key-value pairs
	result := make(map[string]string)

	// Split the output into blocks using two consecutive newline characters
	blocks := strings.Split(string(output), "\n\n")

	// Process each block
	for _, block := range blocks {
		// Split the block into lines
		lines := strings.Split(block, "\n")

		// Process each line
		for _, line := range lines {
			// Skip processing empty lines
			if line == "" {
				continue
			}

			// Split each line into key and value
			parts := strings.SplitN(line, ":", 2)
			// Skip lines where the delimiter ":" is not found
			if len(parts) < 2 {
				continue
			}

			// Trim leading/trailing spaces from key and value
			key := strings.TrimSpace(parts[0])
			value := strings.TrimSpace(parts[1])

			// Add the key-value pair to the map
			result[key] = value
		}
	}

	// Convert the map to JSON
	jsonData, err := json.Marshal(result)
	if err != nil {
		return nil, err
	}

	// Return the JSON data
	return jsonData, nil
}

func runCommand(cmd string, args ...string) ([]byte, error) {
	output, err := exec.Command(cmd, args...).Output()
	if err != nil {
		return nil, err
	}
	return output, nil
}

func handleRequest(w http.ResponseWriter, r *http.Request) {
	// Get the query parameters
	query := r.URL.Query().Get("query")
	selectsim := r.URL.Query().Get("selectsim")
	sim := r.URL.Query().Get("sim")
	gsmpwr := r.URL.Query().Get("gsmpwr")
	pwr := r.URL.Query().Get("pwr")

	var response []byte
	var err error

	if selectsim != "" {
		simNumber, err := strconv.Atoi(sim)
		if err != nil || (simNumber != 1 && simNumber != 2) {
			http.Error(w, "Invalid sim parameter, must be 1 or 2", http.StatusBadRequest)
			return
		}
		response, err = runCommand("gsmat", "AT+QUIMSLOT="+sim)
	} else if gsmpwr != "" {
		pwrState, err := strconv.Atoi(pwr)
		if err != nil || (pwrState != 0 && pwrState != 1) {
			http.Error(w, "Invalid pwr parameter, must be 0 or 1", http.StatusBadRequest)
			return
		}
		if pwrState == 1 {
			response, err = runCommand("gsmpwr", "on")
		} else {
			response, err = runCommand("gsmpwr", "off")
		}
	} else {
		switch query {
		case "info":
			response, err = getStatus()
		case "sim":
			response, err = runCommand("gsmat", "AT+QUIMSLOT?")
		case "simready":
			response, err = runCommand("gsmat", "AT+CPIN?")
		default:
			http.Error(w, "Invalid query parameter", http.StatusBadRequest)
			return
		}
	}

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// Set the Content-Type header to application/json
	w.Header().Set("Content-Type", "application/json")

	// Write the JSON response
	w.Write(response)
}
