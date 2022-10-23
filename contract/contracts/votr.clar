;; this nft contract will be used by registered organizations to authorize users who can vote for an election they created
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

(define-constant contract-owner tx-sender)
(define-constant contract-address (as-contract tx-sender))

(define-constant err-owner-only (err u100))
(define-constant err-token-id-failure (err u101))
(define-constant err-not-token-owner (err u102))

(define-non-fungible-token vote-invitation uint)
(define-data-var invitation-id-nonce uint u0)

(define-read-only (get-last-token-id)
    (ok (var-get invitation-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
    (ok none)
)

(define-read-only (get-owner (token-id uint))
    (ok (nft-get-owner? vote-invitation token-id))
)

(define-public (transfer (invitation-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender sender) err-not-token-owner)
        ;; #[filter(vote-invitation, invitation-id, sender, recipient)]
        (nft-transfer? vote-invitation invitation-id sender recipient)
    )
)

(define-private (send-invitation (address principal))
    (let 
        (
            (invitation-id (+ (var-get invitation-id-nonce) u1))
        )
        (try! (nft-mint? vote-invitation invitation-id address))
        (var-set invitation-id-nonce invitation-id)
        (ok invitation-id)
    )
)

(define-private (send-invitation-to-many (voters (list 128 principal))) 
    (begin
        (map send-invitation voters)
        (ok "invitation sent successfully")
    )
)

(define-private (burn-invitation (invitation-id uint) (sender principal)) 
    ;; #[filter(invitation-id, sender)]
    (nft-burn? vote-invitation invitation-id sender)
)
;; end of nft contract


;; VOTR
;; is a Web 3 voting platform. This platform guarantees transparency and credibility as the voters can monitor the progression of the voting exercise over the Blockchain.

(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_ALREADY_REGISTERED (err u400))
(define-constant ERR_NOT_REGISTERED (err u401))
(define-constant ERR_INVALID_ADDRESS (err u402))
(define-constant ERR_INVALID_VOTE_EXPIRATION (err u403))
(define-constant ERR_NOT_A_CONTESTANT (err u404))
(define-constant ERR_VOTED_ALREADY (err u406))
(define-constant ERR_VOTE_ENDED (err u407))
(define-constant ERR_VOTE_NOT_STARTED (err u408))
(define-constant ERR_VOTE_NOT_ENDED (err u408))
(define-constant ERR_UNAUTHORIZED_VOTER (err u409))
(define-constant ERR_NO_CREATED_ELECTION (err u410))
(define-constant ERR_INVITATIONS_MORE_THAN_EXPECTED (err u411))
(define-constant ERR_SOME_INVITATIONS_NOT_SENT (err u412))

(define-data-var votr-admin principal tx-sender)
(define-data-var elections-id uint u0)
(define-data-var total-registered-organizations uint u0)
(define-data-var vote-posting-price uint u50000000)

(define-map RegisteredOrganizations (string-ascii 128) principal)
(define-map Elections { organization-name: (string-ascii 128), election-id: uint } { 
        title: (string-ascii 30), 
        total-voters: uint, 
        expiration: (optional uint), 
        invitation-sent: uint,
        started: bool,
        contestants: (list 128 { address: principal, name: (string-ascii 128) })
    }
)
(define-map ContestantVotes {address: principal, election-id: uint} uint)
(define-map Voters {address: principal, election-id: uint} { supporter: principal })

;; PUBLIC FUNCTIONS

;; the register function allows an organization to come into the platform and
;; give them the right to commence a voting exercise 
(define-public (register (organization-name (string-ascii 128)) (address principal))
    (begin
        ;; #[filter(organization-name)]
        (asserts! (or (is-eq tx-sender (var-get votr-admin)) (is-eq tx-sender address)) ERR_INVALID_ADDRESS)
        (asserts! (is-none (map-get? RegisteredOrganizations organization-name)) ERR_ALREADY_REGISTERED)

        (map-set RegisteredOrganizations organization-name address)
        (var-set total-registered-organizations (+ (var-get total-registered-organizations) u1))

        (ok "registration successful")    
    )
)

;; the create-election function allows only registered organizations to commence voting exercise
;; with an nft every verified voter must hold
(define-public (create-election (organization-name (string-ascii 128)) (title (string-ascii 30)) (total-voters uint) (contestants (list 128 { address: principal, name: (string-ascii 128) }))) 
    (let 
        (
            (election-id (var-get elections-id))
            (id (+ u1 election-id))
        )
        ;; #[filter(title, total-voters, contestants)]
        (asserts! (is-eq (map-get? RegisteredOrganizations organization-name) (some tx-sender)) ERR_INVALID_ADDRESS)

        (try! (stx-transfer? (var-get vote-posting-price) (unwrap! (map-get? RegisteredOrganizations organization-name) ERR_NOT_REGISTERED) (var-get votr-admin)))
        (map-set Elections { organization-name: organization-name, election-id: id } { 
            title: title, 
            total-voters: total-voters, 
            expiration: none, 
            invitation-sent: u0,
            started: false,
            contestants: contestants
        })
        (var-set elections-id id)
        (try! (authorize-voters organization-name id (map get-contestant-address contestants)))

        (ok id)
    )
)

;; this function will allow registered organizations to authorize specific members to have voting right
;; by sending the nft defined above to the user they want to participate in the vote
(define-public (authorize-voters (organization-name (string-ascii 128)) (election-id uint) (voters (list 128 principal))) 
    (let
        (
            (election (unwrap! (map-get? Elections { organization-name: organization-name, election-id: election-id }) ERR_NOT_REGISTERED))
            (total-sent (get invitation-sent election))
            (updated-election (merge election { invitation-sent: (+ total-sent (len voters)) }))
        )
        (asserts! (is-eq (map-get? RegisteredOrganizations organization-name) (some tx-sender)) ERR_INVALID_ADDRESS)
        ;; #[filter(election-id, voters)]
        (try! (can-send-invitation organization-name election-id (len voters)))

        (map-set Elections { organization-name: organization-name, election-id: election-id } updated-election)

        (send-invitation-to-many voters)
    )
)

;; when an election is created by a registered organization, the election will not be started immediately
;; until they've authorize voters for the election before they can start the election they've created
(define-public (start-election (organization-name (string-ascii 128)) (election-id uint) (expiration uint)) 
    (let
        (
            (election (unwrap! (map-get? Elections { organization-name: organization-name, election-id: election-id }) ERR_NOT_REGISTERED))
            (total-voters (get total-voters election))
            (total-sent (get invitation-sent election))
            (updated-election (merge election { started: true, expiration: (some (+ block-height expiration)) }))
        )
        ;; #[filter(election-id)]
        (asserts! (> expiration u0) ERR_INVALID_VOTE_EXPIRATION)
        (asserts! (is-eq (map-get? RegisteredOrganizations organization-name) (some tx-sender)) ERR_INVALID_ADDRESS)
        (asserts! (is-eq total-voters total-sent) ERR_SOME_INVITATIONS_NOT_SENT)

        (map-set Elections { organization-name: organization-name, election-id: election-id } updated-election)

        (ok "election has started")
    )
)

;; the vote function allows only users with the nft defined above to vote
;; for any contestant of their choice
(define-public (vote (organization-name (string-ascii 128)) (election-id uint) (contestant principal) (invitation-id uint))
    (let
        (
            (election (unwrap! (map-get? Elections { organization-name: organization-name, election-id: election-id }) ERR_NOT_REGISTERED))
            (vote-expiry (get expiration election))
            (votes (unwrap-panic (map-get? ContestantVotes { address: contestant, election-id: election-id })))
        )
        ;; #[filter(updated-votes, contestant, election-id)]
        (asserts! (is-eq (get-owner invitation-id) (ok (some tx-sender))) ERR_UNAUTHORIZED_VOTER)
        (asserts! (< block-height (unwrap! vote-expiry ERR_VOTE_NOT_STARTED)) ERR_VOTE_ENDED)
        (asserts! (is-none (map-get? Voters {address: tx-sender, election-id: election-id})) ERR_VOTED_ALREADY)

        (unwrap! (burn-invitation invitation-id tx-sender) ERR_UNAUTHORIZED_VOTER)

        (map-set ContestantVotes {address: contestant, election-id: election-id} (+ votes u1))
        (map-set Voters {address: tx-sender, election-id: election-id} { supporter: contestant })

        (ok "your vote has been casted")
    )
)

;; the end-vote function will delete any election that has expired from the map
(define-public (end-vote (organization-name (string-ascii 128)) (election-id uint)) 
    (let
        (
            (vote-expiry (unwrap! (get expiration (map-get? Elections {organization-name: organization-name, election-id: election-id})) ERR_NOT_REGISTERED))
        )
        ;; #[filter(election-id)]
        (asserts! (or (is-eq tx-sender (var-get votr-admin)) (is-eq tx-sender (unwrap! (map-get? RegisteredOrganizations organization-name) ERR_NOT_REGISTERED))) ERR_UNAUTHORIZED)
        (asserts! (>= block-height (unwrap! vote-expiry ERR_VOTE_NOT_STARTED)) ERR_VOTE_NOT_ENDED)
        (map-delete Elections { organization-name: organization-name, election-id: election-id })
        (ok "voting has ended")
    )
)

;; check-election-result allows any user to check the result for an ongoing election
(define-read-only (check-election (organization-name (string-ascii 128)) (election-id uint))
   (let
        (
            (election (unwrap! (map-get? Elections { organization-name: organization-name, election-id: election-id }) ERR_NOT_REGISTERED))
        )
        (ok (map get-contestant-votes (get contestants election)))
   )
)

(define-private (can-send-invitation (organization-name (string-ascii 128)) (election-id uint) (invitations uint))
    (let 
        (
            (election (unwrap! (map-get? Elections { organization-name: organization-name, election-id: election-id }) ERR_NOT_REGISTERED))
            (total-voters (get total-voters election))
            (total-sent (get invitation-sent election))
            (remaining-invites (- total-voters total-sent))
        )
        (asserts! (>= remaining-invites invitations) ERR_INVITATIONS_MORE_THAN_EXPECTED)
        (ok true)
    )
)

(define-private (get-contestant-address (contestant {address: principal, name: (string-ascii 128)}))
    (get address contestant)
)

(define-private (get-contestant-votes (contestant {address: principal, name: (string-ascii 128)}))
    (let
        (
            (votes (unwrap-panic (map-get? ContestantVotes { address: (get address contestant), election-id: u1 } )))
        )
        (merge { address: (get address contestant), name: (get name contestant)} { votes: votes })
    )
)
