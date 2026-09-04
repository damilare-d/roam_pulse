/// The two independent axes Chaos Mode's developer console exposes
/// (docs/PRODUCT_DISCOVERY.md section 13) — a network-layer condition and
/// an API-layer condition, applied to every outgoing request together.
enum NetworkCondition { normal, offline, slow, timeout }

enum ApiCondition { normal, serverError, emptyResponse, delayed }
