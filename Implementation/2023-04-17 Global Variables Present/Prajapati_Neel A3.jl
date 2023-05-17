using Random, BenchmarkTools, LinearAlgebra,CUDA, Printf

const MAX_THREADS_PER_BLOCK = CUDA.attribute(CUDA.CuDevice(0), CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK,)

function array_search_CuNative(a_d)
    b_d = similar(a_d)
    n = length(a_d)
    j = 1
    @views while j < n
        b_d[1:j] .= a_d[1:j]
        @cuda blocks=cld(n-j, MAX_THREADS_PER_BLOCK) threads=MAX_THREADS_PER_BLOCK additionKernel(a_d,b_d,j,n)
        j = j << 1
        (a_d, b_d) = (b_d, a_d)
    end
    return a_d
end
function additionKernel(a_d,b_d,j,n)
    id = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    if(id<=n-j)
        b_d[id+j]= a_d[id+j] + a_d[id]
    end
    return nothing
end

function prefixSum_CuArray(a_d)
    b_d = similar(a_d)
    n = length(a_d)
    j = 1
    @views while j < n
        b_d[1:j] .= a_d[1:j]
        b_d[1+j:n].= a_d[1+j:n] + a_d[1:n-j]
        j = j << 1
        (a_d, b_d) = (b_d, a_d)
    end
    return a_d
end




function prefixSum_CuNative_with_Chunks(a_d,chunkSize)
    b_d = similar(a_d)
    n = length(a_d)
    j = 1
    @views while j < n
        b_d[1:j] .= a_d[1:j]
        @cuda blocks=cld(cld((n-j),chunkSize), MAX_THREADS_PER_BLOCK) threads=MAX_THREADS_PER_BLOCK additionKernel_Chunks(a_d,b_d,j,n)
        j = j << 1
        (a_d, b_d) = (b_d, a_d)
    end
    return a_d
end
function additionKernel_Chunks(a_d,b_d,j,n)
    id = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    stride = blockDim().x * gridDim().x
    for i in id:stride:n-j
        b_d[i+j]= a_d[i+j] + a_d[i]
    end
    return nothing
end

function testfn(a, fn)
    a_d = CuArray{eltype(a)}(a)
    print(fn)
    CUDA.@time r_d = fn(a_d)
    r = Array(r_d)
    ps = cumsum(a)
    println(ps == r)
end
Cuchar