;; Lending Request Contract
;; Individual lending request with deposit, withdraw, and payback functionality

;; Constants
(define-constant ERR_UNAUTHORIZED (err u600))
(define-constant ERR_INVALID_STATE (err u601))
(define-constant ERR_INVALID_AMOUNT (err u602))
(define-constant ERR_NOT_ASKER (err u603))
(define-constant ERR_NOT_LENDER (err u604))
(define-constant ERR_INVALID_LENDER (err u605))

;; Data Variables
(define-data-var management-contract principal tx-sender)
(define-data-var trust-token-contract principal tx-sender)
(define-data-var asker principal tx-sender)
(define-data-var lender (optional principal) none)
(define-data-var verified-asker bool false)
(define-data-var amount-asked uint u0)
(define-data-var payback-amount uint u0)
(define-data-var contract-fee uint u0)
(define-data-var purpose (string-utf8 256) u"")
(define-data-var money-lent bool false)
(define-data-var withdrawn-by-asker bool false)
(define-data-var withdrawn-by-lender bool false)
(define-data-var debt-settled bool false)

;; Initialize lending request
(define-public (initialize 
    (req-asker principal)
    (verified bool)
    (amount uint)
    (payback uint)
    (fee uint)
    (request-purpose (string-utf8 256))
    (management principal)
    (token principal)
)
    (begin
        ;; Input validation
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (> payback amount) ERR_INVALID_AMOUNT)
        (asserts! (<= amount u1000000000000) ERR_INVALID_AMOUNT) ;; Max 1M STX
        ;; Initialize state
        (var-set asker req-asker)
        (var-set verified-asker verified)
        (var-set amount-asked amount)
        (var-set payback-amount payback)
        (var-set contract-fee fee)
        (var-set purpose request-purpose)
        (var-set management-contract management)
        (var-set trust-token-contract token)
        (ok true)
    )
)

;; Read-only functions

(define-read-only (get-request-parameters)
    {
        asker: (var-get asker),
        lender: (var-get lender),
        amount-asked: (var-get amount-asked),
        payback-amount: (var-get payback-amount),
        contract-fee: (var-get contract-fee),
        purpose: (var-get purpose)
    }
)

(define-read-only (get-request-state)
    {
        verified-asker: (var-get verified-asker),
        money-lent: (var-get money-lent),
        withdrawn-by-asker: (var-get withdrawn-by-asker),
        debt-settled: (var-get debt-settled)
    }
)

;; Deposit STX (lend or payback)
(define-public (deposit (depositor principal))
    (begin
        ;; Authorization check
        (asserts! (is-eq tx-sender (var-get management-contract)) ERR_UNAUTHORIZED)
        ;; Input validation
        (asserts! (not (is-eq depositor (as-contract tx-sender))) ERR_UNAUTHORIZED)
        
        ;; Case 1: Lender deposits (covers the loan)
        (if (not (var-get money-lent))
            (begin
                (asserts! (not (is-eq depositor (var-get asker))) ERR_INVALID_LENDER)
                (try! (stx-transfer? (var-get amount-asked) depositor (as-contract tx-sender)))
                (var-set lender (some depositor))
                (var-set money-lent true)
                (ok {origin-is-lender: true, origin-is-asker: false})
            )
            ;; Case 2: Asker pays back
            (begin
                (asserts! (is-eq depositor (var-get asker)) ERR_NOT_ASKER)
                (asserts! (not (var-get debt-settled)) ERR_INVALID_STATE)
                (try! (stx-transfer? 
                    (+ (var-get payback-amount) (var-get contract-fee))
                    depositor 
                    (as-contract tx-sender)
                ))
                (var-set debt-settled true)
                (ok {origin-is-lender: false, origin-is-asker: true})
            )
        )
    )
)

;; Withdraw STX
(define-public (withdraw (withdrawer principal))
    (begin
        (asserts! (is-eq tx-sender (var-get management-contract)) ERR_UNAUTHORIZED)
        (asserts! (var-get money-lent) ERR_INVALID_STATE)
        
        ;; Case 1: Asker withdraws loan
        (if (is-eq withdrawer (var-get asker))
            (begin
                (asserts! (not (var-get debt-settled)) ERR_INVALID_STATE)
                (try! (as-contract (stx-transfer? (var-get amount-asked) tx-sender (var-get asker))))
                (var-set withdrawn-by-asker true)
                (ok true)
            )
            ;; Case 2: Lender withdraws (cancellation or payback)
            (begin
                (asserts! (is-eq withdrawer (unwrap! (var-get lender) ERR_NOT_LENDER)) ERR_NOT_LENDER)
                
                (if (not (var-get debt-settled))
                    ;; Lender cancels before asker withdraws
                    (begin
                        (asserts! (not (var-get withdrawn-by-asker)) ERR_INVALID_STATE)
                        (try! (as-contract (stx-transfer? (var-get amount-asked) tx-sender withdrawer)))
                        (var-set money-lent false)
                        (var-set lender none)
                        (ok true)
                    )
                    ;; Lender withdraws payback
                    (begin
                        (try! (as-contract (stx-transfer? (var-get payback-amount) tx-sender withdrawer)))
                        (var-set withdrawn-by-lender true)
                        (ok true)
                    )
                )
            )
        )
    )
)

;; Cancel request (before funded)
(define-public (cancel)
    (begin
        (asserts! (is-eq tx-sender (var-get management-contract)) ERR_UNAUTHORIZED)
        (asserts! (not (var-get money-lent)) ERR_INVALID_STATE)
        (asserts! (not (var-get debt-settled)) ERR_INVALID_STATE)
        (ok true)
    )
)

;; Clean up (after completion)
(define-public (clean-up)
    (begin
        (asserts! (is-eq tx-sender (var-get management-contract)) ERR_UNAUTHORIZED)
        ;; Transfer remaining STX (the fee) to trust token contract
        (try! (as-contract (stx-transfer? 
            (var-get contract-fee)
            tx-sender
            (var-get trust-token-contract)
        )))
        (ok true)
    )
)
