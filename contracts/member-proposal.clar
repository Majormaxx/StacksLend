;; Member Proposal Contract
;; Handles proposals for adding or removing DAO members

;; Constants
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_ALREADY_VOTED (err u201))
(define-constant ERR_ALREADY_EXECUTED (err u202))
(define-constant ERR_NOT_ENOUGH_VOTES (err u203))

;; Data Variables
(define-data-var management-contract principal tx-sender)
(define-data-var member-address principal tx-sender)
(define-data-var is-adding bool true)
(define-data-var majority-margin uint u50)
(define-data-var minimum-votes uint u1)
(define-data-var vote-count uint u0)
(define-data-var positive-votes uint u0)
(define-data-var proposal-passed bool false)
(define-data-var proposal-executed bool false)

;; Data Maps
(define-map has-voted principal bool)

;; Initialize proposal
(define-public (initialize (member principal) (adding bool) (min-votes uint) (margin uint) (management principal))
    (begin
        (asserts! (is-eq tx-sender management) ERR_UNAUTHORIZED)
        (var-set member-address member)
        (var-set is-adding adding)
        (var-set minimum-votes min-votes)
        (var-set majority-margin margin)
        (var-set management-contract management)
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-member-address)
    (var-get member-address)
)

(define-read-only (get-is-adding)
    (var-get is-adding)
)

(define-read-only (get-vote-count)
    (var-get vote-count)
)

(define-read-only (get-positive-votes)
    (var-get positive-votes)
)

(define-read-only (get-proposal-status)
    {
        passed: (var-get proposal-passed),
        executed: (var-get proposal-executed),
        votes: (var-get vote-count),
        positive: (var-get positive-votes)
    }
)

;; Vote on proposal
(define-public (vote (stance bool) (voter principal))
    (begin
        (asserts! (is-eq tx-sender (var-get management-contract)) ERR_UNAUTHORIZED)
        (asserts! (not (var-get proposal-executed)) ERR_ALREADY_EXECUTED)
        (asserts! (not (default-to false (map-get? has-voted voter))) ERR_ALREADY_VOTED)
        
        ;; Record vote
        (map-set has-voted voter true)
        (var-set vote-count (+ (var-get vote-count) u1))
        
        (if stance
            (var-set positive-votes (+ (var-get positive-votes) u1))
            false
        )
        
        ;; Check if we can execute
        (if (>= (var-get vote-count) (var-get minimum-votes))
            (execute-proposal)
            (ok {passed: false, executed: false})
        )
    )
)

;; Execute proposal
(define-private (execute-proposal)
    (let
        (
            (votes (var-get vote-count))
            (positive (var-get positive-votes))
            (percentage (/ (* positive u100) votes))
        )
        (var-set proposal-executed true)
        (var-set proposal-passed (>= percentage (var-get majority-margin)))
        
        (ok {
            passed: (var-get proposal-passed),
            executed: true
        })
    )
)

;; Kill contract (return funds to management)
(define-public (destroy)
    (begin
        (asserts! (is-eq tx-sender (var-get management-contract)) ERR_UNAUTHORIZED)
        (asserts! (var-get proposal-executed) ERR_NOT_ENOUGH_VOTES)
        (ok true)
    )
)
