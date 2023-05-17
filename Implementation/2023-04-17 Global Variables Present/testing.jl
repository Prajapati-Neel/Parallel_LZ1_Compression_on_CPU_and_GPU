using Base.Threads,CUDA
const MAX_THREADS_PER_BLOCK = CUDA.attribute(CUDA.CuDevice(0), CUDA.DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK,)


function array_search()
    array_search_CuNative()
    t1=Threads.@spawn array_search_CuNative()
    t2=Threads.@spawn array_search_CuNative()
    t3=Threads.@spawn array_search_CuNative()
    t4=Threads.@spawn array_search_CuNative()
    t5=Threads.@spawn array_search_CuNative()
    wait(t1)
    wait(t2)
    wait(t3)
    wait(t4)
    wait(t5)
end
function forfunction()
    j=0
    for i in 1:1
        j+=1
    # @cuprintf("%d\n", id)
    end
end

function array_search_CuNative()
    input=Array{Int64}(undef,2000)
    c_d=CuArray{eltype(input)}(input)
    @cuda blocks=1 threads=MAX_THREADS_PER_BLOCK searchKernel(c_d)
    println(c_d)
end
function searchKernel(c_d)
    id = (blockIdx().x - 1) * blockDim().x + threadIdx().x
    a=push!(c_d,id)
return nothing
end
array_search()
CUDA.@time array_search()
CUDA.@time array_search()
CUDA.@time array_search()
