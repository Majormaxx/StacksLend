;; StacksLend Trust Token (STT) - SIP-010 Fungible Token with ICO
;;
;; This contract implements a fungible token following the SIP-010 standard
;; with an Initial Coin Offering (ICO) mechanism for P2P lending platform governance

;; SIP-010 Trait
(impl-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_TOKEN_OWNER (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_ICO_INACTIVE (err u103))
(define-constant ERR_ICO_ACTIVE (err u104))
(define-constant ERR_INVALID_AMOUNT (err u105))
(define-constant ERR_USER_LOCKED (err u106))

;; Token Configuration
(define-constant TOKEN_NAME "StacksLend Trust Token")
(define-constant TOKEN_SYMBOL "STT")
(define-constant TOKEN_DECIMALS u6)
(define-constant TOKEN_SUPPLY u1000000000) ;; 1,000 tokens with 6 decimals

;; ICO Configuration
(define-constant ICO_GOAL u10000000) ;; 10 STX (with 6 decimals)

;; Data Variables
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var ico-active bool true)
(define-data-var contract-stx-balance uint u0)
(define-data-var trustee-count uint u0)
(define-data-var proposal-management-contract (optional principal) none)
(define-data-var total-burned uint u0)

;; Data Maps
(define-map token-balances
    principal
    uint
)
(define-map stx-balances
    principal
    uint
)
(define-map is-trustee
    principal
    bool
)
(define-map is-user-locked
    principal
    bool
)
(define-map allowances
    {
        owner: principal,
        spender: principal,
    }
    uint
)

;; Read-only functions for SIP-010

;; Returns the token name
;; @returns (response string-utf8 ERR)
(define-read-only (get-name)
    (ok TOKEN_NAME)
)

;; Returns the token symbol
;; @returns (response string-utf8 ERR)
(define-read-only (get-symbol)
    (ok TOKEN_SYMBOL)
)

;; Returns the number of decimals
;; @returns (response uint ERR)
(define-read-only (get-decimals)
    (ok TOKEN_DECIMALS)
)

;; Returns the token balance of a given account
;; @param account - principal to query
;; @returns (response uint ERR)
(define-read-only (get-balance (account principal))
    (ok (default-to u0 (map-get? token-balances account)))
)

;; Returns the total token supply
;; @returns (response uint ERR)
(define-read-only (get-total-supply)
    (ok TOKEN_SUPPLY)
)

;; Returns the optional token URI
;; @returns (response (optional string-utf8) ERR)
(define-read-only (get-token-uri)
    (ok (var-get token-uri))
)

;; Additional read-only functions

(define-read-only (get-stx-balance (account principal))
    (default-to u0 (map-get? stx-balances account))
)

(define-read-only (is-ico-active)
    (var-get ico-active)
)

(define-read-only (get-trustee-status (account principal))
    (default-to false (map-get? is-trustee account))
)

(define-read-only (get-user-locked-status (account principal))
    (default-to false (map-get? is-user-locked account))
)

(define-read-only (get-contract-stx-balance)
    (var-get contract-stx-balance)
)

(define-read-only (get-trustee-count)
    (var-get trustee-count)
)

(define-read-only (get-allowance
        (owner principal)
        (spender principal)
    )
    (ok (default-to u0
        (map-get? allowances {
            owner: owner,
            spender: spender,
        })
    ))
)

(define-read-only (get-ico-parameters)
    {
        is-active: (var-get ico-active),
        goal: ICO_GOAL,
        contract-balance: (var-get contract-stx-balance),
        total-supply: TOKEN_SUPPLY,
        trustee-count: (var-get trustee-count),
        user-token-balance: (default-to u0 (map-get? token-balances tx-sender)),
        user-stx-balance: (default-to u0 (map-get? stx-balances tx-sender)),
    }
)

;; Management functions

(define-public (set-management-contract (management principal))
    (begin
        ;; Can only be set once or by current management
        (asserts!
            (or
                (is-none (var-get proposal-management-contract))
                (is-eq tx-sender
                    (unwrap! (var-get proposal-management-contract)
                        ERR_UNAUTHORIZED
                    ))
            )
            ERR_UNAUTHORIZED
        )
        (ok (var-set proposal-management-contract (some management)))
    )
)

(define-public (lock-user (user principal))
    (begin
        (asserts!
            (is-eq tx-sender
                (unwrap! (var-get proposal-management-contract) ERR_UNAUTHORIZED)
            )
            ERR_UNAUTHORIZED
        )
        (ok (map-set is-user-locked user true))
    )
)

(define-public (unlock-users (users (list 100 principal)))
    (begin
        (asserts!
            (is-eq tx-sender
                (unwrap! (var-get proposal-management-contract) ERR_UNAUTHORIZED)
            )
            ERR_UNAUTHORIZED
        )
        (ok (map unlock-user-helper users))
    )
)

(define-private (unlock-user-helper (user principal))
    (map-set is-user-locked user false)
)

;; ICO Participation

(define-public (participate (amount uint))
    (let (
            (participant tx-sender)
            (current-balance (var-get contract-stx-balance))
            (allowed-amount (if (> (+ current-balance amount) ICO_GOAL)
                (- ICO_GOAL current-balance)
                amount
            ))
            (refund-amount (- amount allowed-amount))
        )
        ;; Input validation
        (asserts! (var-get ico-active) ERR_ICO_INACTIVE)
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (<= amount u1000000000000) ERR_INVALID_AMOUNT) ;; Max 1M STX
        (asserts! (not (is-eq participant (as-contract tx-sender))) ERR_UNAUTHORIZED)

        ;; Reentrancy protection: checks-effects-interactions pattern
        ;; 1. Checks complete (all assertions above)
        ;; 2. Effects - update state BEFORE external call
        (let
            (
                (new-balance (+ current-balance allowed-amount))
            )
            (var-set contract-stx-balance new-balance)
            (map-set stx-balances participant
                (+ (get-stx-balance participant) allowed-amount)
            )
        )

        ;; 3. Interactions - external calls happen last
        (try! (stx-transfer? allowed-amount participant (as-contract tx-sender)))

        ;; Register as trustee if not already
        (if (not (get-trustee-status participant))
            (begin
                (map-set is-trustee participant true)
                (var-set trustee-count (+ (var-get trustee-count) u1))
            )
            false
        )

        ;; Check if goal reached and distribute tokens
        (if (>= (var-get contract-stx-balance) ICO_GOAL)
            (begin
                (var-set ico-active false)
                (try! (distribute-tokens))
            )
            false
        )

        (ok {
            allowed: allowed-amount,
            refunded: refund-amount,
        })
    )
)

;; Private function to distribute tokens
(define-private (distribute-tokens)
    (ok true)
    ;; Note: Due to Clarity limitations, we cannot iterate over all participants
    ;; Token distribution will happen on first transfer/claim
)

;; Claim tokens after ICO (proportional to STX contributed)
(define-public (claim-tokens)
    (let (
            (claimer tx-sender)
            (stx-contributed (get-stx-balance claimer))
            (total-stx (var-get contract-stx-balance))
            (tokens-to-receive (/ (* stx-contributed TOKEN_SUPPLY) total-stx))
        )
        (asserts! (not (var-get ico-active)) ERR_ICO_ACTIVE)
        (asserts! (> stx-contributed u0) ERR_INVALID_AMOUNT)
        (asserts! (is-eq (default-to u0 (map-get? token-balances claimer)) u0)
            ERR_INVALID_AMOUNT
        )

        ;; Mint tokens to claimer
        (map-set token-balances claimer tokens-to-receive)

        (ok tokens-to-receive)
    )
)

;; SIP-010 Transfer function
(define-public (transfer
        (amount uint)
        (sender principal)
        (recipient principal)
        (memo (optional (buff 34)))
    )
    (begin
<<<<<<< HEAD
        ;; Input validation
        (asserts! (> amount u0) ERR_INVALID_AMOUNT)
        (asserts! (not (is-eq sender recipient)) ERR_INVALID_AMOUNT)
        ;; Authorization and lock checks
        (asserts! (or (is-eq tx-sender sender) (> (default-to u0 (map-get? allowances {owner: sender, spender: tx-sender})) u0)) ERR_NOT_TOKEN_OWNER)
=======
        (asserts!
            (or (is-eq tx-sender sender) (>
                (default-to u0
                    (map-get? allowances {
                        owner: sender,
                        spender: tx-sender,
                    })
                )
                u0
            ))
            ERR_NOT_TOKEN_OWNER
        )
>>>>>>> issue-21-inline-documentation
        (asserts! (not (get-user-locked-status sender)) ERR_USER_LOCKED)

        (let ((sender-balance (default-to u0 (map-get? token-balances sender))))
            (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)

            ;; Update sender balance
            (map-set token-balances sender (- sender-balance amount))

            ;; Update recipient balance
            (map-set token-balances recipient
                (+ (default-to u0 (map-get? token-balances recipient)) amount)
            )

            ;; Update trustee status
            (if (is-eq (- sender-balance amount) u0)
                (begin
                    (map-set is-trustee sender false)
                    (var-set trustee-count (- (var-get trustee-count) u1))
                )
                false
            )

            (if (not (get-trustee-status recipient))
                (begin
                    (map-set is-trustee recipient true)
                    (var-set trustee-count (+ (var-get trustee-count) u1))
                )
                false
            )

            ;; Print transfer event
            (print {
                type: "transfer",
                sender: sender,
                recipient: recipient,
                amount: amount,
                memo: memo,
            })

            (ok true)
        )
    )
)

;; Approve spender
(define-public (approve
        (spender principal)
        (amount uint)
    )
    (begin
<<<<<<< HEAD
        ;; Input validation
        (asserts! (not (is-eq spender tx-sender)) ERR_INVALID_AMOUNT)
        (asserts! (>= (default-to u0 (map-get? token-balances tx-sender)) amount) ERR_INSUFFICIENT_BALANCE)
        (map-set allowances {owner: tx-sender, spender: spender} amount)
=======
        (asserts! (>= (default-to u0 (map-get? token-balances tx-sender)) amount)
            ERR_INSUFFICIENT_BALANCE
        )
        (map-set allowances {
            owner: tx-sender,
            spender: spender,
        }
            amount
        )
>>>>>>> issue-21-inline-documentation
        (ok true)
    )
)

;; Transfer from (using allowance)
(define-public (transfer-from
        (owner principal)
        (recipient principal)
        (amount uint)
    )
    (let (
            (allowance (default-to u0
                (map-get? allowances {
                    owner: owner,
                    spender: tx-sender,
                })
            ))
            (owner-balance (default-to u0 (map-get? token-balances owner)))
        )
        (asserts! (>= allowance amount) ERR_UNAUTHORIZED)
        (asserts! (>= owner-balance amount) ERR_INSUFFICIENT_BALANCE)
        (asserts! (not (get-user-locked-status owner)) ERR_USER_LOCKED)

        ;; Update allowance
        (map-set allowances {
            owner: owner,
            spender: tx-sender,
        }
            (- allowance amount)
        )

        ;; Update balances
        (map-set token-balances owner (- owner-balance amount))
        (map-set token-balances recipient
            (+ (default-to u0 (map-get? token-balances recipient)) amount)
        )

        ;; Update trustee status
        (if (is-eq (- owner-balance amount) u0)
            (begin
                (map-set is-trustee owner false)
                (var-set trustee-count (- (var-get trustee-count) u1))
            )
            false
        )

        (if (not (get-trustee-status recipient))
            (begin
                (map-set is-trustee recipient true)
                (var-set trustee-count (+ (var-get trustee-count) u1))
            )
            false
        )

        (print {
            type: "transfer-from",
            owner: owner,
            recipient: recipient,
            amount: amount,
            spender: tx-sender,
        })

        (ok true)
    )
)

;; Batch transfer for gas optimization
(define-public (batch-transfer (transfers (list 10 {recipient: principal, amount: uint})))
    (ok (map batch-transfer-helper transfers))
)

(define-private (batch-transfer-helper (transfer-data {recipient: principal, amount: uint}))
    (unwrap-panic (transfer
        (get amount transfer-data)
        tx-sender
        (get recipient transfer-data)
        none
    ))
)

;; Analytics read-only functions
(define-read-only (get-holder-count)
    (var-get trustee-count)
)

(define-read-only (get-circulating-supply)
    (- TOKEN_SUPPLY (var-get total-burned))
)
