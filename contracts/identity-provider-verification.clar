;; Identity Provider Verification Contract
;; This contract validates legitimate credential issuers

(define-data-var admin principal tx-sender)

;; Map of verified identity providers
(define-map verified-providers
  principal  ;; The principal of the identity provider
  {
    name: (string-ascii 100),
    verified-at: uint,
    status: (string-ascii 20)  ;; "active" or "revoked"
  }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-ALREADY-VERIFIED u2)
(define-constant ERR-NOT-FOUND u3)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Add a new identity provider
(define-public (register-provider (provider principal) (name (string-ascii 100)))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-none (map-get? verified-providers provider)) (err ERR-ALREADY-VERIFIED))

    (map-set verified-providers
      provider
      {
        name: name,
        verified-at: block-height,
        status: "active"
      }
    )
    (ok true)
  )
)

;; Revoke a provider's verification
(define-public (revoke-provider (provider principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (match (map-get? verified-providers provider)
      provider-data (begin
        (map-set verified-providers
          provider
          (merge provider-data { status: "revoked" })
        )
        (ok true)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

;; Check if a provider is verified
(define-read-only (is-verified-provider (provider principal))
  (match (map-get? verified-providers provider)
    provider-data (is-eq (get status provider-data) "active")
    false
  )
)

;; Get provider details
(define-read-only (get-provider-details (provider principal))
  (map-get? verified-providers provider)
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)
