package apperror

import (
	"net/http"
	"testing"
)

func TestHTTPStatus(t *testing.T) {
	cases := []struct {
		code Code
		want int
	}{
		{CodeNotFound, http.StatusNotFound},
		{CodeValidation, http.StatusUnprocessableEntity},
		{CodeUnauthorized, http.StatusUnauthorized},
		{CodeUnavailable, http.StatusServiceUnavailable},
		{CodeInternal, http.StatusInternalServerError},
		{Code("SOMETHING_UNMAPPED"), http.StatusInternalServerError},
	}

	for _, c := range cases {
		err := &Error{Code: c.code, Message: "boom"}
		if got := err.HTTPStatus(); got != c.want {
			t.Errorf("Code %q: HTTPStatus() = %d, want %d", c.code, got, c.want)
		}
	}
}

func TestErrorMessage(t *testing.T) {
	err := NotFound("traveller not found")
	if err.Error() != "traveller not found" {
		t.Errorf("Error() = %q, want %q", err.Error(), "traveller not found")
	}
}
