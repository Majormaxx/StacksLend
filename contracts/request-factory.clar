;; Request Factory
;; Creates new lending request contracts

;; Constants
(define-constant ERR_INVALID_AMOUNT (err u700))
(define-constant ERR_INVALID_PAYBACK (err u701))

;; Data Variables
(define-data-var trust-token-contract (optional principal) none)
(define-data-var proposal-management-contract (optional principal) none)

;; Set contracts
(define-public (set-contracts (token principal) (management principal))
    (begin
        (var-set trust-token-contract (some token))
        (var-set proposal-management-contract (some management))
        (ok true)
    )
)

;; Create lending request
(define-public (create-lending-request
    (amount uint)
    (payback uint)
    (request-purpose (string-utf8 256))
    (requester principal)
)
    (begin
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (> payback amount) ERR_INVALID_PAYBACK)
        
        ;; In a real implementation, this would deploy a new lending-request contract
        ;; For now, return request details
        (ok {
            request-type: "lending",
            asker: requester,
            amount: amount,
            payback: payback,
            purpose: request-purpose,
            verified: false ;; Would check trustee status from trust-token
        })
    )
)
