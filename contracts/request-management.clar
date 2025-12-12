;; Request Management Contract
;; Central management for all lending requests

;; Constants
(define-constant ERR_UNAUTHORIZED (err u800))
(define-constant ERR_INVALID_AMOUNT (err u801))
(define-constant ERR_INVALID_PAYBACK (err u802))
(define-constant ERR_TOO_MANY_REQUESTS (err u803))
(define-constant ERR_INVALID_REQUEST (err u804))
(define-constant MAX_USER_REQUESTS u5)

;; Data Variables
(define-data-var request-factory-contract (optional principal) none)

;; Data Maps
(define-map user-request-count principal uint)
(define-map valid-requests principal bool)
(define-map request-index principal uint)
(define-map requests uint principal)
(define-data-var total-requests uint u0)

;; Set factory contract
(define-public (set-request-factory (factory principal))
    (begin
        (asserts! (is-none (var-get request-factory-contract)) ERR_UNAUTHORIZED)
        (var-set request-factory-contract (some factory))
        (ok true)
    )
)

;; Read-only functions

(define-read-only (get-user-request-count (user principal))
    (default-to u0 (map-get? user-request-count user))
)

(define-read-only (is-valid-request (request principal))
    (default-to false (map-get? valid-requests request))
)

(define-read-only (get-total-requests)
    (var-get total-requests)
)

(define-read-only (get-request-at-index (index uint))
    (map-get? requests index)
)

;; Create lending request
(define-public (ask (amount uint) (payback uint) (request-purpose (string-utf8 256)))
    (let
        (
            (user-count (get-user-request-count tx-sender))
            (request-idx (var-get total-requests))
        )
        ;; Input validation
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (> payback amount) ERR_INVALID_PAYBACK)
        (asserts! (<= amount u1000000000000) ERR_INVALID_AMOUNT) ;; Max 1M STX
        (asserts! (<= payback u2000000000000) ERR_INVALID_AMOUNT) ;; Max 2M STX
        (asserts! (< user-count MAX_USER_REQUESTS) ERR_TOO_MANY_REQUESTS)
        
        ;; Create request (in real implementation, deploy new contract)
        (let
            ((request-contract (as-contract tx-sender)))
            
            ;; Update tracking
            (map-set user-request-count tx-sender (+ user-count u1))
            (map-set valid-requests request-contract true)
            (map-set request-index request-contract request-idx)
            (map-set requests request-idx request-contract)
            (var-set total-requests (+ request-idx u1))
            
            (ok {
                request: request-contract,
                amount: amount,
                payback: payback,
                purpose: request-purpose
            })
        )
    )
)

;; Deposit to request (lend or payback)
(define-public (deposit (request principal) (amount uint))
    (begin
        (asserts! (is-valid-request request) ERR_INVALID_REQUEST)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        
        ;; In real implementation, call request contract's deposit function
        (ok {
            request: request,
            depositor: tx-sender,
            amount: amount
        })
    )
)

;; Withdraw from request
(define-public (withdraw (request principal))
    (begin
        (asserts! (is-valid-request request) ERR_INVALID_REQUEST)
        
        ;; In real implementation, call request contract's withdraw function
        (ok {
            request: request,
            withdrawer: tx-sender
        })
    )
)

;; Cancel request
(define-public (cancel-request (request principal))
    (begin
        (asserts! (is-valid-request request) ERR_INVALID_REQUEST)
        
        ;; Remove from tracking
        (map-delete valid-requests request)
        (map-set user-request-count tx-sender 
            (- (get-user-request-count tx-sender) u1))
        
        (ok true)
    )
)

;; Remove completed request
(define-private (remove-request (request principal) (user principal))
    (let
        (
            (req-index (unwrap! (map-get? request-index request) ERR_INVALID_REQUEST))
            (last-index (- (var-get total-requests) u1))
            (last-request (unwrap! (map-get? requests last-index) ERR_INVALID_REQUEST))
        )
        ;; Update user request count
        (map-set user-request-count user (- (get-user-request-count user) u1))
        
        ;; Swap with last and remove
        (map-set requests req-index last-request)
        (map-set request-index last-request req-index)
        (map-delete requests last-index)
        (map-delete request-index request)
        (map-delete valid-requests request)
        
        (var-set total-requests last-index)
        
        (ok true)
    )
)
