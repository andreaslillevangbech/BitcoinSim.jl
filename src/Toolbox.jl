using LinearAlgebra

module MDPToolBox
export mdp_policy_iteration


function mdp_policy_iteration(
    P,
    R,
    discount,
    policy0 = nothing,
    max_iter = 1000,
    eval_type = 0,
)

    @assert 0 < discount < 1 "discount must be in (0,1)"

    S = size(P, 1)
    A = size(P, 3)

    PR = mdp_computePR(P, R)

    if isnothing(policy0)
        # initialization of policy:
        # the one which maximizes the expected immediate reward
        _, policy0 = mdp_bellman_operator(P, PR, discount, zeros(S, 1))
    else
        @assert size(policy0) == S "dim of policy0 should be state space sized"
    end

    iter = 0
    policy = policy0
    is_done = false
    while !is_done
        iter = iter + 1

        if (eval_type == 0)
            V = mdp_eval_policy_matrix(P, PR, discount, policy)
        else
            V = mdp_eval_policy_iterative(P, PR, discount, policy)
        end

        _, policy_next = mdp_bellman_operator(P, PR, discount, V)

        n_different = sum(policy_next .!= policy)
        if all(policy_next == policy) || iter == max_iter
            is_done = true
        else
            policy = policy_next
        end
    end

end;  # function



#NOTE: Sparsify the whole thing

function mdp_eval_policy_iterative() end

function mdp_eval_policy_matrix(P, R, discount, policy)

    Ppolicy, PRpolicy = mdp_computePpolicyPRpolicy(P, R, policy)

    # V = PR + gPV  => (I-gP)V = PR  => V = inv(I-gP)*PR
    Vpolicy = (I - discount * Ppolicy) \ PRpolicy
    return Vpolicy

end


function mdp_computePpolicyPRpolicy(P, R, policy)

    S, _, A = size(P)
    Ppolicy = Matrix{Float32}(undef, S, S)
    PRpolicy = Vector{Float32}(undef, S)
    for a=1:A # avoid looping over S
        ind = policy .== a; # the rows that use action a (bitvector)
        if any(ind)
            Ppolicy[ind,:] = P[ind,:,a];
            PR = mdp_computePR(P,R);
            PRpolicy[ind,1] = PR[ind,a];
        end
    return Ppolicy, PRpolicy
end


function mdp_computePR(P, R)
    # R has form (SxSxA)
    S, _, A = size(P)
    PR = Matrix{Float32}(undef, S, A)
    for a = 1:A
        PR[:, a] = sum(P[:, :, a] .* R[:, :, a], dims = 2)
    end
    return PR
end


function mdp_bellman_operator(P, PR, discount, Vprev)

    @assert 0 < discount < 1 "discount must be in (0,1)"

    S = size(P, 1)
    A = size(P, 3)
    Q = zeros(S, A)
    for a = 1:A
        Q[:, a] = PR[:, a] + discount * P[:, :, a] * Vprev
    end
    V, p = findmax(Q, dims = 2)

    return V, getindex.(p, 2) # Stupid julia returns a CartesianIndex

end

end # module
