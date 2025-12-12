;; Proposal Factory
;; Creates new proposal contracts for the DAO

;; Constants  
(define-constant ERR_UNAUTHORIZED (err u400))
(define-constant ERR_INVALID_FEE (err u401))

;; Create a new contract fee proposal
(define-public (create-fee-proposal (proposed-fee uint) (min-votes uint) (margin uint))
    (let
        (
            (proposal-id (+ u1 block-height))
        )
        (asserts! (> proposed-fee u0) ERR_INVALID_FEE)
        
        ;; In a real implementation, this would deploy a new contract-fee-proposal
        ;; For now, we return a placeholder response
        (ok {
            proposal-type: "fee",
            proposed-fee: proposed-fee,
            min-votes: min-votes,
            margin: margin,
            creator: tx-sender
        })
    )
)

;; Create a new member proposal
(define-public (create-member-proposal (member principal) (adding bool) (trustee-count uint) (margin uint))
    (let
        (
            (min-votes (if (is-eq (/ trustee-count u2) u0) u1 (/ trustee-count u2)))
            (proposal-id (+ u1 block-height))
        )
        ;; In a real implementation, this would deploy a new member-proposal
        ;; For now, we return a placeholder response
        (ok {
            proposal-type: "member",
            member-address: member,
            is-adding: adding,
            min-votes: min-votes,
            margin: margin,
            creator: tx-sender
        })
    )
)
