#############################################################################
# transpose.jl
# Returns the transpose of a matrix
# All expressions and atoms are subtpyes of AbstractExpr.
# Please read expressions.jl first.
#############################################################################

import Base.transpose, Base.ctranspose
export transpose, ctranspose, TransposeAtom, CTransposeAtom
export sign, curvature, monotonicity, evaluate, conic_form!

type TransposeAtom <: AbstractExpr
  head::Symbol
  id_hash::UInt64
  children::Tuple{AbstractExpr}
  size::Tuple{Int, Int}

  function TransposeAtom(x::AbstractExpr)
    children = (x,)
    return new(:transpose, hash(children), children, (x.size[2], x.size[1]))
  end
end

function sign(x::TransposeAtom)
  return sign(x.children[1])
end

function monotonicity(x::TransposeAtom)
  return (Nondecreasing(),)
end

function curvature(x::TransposeAtom)
  return ConstVexity()
end

function evaluate(x::TransposeAtom)
  return evaluate(x.children[1])'
end

# Since everything is vectorized, we simply need to multiply x by a permutation
# matrix such that coeff * vectorized(x) - vectorized(x') = 0
function conic_form!(x::TransposeAtom, unique_conic_forms::UniqueConicForms)
  if !has_conic_form(unique_conic_forms, x)
    objective = conic_form!(x.children[1], unique_conic_forms)

    sz = get_vectorized_size(x)

    num_rows = x.size[1]
    num_cols = x.size[2]

    I = Array(Int, sz)
    J = Array(Int, sz)

    k = 1
    for r = 1:num_rows
      for c = 1:num_cols
        I[k] = (c - 1) * num_rows + r
        J[k] = (r - 1) * num_cols + c
        k += 1
      end
    end

    transpose_matrix = sparse(I, J, 1.0)

    objective = transpose_matrix * objective
    cache_conic_form!(unique_conic_forms, x, objective)
  end
  return get_conic_form(unique_conic_forms, x)
end

transpose(x::AbstractExpr) = TransposeAtom(x)

#ctranspose(x::AbstractExpr) = transpose(x)
#ctranspose(x::Constant) = Constant(x.value')
#ctranspose(x::Constant) = Constant(x.value')



type CTransposeAtom <: AbstractExpr
  head::Symbol
  id_hash::UInt64
  children::Tuple{AbstractExpr}
  size::Tuple{Int, Int}

  function CTransposeAtom(x::AbstractExpr)
    children = (x,)
    return new(:ctranspose, hash(children), children, (x.size[2], x.size[1]))
  end
end

function sign(x::CTransposeAtom)
  return sign(x.children[1])
end

function monotonicity(x::CTransposeAtom)
  return (Nondecreasing(),)
end

function curvature(x::CTransposeAtom)
  return ConstVexity()
end

function evaluate(x::CTransposeAtom)
  return evaluate(x.children[1])'
end

# Since everything is vectorized, we simply need to multiply x by a permutation
# matrix such that coeff * vectorized(x) - vectorized(x') = 0
function conic_form!(x::CTransposeAtom, unique_conic_forms::UniqueConicForms)
  if !has_conic_form(unique_conic_forms, x)
    objective = conic_form!(x.children[1], unique_conic_forms)

    sz = get_vectorized_size(x)

    num_rows = x.size[1]
    num_cols = x.size[2]

    I = Array(Int, sz)
    J = Array(Int, sz)

    k = 1
    for r = 1:num_rows
      for c = 1:num_cols
        I[k] = (c - 1) * num_rows + r
        J[k] = (r - 1) * num_cols + c
        k += 1
      end
    end

    transpose_matrix = sparse(I, J, 1.0)

    for var in keys(objective)
      x1 = transpose_matrix * objective[var][1]'
      x2 = transpose_matrix * objective[var][2]'
      objective[var] = (x1,x2)
    end

    #objective = transpose_matrix * objective
    cache_conic_form!(unique_conic_forms, x, objective)
  end
  return get_conic_form(unique_conic_forms, x)
end

#transpose(x::AbstractExpr) = TransposeAtom(x)
ctranspose(x::AbstractExpr) = CTransposeAtom(x)
ctranspose(x::Constant) = Constant(x.value')
#ctranspose(x::Constant) = Constant(x.value')
