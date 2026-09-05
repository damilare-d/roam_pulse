package httpapi

import "net/http"

// withCORS lets the Flutter web build (served from a different origin —
// Vercel/Firebase Hosting — than this API) call it from a browser.
// Wide open (`*`) rather than a single allow-listed origin because this
// backend has no cookie- or credential-based auth to protect (see
// ADR-010: the demo endpoint hands back the one seeded traveller
// regardless of who asks) — there's nothing here a stricter origin
// policy would actually be defending.
func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}

		next.ServeHTTP(w, r)
	})
}
