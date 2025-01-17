package main

import (
	"log"
	"net/http"
	"os"
	"os/exec"

	"github.com/creack/pty"
	"github.com/gorilla/websocket"
)

var logger = log.New(os.Stdout, "(s)hell-executor ", log.LstdFlags|log.Lshortfile|log.Ltime|log.LUTC)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

func main() {
	port := getEnv("SERVER_PORT", "8080")
	http.HandleFunc("/hz", hz)
	http.Handle("/", http.FileServer(http.Dir("./static")))
	http.HandleFunc("/ws", handleShell)

	logger.Println("Server is ready to handle requests at port", port)
	logger.Fatal(http.ListenAndServe(":"+port, nil))
}

func handleShell(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		logger.Println("WebSocket upgrade error:", err)
		return
	}
	defer conn.Close()

	cmd := exec.Command("/bin/sh")
	cmd.Env = append(cmd.Env, "HISTFILE=/dev/null")
	cmd.Env = append(cmd.Env, "HISTSIZE=0")

	ptmx, err := pty.Start(cmd)
	if err != nil {
		logger.Println("Failed to start shell:", err)
		return
	}
	defer ptmx.Close()

	go func() {
		for {
			msgType, msg, err := conn.ReadMessage()
			if err != nil {
				logger.Println("WebSocket read error:", err)
				return
			}
			if msgType == websocket.TextMessage {
				// Send data from WebSocket to shell
				ptmx.Write(msg)
			}
		}
	}()

	buf := make([]byte, 1024)
	for {
		n, err := ptmx.Read(buf)
		if err != nil {
			logger.Println("Shell read error:", err)
			return
		}
		// Send shell output to WebSocket
		conn.WriteMessage(websocket.TextMessage, buf[:n])
	}
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
