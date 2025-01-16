package main

import (
	"bytes"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"os"
	"os/exec"
)

const formTemplate = `
<!DOCTYPE html>
<html>
<head>
	<title>shell-executor</title>
</head>
<body>
	<h1>shell executor</h1>
	<form method="POST" action="/">
		<label for="command">enter command:</label><br>
		<input type="text" id="command" name="command" style="width:300px;"><br><br>
		<input type="submit" value="Run">
	</form>
	<h2>output:</h2>
	<pre>{{.Output}}</pre>
</body>
</html>
`

type CommandResult struct {
	Output string
}

var logger = log.New(os.Stdout, "shell-executor ", log.LstdFlags|log.Lshortfile|log.Ltime|log.LUTC)

func main() {
	port := getEnv("SERVER_PORT", "8080")
	http.HandleFunc("/hz", hz)
	http.HandleFunc("/", commandHandler)
	logger.Println("Server is ready to handle requests at port", port)
	logger.Fatal(http.ListenAndServe(":"+port, nil))
}

func hz(w http.ResponseWriter, r *http.Request) {
	logger.Println(r.UserAgent())
	_, err := w.Write([]byte("ok"))
	if err != nil {
		logger.Println("Error writing response:", err)
	}
}

func getEnv(key, defaultValue string) string {
	value := os.Getenv(key)
	if len(value) == 0 {
		return defaultValue
	}
	return value
}

func commandHandler(w http.ResponseWriter, r *http.Request) {
	var result CommandResult

	if r.Method == http.MethodPost {
		command := r.FormValue("command")
		output, err := executeShellCommand(command)
		if err != nil {
			result.Output = fmt.Sprintf("Error: %v\n%s", err, output)
		} else {
			result.Output = output
		}
	}

	// tmpl := template.Must(template.New("form").Parse(formTemplate))
	tmpl, err := template.New("form").Parse(formTemplate)
	if err != nil {
		http.Error(w, "Failed to parse template", http.StatusInternalServerError)
		return
	}

	err = tmpl.Execute(w, result)
	if err != nil {
		http.Error(w, "Failed to render template", http.StatusInternalServerError)
	}
}

func executeShellCommand(cmd string) (string, error) {
	command := exec.Command("sh", "-c", cmd)
	// For Windows, use "cmd" and "/C"
	var out bytes.Buffer
	var stderr bytes.Buffer
	command.Stdout = &out
	command.Stderr = &stderr
	err := command.Run()
	if err != nil {
		return stderr.String(), err
	}
	return out.String(), nil
}
