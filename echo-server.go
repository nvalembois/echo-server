package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/sirupsen/logrus"
)

func main() {
	// initialisation des logs
	logrus.SetFormatter(&logrus.TextFormatter{})
	s := &http.Server{
		Addr:           ":8080",
		Handler:        &customHandler{},
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}
	logrus.Fatal(s.ListenAndServe())

}

type customHandler struct {
}

type response struct {
	Error       string      `json:"error"`
	RemoteAddr  string      `json:"remoteAddr"`
	Url         string      `json:"url"`
	Method      string      `json:"method"`
	Proto       string      `json:"proto"`
	Headers     http.Header `json:"headers"`
	HeaderSize  int         `json:"headerSize"`
	ContentSize int64       `json:"contentSize"`
	ReadSize    int         `json:"contentReadSize"`
}

func getURL(r *http.Request) string {
	protocol := "http"
	if r.TLS != nil {
		protocol += "s"
	}
	return fmt.Sprintf("%s://%s%s", protocol, r.Host, r.RequestURI)
}

func getHeaderSize(r *http.Request) int {
	s := len(r.RequestURI) + 1 + len(r.Method) + 1
	for k, v := range r.Header {
		s += len(k) + 2 + len(v) + 1
	}
	return s
}

func (h *customHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	buf := make([]byte, 1024)
	resp := response{
		Error:       "",
		RemoteAddr:  r.RemoteAddr,
		Url:         getURL(r),
		Proto:       r.Proto,
		Method:      r.Method,
		Headers:     r.Header,
		HeaderSize:  getHeaderSize(r),
		ContentSize: r.ContentLength,
		ReadSize:    0,
	}
	if r.Body != nil {
		for {
			n, err := r.Body.Read(buf)
			resp.ReadSize += n
			if err == io.EOF {
				break
			}
			if err != nil {
				logrus.Errorf("(%s) %s - read body error: %s", r.RemoteAddr, resp.Url, err)
				resp.Error = fmt.Sprintf("read body error: %s", err)
				continue
			}
		}
		r.Body.Close()
	}

	b, err := json.MarshalIndent(resp, "", "  ")
	if err != nil {
		logrus.Errorf("(%s) %s - 500 - error Marshaling response: %s", r.RemoteAddr, resp.Url, err)
		w.WriteHeader(500)
		return
	}
	w.Header().Add("Content-Type", "application/json; charset=utf-8")
	w.Header().Add("Cache-Control", "no-store")
	if _, err := w.Write(b); err != nil {
		logrus.Errorf("(%s) %s - error sending response: %s", r.RemoteAddr, resp.Url, err)
		return
	}
	logrus.Infof("(%s) %s - 200", r.RemoteAddr, resp.Url)
}
