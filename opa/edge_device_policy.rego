package envoy.authz

import input.attributes.request.http as http_request

default allow = false

allow if {
    svc_spiffe_id == "spiffe://paavo-rotsten.org/edge-service"
}

svc_spiffe_id = spiffe_id if {
    [_, _, uri_type_san] := split(http_request.headers["x-forwarded-client-cert"], ";")
    [_, spiffe_id] := split(uri_type_san, "=")
}