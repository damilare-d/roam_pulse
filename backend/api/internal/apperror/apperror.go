// Package apperror is RoamPulse's structured error model. Handlers never
// return bare strings to the client — every failure is one of these
// classified codes, mapped to a consistent HTTP status and JSON shape
// (see docs/ARCHITECTURE.md section 7).
package apperror

import "net/http"

type Code string

const (
	CodeNotFound     Code = "NOT_FOUND"
	CodeValidation   Code = "VALIDATION_ERROR"
	CodeUnauthorized Code = "UNAUTHORIZED"
	CodeUnavailable  Code = "SERVICE_UNAVAILABLE"
	CodeInternal     Code = "INTERNAL_ERROR"
)

// Error is a classified application failure. It implements the error
// interface so it can flow through normal Go error handling, while still
// carrying enough structure for the HTTP layer to render a precise
// response instead of collapsing everything into "something went wrong".
type Error struct {
	Code    Code
	Message string
	Details map[string]any
}

func (e *Error) Error() string {
	return e.Message
}

func (e *Error) HTTPStatus() int {
	switch e.Code {
	case CodeNotFound:
		return http.StatusNotFound
	case CodeValidation:
		return http.StatusUnprocessableEntity
	case CodeUnauthorized:
		return http.StatusUnauthorized
	case CodeUnavailable:
		return http.StatusServiceUnavailable
	default:
		return http.StatusInternalServerError
	}
}

func NotFound(message string) *Error {
	return &Error{Code: CodeNotFound, Message: message}
}

func Validation(message string, details map[string]any) *Error {
	return &Error{Code: CodeValidation, Message: message, Details: details}
}

func Unavailable(message string) *Error {
	return &Error{Code: CodeUnavailable, Message: message}
}

func Internal(message string) *Error {
	return &Error{Code: CodeInternal, Message: message}
}
