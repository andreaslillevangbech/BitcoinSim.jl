function honest_policy(state, attack=nothing) :: Action
  h,a,s,d,w = state
  if h > a
    return adopt
  elseif a > h
    return override
  end
  return wait
end

function sm1(state, attack=nothing) :: Action
  h,a,s,d,w = state
  if h > a
    return adopt
  elseif h == a - 1 && a > 1
    return override
  end
  return wait
end

function ism(state, attack) :: Action
  if attack
    return sm1(state)
  else
    return honest_policy(state)
  end
end


function policy_is_honest() end
