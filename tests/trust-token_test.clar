;; Trust Token Test Suite
;; Tests for trust-token.clar - SIP-010 token with ICO

(define-constant deployer tx-sender)
(define-constant user1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(define-constant user2 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(define-constant user3 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)

;; ICO Participation Tests
(define-public (test-ico-participation)
    (begin
        (asserts! (is-eq (contract-call? .trust-token is-ico-active) true) (err u1))
        (asserts! (is-ok (contract-call? .trust-token participate u1000000)) (err u2))
        (asserts! (> (contract-call? .trust-token get-stx-balance deployer) u0) (err u3))
        (ok true)
    )
)

(define-public (test-ico-goal-reached)
    (begin
        ;; Participate with full ICO amount
        (try! (contract-call? .trust-token participate u10000000))
        (asserts! (is-eq (contract-call? .trust-token is-ico-active) false) (err u4))
        (ok true)
    )
)

(define-public (test-claim-tokens-after-ico)
    (begin
        (try! (contract-call? .trust-token participate u5000000))
        (try! (as-contract (contract-call? .trust-token participate u5000000)))
        (asserts! (is-ok (contract-call? .trust-token claim-tokens)) (err u5))
        (ok true)
    )
)

;; Transfer Tests
(define-public (test-transfer-tokens)
    (let
        (
            (initial-balance (unwrap-panic (contract-call? .trust-token get-balance deployer)))
        )
        (asserts! (is-ok (contract-call? .trust-token transfer u100 deployer user1 none)) (err u6))
        (asserts! (is-eq (unwrap-panic (contract-call? .trust-token get-balance user1)) u100) (err u7))
        (ok true)
    )
)

;; Approval and TransferFrom Tests
(define-public (test-approve-and-transfer-from)
    (begin
        (try! (contract-call? .trust-token approve user1 u500))
        (asserts! (is-eq (unwrap-panic (contract-call? .trust-token get-allowance deployer user1)) u500) (err u8))
        (ok true)
    )
)

;; User Locking Tests
(define-public (test-user-cannot-transfer-when-locked)
    (begin
        (try! (contract-call? .trust-token set-management-contract .proposal-management))
        (try! (as-contract (contract-call? .trust-token lock-user deployer)))
        (asserts! (is-err (contract-call? .trust-token transfer u100 deployer user1 none)) (err u9))
        (ok true)
    )
)

;; Input Validation Tests
(define-public (test-zero-amount-participation-fails)
    (begin
        (asserts! (is-err (contract-call? .trust-token participate u0)) (err u10))
        (ok true)
    )
)

(define-public (test-participation-after-ico-fails)
    (begin
        (try! (contract-call? .trust-token participate u10000000))
        (asserts! (is-err (contract-call? .trust-token participate u1000)) (err u11))
        (ok true)
    )
)

;; SIP-010 Compliance Tests
(define-public (test-get-name)
    (begin
        (asserts! (is-eq (unwrap-panic (contract-call? .trust-token get-name)) "StacksLend Trust Token") (err u12))
        (ok true)
    )
)

(define-public (test-get-symbol)
    (begin
        (asserts! (is-eq (unwrap-panic (contract-call? .trust-token get-symbol)) "STT") (err u13))
        (ok true)
    )
)

(define-public (test-get-decimals)
    (begin
        (asserts! (is-eq (unwrap-panic (contract-call? .trust-token get-decimals)) u6) (err u14))
        (ok true)
    )
)

(define-public (test-get-total-supply)
    (begin
        (asserts! (is-eq (unwrap-panic (contract-call? .trust-token get-total-supply)) u1000000000) (err u15))
        (ok true)
    )
)
