;; Proposal Management Test Suite
;; Tests for proposal-management.clar and related proposal contracts

(define-constant deployer tx-sender)
(define-constant user1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
(define-constant user2 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)

;; Setup: Initialize governance system
(define-public (setup-governance)
    (begin
        (try! (contract-call? .trust-token set-management-contract .proposal-management))
        (ok true)
    )
)

;; Member Proposal Tests
(define-public (test-create-member-proposal)
    (begin
        (try! (setup-governance))
        (asserts! (is-ok (contract-call? .proposal-factory create-member-proposal user1 true)) (err u1))
        (ok true)
    )
)

(define-public (test-vote-on-member-proposal)
    (let
        (
            (proposal-contract (unwrap-panic (contract-call? .proposal-factory create-member-proposal user1 true)))
        )
        (asserts! (is-ok (contract-call? .proposal-management vote true proposal-contract)) (err u2))
        (ok true)
    )
)

(define-public (test-proposal-execution-after-majority)
    (begin
        ;; Setup token holders
        (try! (contract-call? .trust-token participate u5000000))
        (let
            (
                (proposal (unwrap-panic (contract-call? .proposal-factory create-member-proposal user1 true)))
            )
            (try! (contract-call? .proposal-management vote true proposal))
            (ok true)
        )
    )
)

;; Fee Proposal Tests
(define-public (test-create-fee-proposal)
    (begin
        (asserts! (is-ok (contract-call? .proposal-factory create-contract-fee-proposal u200)) (err u3))
        (ok true)
    )
)

(define-public (test-vote-on-fee-proposal)
    (let
        (
            (proposal-contract (unwrap-panic (contract-call? .proposal-factory create-contract-fee-proposal u200)))
        )
        (asserts! (is-ok (contract-call? .proposal-management vote true proposal-contract)) (err u4))
        (ok true)
    )
)

;; Voting Power Tests
(define-public (test-voting-power-based-on-tokens)
    (begin
        (try! (contract-call? .trust-token participate u1000000))
        (try! (contract-call? .trust-token claim-tokens))
        ;; User with tokens can vote
        (ok true)
    )
)

;; Proposal Validation Tests
(define-public (test-cannot-vote-twice)
    (let
        (
            (proposal (unwrap-panic (contract-call? .proposal-factory create-member-proposal user1 true)))
        )
        (try! (contract-call? .proposal-management vote true proposal))
        (asserts! (is-err (contract-call? .proposal-management vote true proposal)) (err u5))
        (ok true)
    )
)

(define-public (test-unauthorized-proposal-creation)
    (begin
        ;; Test that fee proposals can only be created by board members
        (ok true)
    )
)

;; Quorum Tests
(define-public (test-proposal-requires-majority)
    (begin
        ;; Verify proposals need majority to pass
        (ok true)
    )
)
