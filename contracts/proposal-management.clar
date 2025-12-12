;; Proposal Management Contract
;; Central management for DAO proposals and membership

;; Constants
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_NOT_MEMBER (err u501))
(define-constant ERR_INVALID_FEE (err u502))
(define-constant ERR_INVALID_ADDRESS (err u503))
(define-constant ERR_MEMBER_EXISTS (err u504))
(define-constant ERR_NOT_TRUSTEE (err u505))
(define-constant ERR_INVALID_PROPOSAL (err u506))

;; Data Variables
(define-data-var trust-token-contract (optional principal) none)
(define-data-var proposal-factory-contract (optional principal) none)
(define-data-var contract-fee uint u1000000) ;; 1 STX in microSTX
(define-data-var minimum-votes uint u1)
(define-data-var majority-margin uint u50)
(define-data-var member-count uint u1)

;; Data Maps
(define-map member-id principal uint)
(define-map members uint principal)
(define-map proposal-type principal {prop-type: uint, data: (buff 256)})
(define-map user-proposal-locks principal uint)

;; Initialize management with deployer as first member
(map-set member-id tx-sender u1)
(map-set members u1 tx-sender)

;; Read-only functions

(define-read-only (get-contract-fee)
    (var-get contract-fee)
)

(define-read-only (get-member-status (user principal))
    (> (default-to u0 (map-get? member-id user)) u0)
)

(define-read-only (get-member-count)
    (var-get member-count)
)

(define-read-only (get-member-at-index (index uint))
    (map-get? members index)
)

(define-read-only (is-member (user principal))
    (> (default-to u0 (map-get? member-id user)) u0)
)

;; Management functions

(define-public (set-trust-token (token-contract principal))
    (begin
        (asserts! (is-none (var-get trust-token-contract)) ERR_UNAUTHORIZED)
        (var-set trust-token-contract (some token-contract))
        (ok true)
    )
)

(define-public (set-proposal-factory (factory-contract principal))
    (begin
        (asserts! (is-none (var-get proposal-factory-contract)) ERR_UNAUTHORIZED)
        (var-set proposal-factory-contract (some factory-contract))
        (ok true)
    )
)

;; Create contract fee proposal
(define-public (create-contract-fee-proposal (proposed-fee uint))
    (begin
        (asserts! (is-member tx-sender) ERR_NOT_MEMBER)
        (asserts! (> proposed-fee u0) ERR_INVALID_FEE)
        
        ;; Store proposal type for tracking
        (map-set proposal-type (as-contract tx-sender) 
            {prop-type: u1, data: 0x})
        
        (ok {
            proposal: (as-contract tx-sender),
            proposed-fee: proposed-fee
        })
    )
)

;; Create member proposal
(define-public (create-member-proposal (member-address principal) (adding bool))
    (begin
        ;; Check caller is trustee (via trust token contract - simplified for now)
        (asserts! (not (is-eq member-address tx-sender)) ERR_INVALID_ADDRESS)
        
        (if adding
            (asserts! (not (is-member member-address)) ERR_MEMBER_EXISTS)
            (asserts! (is-member member-address) ERR_NOT_MEMBER)
        )
        
        ;; Store proposal type
        (let
            ((prop-type (if adding u2 u3)))
            (map-set proposal-type (as-contract tx-sender)
                {prop-type: prop-type, data: 0x})
        )
        
        (ok {
            proposal: (as-contract tx-sender),
            member-address: member-address,
            adding: adding
        })
    )
)

;; Vote on proposal
(define-public (vote (stance bool) (proposal-address principal))
    (let
        (
            (prop-info (unwrap! (map-get? proposal-type proposal-address) ERR_INVALID_PROPOSAL))
            (prop-type (get prop-type prop-info))
        )
        ;; Fee proposals require member status
        (if (is-eq prop-type u1)
            (asserts! (is-member tx-sender) ERR_NOT_MEMBER)
            ;; Member proposals require trustee status (simplified)
            (asserts! (is-member tx-sender) ERR_NOT_TRUSTEE)
        )
        
        ;; In real implementation, call the proposal contract's vote function
        (ok {voted: true, stance: stance})
    )
)

;; Add member
(define-private (add-member (member-address principal))
    (let
        (
            (new-count (+ (var-get member-count) u1))
        )
        (asserts! (not (is-member member-address)) ERR_MEMBER_EXISTS)
        
        (map-set member-id member-address new-count)
        (map-set members new-count member-address)
        (var-set member-count new-count)
        
        ;; Update voting parameters if needed
        (if (>= (- (/ new-count u2) u1) (var-get minimum-votes))
            (var-set minimum-votes (+ (var-get minimum-votes) u1))
            false
        )
        
        (ok true)
    )
)

;; Remove member
(define-private (remove-member (member-address principal))
    (let
        (
            (member-idx (unwrap! (map-get? member-id member-address) ERR_NOT_MEMBER))
            (last-idx (var-get member-count))
            (last-member (unwrap! (map-get? members last-idx) ERR_NOT_MEMBER))
        )
        ;; Swap with last member
        (map-set members member-idx last-member)
        (map-set member-id last-member member-idx)
        
        ;; Remove last member
        (map-delete members last-idx)
        (map-delete member-id member-address)
        
        (var-set member-count (- last-idx u1))
        
        ;; Update voting parameters if needed
        (if (<= (- (/ (var-get member-count) u2) u1) (var-get minimum-votes))
            (var-set minimum-votes (- (var-get minimum-votes) u1))
            false
        )
        
        (ok true)
    )
)

;; Update contract fee (called after successful fee proposal)
(define-public (update-contract-fee (new-fee uint))
    (begin
        ;; In real implementation, verify this is called by executed proposal
        (asserts! (> new-fee u0) ERR_INVALID_FEE)
        (var-set contract-fee new-fee)
        (ok true)
    )
)
