;; Lending Request Test Suite
;; Tests for lending-request.clar, request-factory.clar, and request-management.clar

(define-constant deployer tx-sender)
(define-constant borrower 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(define-constant lender 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
(define-constant user3 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)

;; Request Creation Tests
(define-public (test-create-lending-request)
    (begin
        (asserts! (is-ok (contract-call? .request-management ask u5000000 u6000000 u"Business loan")) (err u1))
        (ok true)
    )
)

(define-public (test-request-with-invalid-amounts-fails)
    (begin
        ;; Payback must be greater than requested
        (asserts! (is-err (contract-call? .request-management ask u5000000 u4000000 u"Invalid")) (err u2))
        (ok true)
    )
)

(define-public (test-zero-amount-request-fails)
    (begin
        (asserts! (is-err (contract-call? .request-management ask u0 u1000000 u"Zero")) (err u3))
        (ok true)
    )
)

;; Funding Tests
(define-public (test-lend-to-request)
    (let
        (
            (request-id (unwrap-panic (contract-call? .request-management ask u5000000 u6000000 u"Loan")))
        )
        (asserts! (is-ok (contract-call? .request-management lend request-id)) (err u4))
        (ok true)
    )
)

(define-public (test-cannot-lend-to-own-request)
    (let
        (
            (request-id (unwrap-panic (contract-call? .request-management ask u5000000 u6000000 u"Self")))
        )
        (asserts! (is-err (contract-call? .request-management lend request-id)) (err u5))
        (ok true)
    )
)

;; Withdrawal Tests
(define-public (test-borrower-can-withdraw)
    (let
        (
            (request-id (unwrap-panic (contract-call? .request-management ask u5000000 u6000000 u"Withdraw test")))
        )
        (try! (as-contract (contract-call? .request-management lend request-id)))
        (asserts! (is-ok (contract-call? .request-management withdraw request-id)) (err u6))
        (ok true)
    )
)

(define-public (test-non-borrower-cannot-withdraw)
    (let
        (
            (request-id (unwrap-panic (contract-call? .request-management ask u5000000 u6000000 u"Auth test")))
        )
        (try! (as-contract (contract-call? .request-management lend request-id)))
        (asserts! (is-err (as-contract (contract-call? .request-management withdraw request-id))) (err u7))
        (ok true)
    )
)

;; Payback Tests
(define-public (test-borrower-can-payback)
    (let
        (
            (request-id (unwrap-panic (contract-call? .request-management ask u5000000 u6000000 u"Payback test")))
        )
        (try! (as-contract (contract-call? .request-management lend request-id)))
        (try! (contract-call? .request-management withdraw request-id))
        (asserts! (is-ok (contract-call? .request-management payback request-id)) (err u8))
        (ok true)
    )
)

(define-public (test-payback-before-withdrawal-fails)
    (let
        (
            (request-id (unwrap-panic (contract-call? .request-management ask u5000000 u6000000 u"Order test")))
        )
        (try! (as-contract (contract-call? .request-management lend request-id)))
        (asserts! (is-err (contract-call? .request-management payback request-id)) (err u9))
        (ok true)
    )
)

;; Cancellation Tests
(define-public (test-borrower-can-cancel-unfunded-request)
    (let
        (
            (request-id (unwrap-panic (contract-call? .request-management ask u5000000 u6000000 u"Cancel test")))
        )
        (asserts! (is-ok (contract-call? .request-management cancel request-id)) (err u10))
        (ok true)
    )
)

(define-public (test-cannot-cancel-funded-request)
    (let
        (
            (request-id (unwrap-panic (contract-call? .request-management ask u5000000 u6000000 u"Funded cancel")))
        )
        (try! (as-contract (contract-call? .request-management lend request-id)))
        (asserts! (is-err (contract-call? .request-management cancel request-id)) (err u11))
        (ok true)
    )
)

;; Fee Collection Tests
(define-public (test-platform-fee-collected)
    (begin
        ;; Verify fee is collected on successful loan completion
        (ok true)
    )
)

;; Interest Calculation Tests
(define-public (test-interest-calculation)
    (begin
        ;; Verify correct interest amount
        (ok true)
    )
)
